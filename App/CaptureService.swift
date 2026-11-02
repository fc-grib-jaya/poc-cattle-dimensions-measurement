import ARKit
import AVFoundation
import CoreImage
import SwiftUI

// The AR frame is retained only while capture buffers are copied. No mesh fusion:
// moving cattle must not be accumulated across different timestamps.
final class CaptureService: NSObject, ObservableObject, ARSessionDelegate {
    let session=ARSession()
    @Published var status="Menyiapkan kamera…"
    @Published var ready=false
    @Published var busy=false
    private var running=false
    private var startRequest=0
    private let processing=DispatchQueue(label:"capture.snapshot",qos:.userInitiated)
    private let context=CIContext()
    override init() { super.init();session.delegate=self }
    func start() {
        guard !running else {return}
        startRequest += 1
        let request=startRequest
        guard ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth) else {
            status="Capture ukuran membutuhkan iPhone/iPad dengan LiDAR. Foto impor tetap bisa untuk uji pose."; return
        }
        AVCaptureDevice.requestAccess(for:.video) { granted in
            DispatchQueue.main.async {
                guard request == self.startRequest else {return}
                guard granted else {self.status="Izin kamera diperlukan. Aktifkan melalui Settings.";return}
                let config=ARWorldTrackingConfiguration();config.frameSemantics=[.sceneDepth]
                self.running=true
                self.session.run(config,options:[.resetTracking,.removeExistingAnchors])
                self.status="Arahkan ke satu sisi tubuh. Tunggu depth siap."
            }
        }
    }
    func stop() { startRequest += 1; running=false;session.pause();ready=false }
    func session(_ session:ARSession,didUpdate frame:ARFrame) {
        let ok=frame.sceneDepth != nil
        DispatchQueue.main.async { guard self.running else {return}; if self.ready != ok {self.ready=ok}; if ok && !self.busy { self.status="LiDAR siap · ambil dari posisi aman" } }
    }
    func session(_ session:ARSession,didFailWithError error:Error) {
        DispatchQueue.main.async {self.running=false;self.ready=false;self.status=error.localizedDescription}
    }
    func sessionWasInterrupted(_ session:ARSession) { DispatchQueue.main.async {self.ready=false;self.status="Kamera terjeda."} }
    func sessionInterruptionEnded(_ session:ARSession) { DispatchQueue.main.async {if self.running {self.stop();self.start()}} }
    func capture(completion:@escaping(Result<Capture,Error>)->Void) {
        guard !busy,let frame=session.currentFrame,let scene=frame.sceneDepth else {
            completion(.failure(AppFailure.message("Depth belum siap. Tunggu lalu ambil ulang.")));return
        }
        busy=true
        processing.async {
            let outcome:Result<Capture,Error> = Result {
                // Both image and depth are taken from this exact ARFrame.
                let ci=CIImage(cvPixelBuffer:frame.capturedImage).oriented(.right)
                guard let cg=self.context.createCGImage(ci,from:ci.extent) else {throw AppFailure.message("Foto gagal dibuat.")}
                let image=UIImage(cgImage:cg)
                let buffer=scene.depthMap
                CVPixelBufferLockBaseAddress(buffer,.readOnly)
                defer {CVPixelBufferUnlockBaseAddress(buffer,.readOnly)}
                let w=CVPixelBufferGetWidth(buffer),h=CVPixelBufferGetHeight(buffer)
                guard let base=CVPixelBufferGetBaseAddress(buffer) else {throw MeasurementError.invalidDepth}
                var meters=[Float](repeating:0,count:w*h)
                for y in 0..<h {
                    let row=base.advanced(by:y*CVPixelBufferGetBytesPerRow(buffer)).assumingMemoryBound(to:Float.self)
                    for x in 0..<w {let z=row[x];meters[y*w+x]=z.isFinite && z>0 ? z : 0}
                }
                var confidence=[UInt8](repeating:0,count:w*h)
                if let cb=scene.confidenceMap,CVPixelBufferGetWidth(cb)==w,CVPixelBufferGetHeight(cb)==h {
                    CVPixelBufferLockBaseAddress(cb,.readOnly)
                    defer {CVPixelBufferUnlockBaseAddress(cb,.readOnly)}
                    if let b=CVPixelBufferGetBaseAddress(cb) {
                        for y in 0..<h {let row=b.advanced(by:y*CVPixelBufferGetBytesPerRow(cb)).assumingMemoryBound(to:UInt8.self)
                            for x in 0..<w {confidence[y*w+x]=row[x]}
                        }
                    }
                }
                let k=frame.camera.intrinsics,res=frame.camera.imageResolution
                let calibration=CameraCalibration(fx:Double(k[0][0]),fy:Double(k[1][1]),cx:Double(k[2][0]),cy:Double(k[2][1]),width:Int(res.width),height:Int(res.height))
                let depth=DepthFrame(width:w,height:h,meters:meters,confidence:confidence,calibration:calibration)
                let transform=(0..<4).flatMap { c in (0..<4).map { r in frame.camera.transform[c][r] } }
                let metadata=CaptureMetadata(id:UUID(),date:Date(),timestamp:frame.timestamp,source:"ARFrame.sceneDepth",orientation:"portrait-right-baked",cameraTransform:transform,depth:depth)
                return Capture(image:image,metadata:metadata)
            }
            DispatchQueue.main.async {self.busy=false;completion(outcome)}
        }
    }
}
struct CameraPreview:UIViewRepresentable {
    let service:CaptureService
    func makeUIView(context:Context)->ARSCNView {
        let view=ARSCNView(frame:.zero);view.session=service.session;view.automaticallyUpdatesLighting=false;return view
    }
    func updateUIView(_ view:ARSCNView,context:Context) {}
}
