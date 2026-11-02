import SwiftUI

@MainActor final class ReviewModel:ObservableObject {
    let capture:Capture
    let mode:SubjectMode
    @Published var target=CGRect(x:0.05,y:0.05,width:0.9,height:0.9)
    @Published var selectingTarget=true
    @Published var landmarks=[Landmark]()
    @Published var pose=[Landmark]()
    @Published var activeID="shoulder"
    @Published var busy=false
    @Published var confirmed=false
    @Published var result:MeasurementResult?
    @Published var message:String?
    @Published var modelName="Manual"
    @Published var cowID=""
    @Published var breed=""
    @Published var saved=false
    private let poseService=PoseService()
    init(capture:Capture,mode:SubjectMode) {self.capture=capture;self.mode=mode}
    var anchorSpecs:[(String,String)] {
        mode == .cattle ? [("shoulder","1 · Ujung bahu"),("pin","2 · Tulang duduk"),("chestTop","3 · Atas dada"),("chestBottom","4 · Bawah dada")] : [("shoulder","1 · Titik A"),("pin","2 · Titik B")]
    }
    var hasAllPoints:Bool {anchorSpecs.allSatisfy {r in landmarks.contains {$0.id==r.0}}}
    func move(id:String,to p:Point2) {
        guard p.isValid,!busy else {return}
        let label=anchorSpecs.first {$0.0==id}?.1 ?? id
        if let i=landmarks.firstIndex(where:{$0.id==id}) {landmarks[i].point=p;landmarks[i].source="manual"}
        else {landmarks.append(.init(id:id,label:label,point:p,confidence:1,source:"manual"))}
        activeID=id;confirmed=false;result=nil;saved=false;message=nil
    }
    func changeTarget(_ rect:CGRect) {
        target=rect;landmarks=[];pose=[];result=nil;confirmed=false;saved=false;modelName="Manual"
    }
    func detect() {
        selectingTarget=false;busy=true;message=nil;confirmed=false;result=nil;saved=false
        poseService.detect(image:capture.image,mode:mode,target:target) {[weak self] response in
            guard let self=self else {return};self.busy=false
            switch response {
            case .failure(let error):self.message=error.localizedDescription
            case .success(let output):
                self.pose=output.landmarks;self.modelName=output.model
                if self.mode == .cattle {
                    let shoulder=output.landmarks.filter {$0.id.contains("shoulder")}.max {$0.confidence<$1.confidence}
                    let hip=output.landmarks.filter {$0.id.contains("hip")}.max {$0.confidence<$1.confidence}
                    // AP10K hip is NOT pin/ischium. Offer a marked proxy for manual correction.
                    for (id,p) in [("shoulder",shoulder),("pin",hip)] {
                        if let p=p,!self.landmarks.contains(where:{$0.id==id && $0.source=="manual"}) {
                            self.landmarks.removeAll {$0.id==id}
                            self.landmarks.append(.init(id:id,label:self.anchorSpecs.first {$0.0==id}!.1,point:p.point,confidence:p.confidence,source:"model-proxy-needs-review"))
                        }
                    }
                    self.message="Titik model adalah usulan. Koreksi bahu & tulang duduk; letakkan titik atas/bawah dada tepat di belakang kaki depan."
                } else {self.message="Pose tampil sebagai titik putih. Pilih dua titik untuk uji jarak LiDAR."}
            }
        }
    }
    func compute() {
        guard confirmed,hasAllPoints else {message="Lengkapi dan periksa semua titik terlebih dahulu.";return}
        guard let depth=capture.metadata.depth else {message="Foto impor tidak memiliki pasangan LiDAR. Uji pose tersedia; ukuran metrik memerlukan capture LiDAR.";return}
        let points=Dictionary(uniqueKeysWithValues:landmarks.map {($0.id,$0.point)})
        do {
            if mode == .cattle {
                result=try MeasurementEngine.cattle(shoulder:points["shoulder"]!,pin:points["pin"]!,top:points["chestTop"]!,bottom:points["chestBottom"]!,depth:depth)
            } else {
                result = .init(lengthCM:try MeasurementEngine.distance(points["shoulder"]!,points["pin"]!,in:depth),girth:nil,weightKG:nil,warning:nil,formulaVersion:"distance-only-v1")
            }
            message=result?.warning
        } catch {result=nil;message=error.localizedDescription}
    }
    func save(to store:HistoryStore) {
        guard let result=result,confirmed,!saved else {return}
        let record=SavedMeasurement(id:UUID(),date:Date(),mode:mode,cowID:cowID,breed:breed,result:result,landmarks:landmarks,pose:pose,model:modelName,target:[target.minX,target.minY,target.width,target.height],confirmed:confirmed)
        do {try store.save(record:record,capture:capture);saved=true}
        catch {message=error.localizedDescription}
    }
}
