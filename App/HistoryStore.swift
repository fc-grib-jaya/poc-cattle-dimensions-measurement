import Foundation
import UIKit

@MainActor final class HistoryStore:ObservableObject {
    @Published private(set) var records=[SavedMeasurement]()
    @Published var error:String?
    private let root:URL
    init() {
        root=FileManager.default.urls(for:.applicationSupportDirectory,in:.userDomainMask)[0].appendingPathComponent("SapiMeasure",isDirectory:true)
        do {
            try FileManager.default.createDirectory(at:root,withIntermediateDirectories:true)
            var url=root;var values=URLResourceValues();values.isExcludedFromBackup=true;try url.setResourceValues(values)
            reload()
        } catch { self.error=error.localizedDescription }
    }
    func reload() {
        do {
            let folders=try FileManager.default.contentsOfDirectory(at:root,includingPropertiesForKeys:nil).filter {!$0.lastPathComponent.hasPrefix(".")}
            var decoded=[SavedMeasurement](),bad=0
            for folder in folders {
                do {decoded.append(try JSONDecoder().decode(SavedMeasurement.self,from:Data(contentsOf:folder.appendingPathComponent("result.json"))))}
                catch {bad+=1}
            }
            records=decoded.sorted {$0.date>$1.date}
            if bad>0 {error="\(bad) data riwayat tidak dapat dibaca. File dipertahankan."}
        } catch {self.error=error.localizedDescription}
    }
    func save(record:SavedMeasurement,capture:Capture) throws {
        let temp=root.appendingPathComponent(".\(record.id.uuidString)",isDirectory:true)
        let destination=root.appendingPathComponent(record.id.uuidString,isDirectory:true)
        try FileManager.default.createDirectory(at:temp,withIntermediateDirectories:true)
        do {
            let encoder=JSONEncoder();encoder.outputFormatting=[.sortedKeys]
            try encoder.encode(record).write(to:temp.appendingPathComponent("result.json"),options:.atomic)
            try encoder.encode(capture.metadata).write(to:temp.appendingPathComponent("capture.json"),options:.atomic)
            guard let jpg=capture.image.jpegData(compressionQuality:0.92) else {throw AppFailure.message("Foto gagal disimpan.")}
            try jpg.write(to:temp.appendingPathComponent("photo.jpg"),options:.atomic)
            try FileManager.default.moveItem(at:temp,to:destination)
            reload()
        } catch {try? FileManager.default.removeItem(at:temp);throw error}
    }
    func delete(_ record:SavedMeasurement) {
        do {try FileManager.default.removeItem(at:root.appendingPathComponent(record.id.uuidString));reload()}
        catch {self.error=error.localizedDescription}
    }
    func photo(_ record:SavedMeasurement)->UIImage? {
        UIImage(contentsOfFile:root.appendingPathComponent(record.id.uuidString).appendingPathComponent("photo.jpg").path)
    }
    func restore(_ record:SavedMeasurement) throws -> Capture {
        let folder=root.appendingPathComponent(record.id.uuidString)
        let metadata=try JSONDecoder().decode(CaptureMetadata.self,from:Data(contentsOf:folder.appendingPathComponent("capture.json")))
        guard let image=photo(record) else {throw AppFailure.message("Foto tidak ditemukan.")}
        return Capture(image:image,metadata:metadata)
    }
}
