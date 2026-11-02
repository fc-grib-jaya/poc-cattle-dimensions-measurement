import UIKit
import Vision
import OnnxRuntimeBindings

struct PoseOutput { let landmarks:[Landmark]; let model:String }
final class PoseService {
    private var env:ORTEnv?
    private var session:ORTSession?
    private let queue=DispatchQueue(label:"pose.inference",qos:.userInitiated)
    func detect(image:UIImage,mode:SubjectMode,target:CGRect,completion:@escaping(Result<PoseOutput,Error>)->Void) {
        queue.async {
            let result:Result<PoseOutput,Error> = Result {
                switch mode {
                case .cattle: return try self.cattle(image:image,target:target)
                case .human,.animal: return try self.vision(image:image,mode:mode,target:target)
                }
            }
            DispatchQueue.main.async {completion(result)}
        }
    }
    private func vision(image:UIImage,mode:SubjectMode,target:CGRect) throws -> PoseOutput {
        guard let cg=image.cgImage else {throw AppFailure.message("Foto tidak terbaca.")}
        let rect=CGRect(x:target.minX*Double(cg.width),y:target.minY*Double(cg.height),width:target.width*Double(cg.width),height:target.height*Double(cg.height)).integral
        guard let crop=cg.cropping(to:rect) else {throw AppFailure.message("Area pilihan tidak valid.")}
        let handler=VNImageRequestHandler(cgImage:crop,orientation:.up)
        var landmarks=[Landmark]()
        func add(_ name:String,_ p:VNRecognizedPoint) {
            guard p.confidence>=0.1 else {return}
            landmarks.append(.init(id:name,label:name,point:.init((rect.minX+p.location.x*rect.width)/Double(cg.width),(rect.minY+(1-p.location.y)*rect.height)/Double(cg.height)),confidence:Double(p.confidence),source:mode.rawValue))
        }
        if mode == .human {
            let request=VNDetectHumanBodyPoseRequest();try handler.perform([request])
            if let observation=request.results?.first {
                for (name,p) in try observation.recognizedPoints(.all) {add(String(describing:name),p)}
            }
        } else {
            let request=VNDetectAnimalBodyPoseRequest();try handler.perform([request])
            if let observation=request.results?.first {
                for (name,p) in try observation.recognizedPoints(.all) {add(String(describing:name),p)}
            }
        }
        guard !landmarks.isEmpty else {throw AppFailure.message("Pose tidak ditemukan. Persempit area target atau letakkan titik manual.")}
        return .init(landmarks:landmarks,model:mode == .human ? "Apple Vision Human" : "Apple Vision Animal")
    }
    private func cattle(image:UIImage,target:CGRect) throws -> PoseOutput {
        if session == nil {
            guard let path=Bundle.main.path(forResource:"AnimalPose",ofType:"onnx") else {throw AppFailure.message("AnimalPose.onnx tidak ditemukan dalam bundle.")}
            let environment=try ORTEnv(loggingLevel:.warning)
            let options=try ORTSessionOptions();try options.setIntraOpNumThreads(2)
            session=try ORTSession(env:environment,modelPath:path,sessionOptions:options);env=environment
        }
        guard let session=session else {throw AppFailure.message("Model gagal dimuat.")}
        let width=image.size.width,height=image.size.height
        // RTMPose AP10K: square 256 crop, bbox padding 1.25, RGB mean/std, NCHW.
        let side=max(target.width*width,target.height*height)*1.25
        let crop=CGRect(x:target.midX*width-side/2,y:target.midY*height-side/2,width:side,height:side)
        let format=UIGraphicsImageRendererFormat();format.scale=1;format.opaque=true
        let resized=UIGraphicsImageRenderer(size:CGSize(width:256,height:256),format:format).image { ctx in
            UIColor.black.setFill();ctx.fill(CGRect(x:0,y:0,width:256,height:256))
            image.draw(in:CGRect(x:-crop.minX*256/side,y:-crop.minY*256/side,width:width*256/side,height:height*256/side))
        }
        guard let cg=resized.cgImage else {throw AppFailure.message("Preprocessing gagal.")}
        var rgba=[UInt8](repeating:0,count:256*256*4)
        let ok=rgba.withUnsafeMutableBytes { bytes -> Bool in
            guard let context=CGContext(data:bytes.baseAddress,width:256,height:256,bitsPerComponent:8,bytesPerRow:256*4,space:CGColorSpaceCreateDeviceRGB(),bitmapInfo:CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue) else {return false}
            context.draw(cg,in:CGRect(x:0,y:0,width:256,height:256));return true
        }
        guard ok else {throw AppFailure.message("Buffer model gagal dibuat.")}
        let mean:[Float]=[123.675,116.28,103.53],std:[Float]=[58.395,57.12,57.375]
        var tensor=[Float](repeating:0,count:3*256*256)
        for c in 0..<3 {for i in 0..<(256*256) {tensor[c*256*256+i]=(Float(rgba[i*4+c])-mean[c])/std[c]}}
        let data=tensor.withUnsafeBufferPointer {Data(buffer:$0)}
        let value=try ORTValue(tensorData:NSMutableData(data:data),elementType:.float,shape:[1,3,256,256])
        let inputNames=try session.inputNames(),outputNames=try session.outputNames()
        guard inputNames.count==1,outputNames.contains("simcc_x"),outputNames.contains("simcc_y") else {throw AppFailure.message("Kontrak model tidak cocok dengan AP10K SimCC.")}
        let outputs=try session.run(withInputs:[inputNames[0]:value],outputNames:Set(outputNames),runOptions:nil)
        func values(_ name:String) throws -> [Float] {
            guard let output=outputs[name] else {throw AppFailure.message("Output model hilang.")}
            let shape=try output.tensorTypeAndShapeInfo().shape.map { $0.intValue }
            guard shape == [1,17,512] else {throw AppFailure.message("Bentuk tensor model tidak sesuai.")}
            let bytes=try output.tensorData() as Data
            return bytes.withUnsafeBytes {Array($0.bindMemory(to:Float.self))}
        }
        let xs=try values("simcc_x"),ys=try values("simcc_y")
        let names=["left_eye","right_eye","nose","neck","tail_root","left_shoulder","left_elbow","left_front_paw","right_shoulder","right_elbow","right_front_paw","left_hip","left_knee","left_back_paw","right_hip","right_knee","right_back_paw"]
        var points=[Landmark]()
        for j in 0..<17 {
            let ix=(0..<512).max {xs[j*512+$0]<xs[j*512+$1]}!
            let iy=(0..<512).max {ys[j*512+$0]<ys[j*512+$1]}!
            let score=Double(min(xs[j*512+ix],ys[j*512+iy]))
            let p=Point2((crop.minX+Double(ix)/512*side)/width,(crop.minY+Double(iy)/512*side)/height)
            if score>=0.1 && p.isValid {points.append(.init(id:names[j],label:names[j],point:p,confidence:score,source:"RTMPose AP10K"))}
        }
        guard !points.isEmpty else {throw AppFailure.message("Model belum menemukan pose. Letakkan titik manual.")}
        return .init(landmarks:points,model:"RTMPose-m AP10K · 7a041aa1 · ONNX")
    }
}
