import Foundation

public struct Point2: Codable, Equatable, Sendable {
    public var x: Double
    public var y: Double
    public init(_ x: Double, _ y: Double) { self.x = x; self.y = y }
    public var isValid: Bool { x.isFinite && y.isFinite && (0...1).contains(x) && (0...1).contains(y) }
}
public struct Vector3: Codable, Sendable {
    public var x: Double; public var y: Double; public var z: Double
    public init(_ x: Double, _ y: Double, _ z: Double) { self.x=x; self.y=y; self.z=z }
    public static func +(a: Self,b: Self)->Self { .init(a.x+b.x,a.y+b.y,a.z+b.z) }
    public static func -(a: Self,b: Self)->Self { .init(a.x-b.x,a.y-b.y,a.z-b.z) }
    public static func *(a: Self,b: Double)->Self { .init(a.x*b,a.y*b,a.z*b) }
    public func dot(_ b: Self)->Double { x*b.x+y*b.y+z*b.z }
    public var norm: Double { sqrt(dot(self)) }
}
public struct CameraCalibration: Codable, Sendable {
    public var fx: Double; public var fy: Double; public var cx: Double; public var cy: Double
    public var width: Int; public var height: Int
    public init(fx: Double,fy: Double,cx: Double,cy: Double,width: Int,height: Int) {
        self.fx=fx;self.fy=fy;self.cx=cx;self.cy=cy;self.width=width;self.height=height
    }
}
public struct DepthFrame: Codable, Sendable {
    public var width: Int; public var height: Int
    public var meters: [Float]; public var confidence: [UInt8]
    public var calibration: CameraCalibration
    public init(width:Int,height:Int,meters:[Float],confidence:[UInt8],calibration:CameraCalibration) {
        self.width=width;self.height=height;self.meters=meters;self.confidence=confidence;self.calibration=calibration
    }
    // All public image points are upright portrait, top-left origin. Raw AR buffers
    // are landscape. RGB is baked with EXIF .right, so inverse is (v, 1-u).
    public static func portraitToRaw(_ p: Point2)->Point2 { .init(p.y, 1-p.x) }
    public func point(at portrait: Point2) throws -> Vector3 {
        guard portrait.isValid, width>2, height>2, meters.count==width*height,
              confidence.count==width*height, calibration.fx>0, calibration.fy>0 else {
            throw MeasurementError.invalidDepth
        }
        let uv=Self.portraitToRaw(portrait)
        let x=min(width-1,max(0,Int(uv.x*Double(width))))
        let y=min(height-1,max(0,Int(uv.y*Double(height))))
        var samples=[Double]()
        for dy in -1...1 { for dx in -1...1 {
            let xx=x+dx, yy=y+dy
            guard (0..<width).contains(xx),(0..<height).contains(yy) else { continue }
            let i=yy*width+xx, z=Double(meters[i])
            if confidence[i]>=1 && z.isFinite && (0.25...5.0).contains(z) { samples.append(z) }
        }}
        guard samples.count>=3 else { throw MeasurementError.invalidDepth }
        samples.sort()
        guard samples.last! - samples.first! < 0.08 else { throw MeasurementError.depthEdge }
        let z=samples[samples.count/2]
        return .init((uv.x*Double(calibration.width)-calibration.cx)*z/calibration.fx,
                     (uv.y*Double(calibration.height)-calibration.cy)*z/calibration.fy,z)
    }
}
public enum MeasurementError: LocalizedError {
    case invalidDepth, depthEdge, invalidSection, insufficientSection, badFit, invalidLength
    public var errorDescription: String? {
        switch self {
        case .invalidDepth: return "Depth tidak cukup. Pindahkan titik ke permukaan tubuh yang terlihat atau ambil ulang."
        case .depthEdge: return "Depth bercampur dengan latar/objek lain. Periksa titik atau ambil ulang."
        case .invalidSection: return "Bidang dada belum sesuai. Letakkan titik atas dan bawah tepat di belakang kaki depan."
        case .insufficientSection: return "Kurva dada belum terbaca. Coba sudut samping yang lebih jelas."
        case .badFit: return "Bentuk dada belum dapat diperkirakan dari depth ini. Ambil ulang."
        case .invalidLength: return "Jarak titik tidak valid. Periksa titik panjang badan."
        }
    }
}
public struct GirthEstimate: Codable, Sendable {
    public let centimeters: Double
    public let semiHeightMeters: Double
    public let semiWidthMeters: Double
    public let residualMeters: Double
    public let validSamples: Int
    public let method: String
}
public struct MeasurementResult: Codable, Sendable {
    public let lengthCM: Double
    public let girth: GirthEstimate?
    public let weightKG: Double?
    public let warning: String?
    public let formulaVersion: String
}
public enum MeasurementEngine {
    public static func distance(_ a:Point2,_ b:Point2,in depth:DepthFrame) throws -> Double {
        let d=try (depth.point(at:a)-depth.point(at:b)).norm*100
        guard d.isFinite,d>1,d<500 else { throw MeasurementError.invalidLength };return d
    }
    public static func winter(lengthCM:Double,girthCM:Double)->Double? {
        guard lengthCM.isFinite,girthCM.isFinite,lengthCM>0,girthCM>0 else { return nil }
        return girthCM*girthCM*lengthCM/10815.15
    }
    // Prototype assumption: endpoints lie on the central sagittal plane of a
    // perpendicular chest ellipse. Fit visible depth bulge; mirror the ellipse.
    // This is NOT a direct circumference measurement or a validated cattle fit.
    public static func girth(top:Point2,bottom:Point2,in depth:DepthFrame) throws -> GirthEstimate {
        let upper=try depth.point(at:top), lower=try depth.point(at:bottom)
        let axis=lower-upper, height=axis.norm, b=height/2
        guard height>0.15,height<2.2,abs(top.y-bottom.y)>0.05 else { throw MeasurementError.invalidSection }
        let unit=axis*(1/height), center=(upper+lower)*0.5
        let towardCamera=center*(-1)
        let radial=towardCamera-unit*towardCamera.dot(unit)
        guard radial.norm>0.1 else { throw MeasurementError.invalidSection }
        let radialUnit=radial*(1/radial.norm)
        var pairs=[(Double,Double)]()
        for i in 2...38 {
            let t=Double(i)/40
            let p=Point2(top.x+(bottom.x-top.x)*t,top.y+(bottom.y-top.y)*t)
            guard let q=try? depth.point(at:p) else {continue}
            let relative=q-center, axial=relative.dot(unit)/b
            guard abs(axial)<0.98 else {continue}
            let f=sqrt(1-axial*axial), bulge=relative.dot(radialUnit)
            if bulge > -0.03 {pairs.append((f,bulge))}
        }
        guard pairs.count>=24 else { throw MeasurementError.insufficientSection }
        let numerator = pairs.reduce(0.0) { sum, pair in sum + pair.0 * pair.1 }
        let denominator = pairs.reduce(0.0) { sum, pair in sum + pair.0 * pair.0 }
        let a = numerator / denominator
        let squaredError = pairs.reduce(0.0) { sum, pair in sum + pow(pair.1 - a * pair.0, 2) }
        let residual = sqrt(squaredError / Double(pairs.count))
        guard a>0.04,a/b>0.12,a/b<1.5,residual<0.06 else { throw MeasurementError.badFit }
        let h=pow(a-b,2)/pow(a+b,2)
        let circumference=Double.pi*(a+b)*(1+3*h/(10+sqrt(4-3*h)))
        return .init(centimeters:circumference*100,semiHeightMeters:b,semiWidthMeters:a,
                     residualMeters:residual,validSamples:pairs.count,method:"visible-depth-ellipse-v0")
    }
    public static func cattle(shoulder:Point2,pin:Point2,top:Point2,bottom:Point2,depth:DepthFrame) throws -> MeasurementResult {
        let length=try distance(shoulder,pin,in:depth)
        do {
            let g=try girth(top:top,bottom:bottom,in:depth)
            return .init(lengthCM:length,girth:g,weightKG:winter(lengthCM:length,girthCM:g.centimeters),warning:nil,formulaVersion:"Winter-cm-10815.15-v1")
        } catch {
            return .init(lengthCM:length,girth:nil,weightKG:nil,warning:error.localizedDescription,formulaVersion:"Winter-cm-10815.15-v1")
        }
    }
}
