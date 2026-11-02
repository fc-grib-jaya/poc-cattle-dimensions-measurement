import Foundation
import UIKit

enum SubjectMode: String, CaseIterable, Codable, Identifiable {
    case cattle = "Sapi", human = "Human", animal = "Kucing/anjing"
    var id:String { rawValue }
}
struct Landmark: Identifiable, Codable {
    var id:String
    var label:String
    var point:Point2
    var confidence:Double
    var source:String
}
struct CaptureMetadata: Codable {
    let id:UUID
    let date:Date
    let timestamp:TimeInterval
    let source:String
    let orientation:String
    let cameraTransform:[Float]
    let depth:DepthFrame?
}
struct Capture: Identifiable {
    var id:UUID { metadata.id }
    let image:UIImage
    let metadata:CaptureMetadata
}
struct SavedMeasurement: Identifiable, Codable {
    let id:UUID
    let date:Date
    let mode:SubjectMode
    let cowID:String
    let breed:String
    let result:MeasurementResult
    let landmarks:[Landmark]
    let pose:[Landmark]
    let model:String
    let target:[Double]
    let confirmed:Bool
    var experimental:Bool = true
}
enum AppFailure: LocalizedError {
    case message(String)
    var errorDescription:String? { if case let .message(s)=self { return s };return nil }
}
extension UIImage {
    func normalized() -> UIImage {
        let format=UIGraphicsImageRendererFormat();format.scale=1
        let ratio=min(1,2048/max(size.width,size.height))
        let output=CGSize(width:size.width*ratio,height:size.height*ratio)
        return UIGraphicsImageRenderer(size:output,format:format).image { _ in draw(in:CGRect(origin:.zero,size:output)) }
    }
}
