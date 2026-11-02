import SwiftUI
import PhotosUI

@main @MainActor struct SapiMeasureApp:App {
    @StateObject private var history=HistoryStore()
    var body:some Scene {
        WindowGroup {HomeScreen().environmentObject(history).tint(.teal)}
    }
}
@MainActor struct HomeScreen:View {
    @State private var mode=SubjectMode.cattle
    @State private var camera=false
    @State private var history=false
    @State private var imported:Capture?
    @State private var photo:PhotosPickerItem?
    @State private var error:String?
    var body:some View {
        NavigationStack {
            ScrollView {
                VStack(alignment:.leading,spacing:24) {
                    Label("SAPI MEASURE / DEVELOPMENT",systemImage:"viewfinder").font(.caption.bold()).foregroundStyle(.teal)
                    Text("Ukur dari\nsatu sisi.").font(.system(size:42,weight:.bold,design:.rounded))
                    Text("Ambil foto dengan LiDAR, periksa titik tubuh, lalu lihat estimasi awal.").font(.title3).foregroundStyle(.secondary)
                    VStack(alignment:.leading,spacing:12) {
                        Text("Mode pengembangan").font(.headline)
                        Picker("Subjek",selection:$mode) {ForEach(SubjectMode.allCases) {m in Text(m.rawValue).tag(m)}}.pickerStyle(.segmented)
                        Text(mode == .cattle ? "Sapi: model quadruped + koreksi manual. Panjang, estimasi lingkar dada, dan Winter." : "Uji pipeline pose dan jarak dua titik. Rumus bobot sapi hanya tersedia pada mode Sapi.").font(.callout).foregroundStyle(.secondary)
                    }.padding().background(.quaternary,in:RoundedRectangle(cornerRadius:20))
                    Button {camera=true} label: {Label("Buka kamera LiDAR",systemImage:"camera.fill").frame(maxWidth:.infinity).padding(.vertical,10)}.buttonStyle(.borderedProminent)
                    PhotosPicker(selection:$photo,matching:.images) {Label("Impor foto untuk uji pose",systemImage:"photo.on.rectangle")}
                    Button {history=true} label: {Label("Riwayat lokal",systemImage:"clock.arrow.circlepath")}
                    Text("Iterasi 0–1 · estimasi eksperimental. Ambil gambar dari posisi aman tanpa memindahkan atau mengitari sapi.").font(.footnote).foregroundStyle(.secondary)
                    if let error=error {Text(error).foregroundStyle(.orange)}
                }.padding(24)
            }.navigationTitle("SapiMeasure").navigationBarTitleDisplayMode(.inline)
        }.fullScreenCover(isPresented:$camera) {CameraScreen(mode:mode)}
            .sheet(isPresented:$history) {NavigationStack {HistoryScreen()}}
            .fullScreenCover(item:$imported) {capture in NavigationStack {ReviewScreen(model:ReviewModel(capture:capture,mode:mode))}}
            .onChange(of:photo) {_,item in
                guard let item=item else {return}
                Task {
                    do {
                        guard let data=try await item.loadTransferable(type:Data.self),let image=UIImage(data:data) else {throw AppFailure.message("Foto tidak dapat dibuka.")}
                        imported=Capture(image:image.normalized(),metadata:.init(id:UUID(),date:Date(),timestamp:0,source:"photo-import-no-depth",orientation:"upright-baked",cameraTransform:[],depth:nil))
                    } catch {self.error=error.localizedDescription}
                    photo=nil
                }
            }
    }
}
@MainActor struct CameraScreen:View {
    let mode:SubjectMode
    @StateObject private var service=CaptureService()
    @State private var capture:Capture?
    @State private var error:String?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    var body:some View {
        ZStack {
            CameraPreview(service:service).ignoresSafeArea()
            VStack(spacing:20) {
                HStack {Button("Tutup") {dismiss()};Spacer();Text(mode.rawValue).bold()}.padding().background(.ultraThinMaterial,in:RoundedRectangle(cornerRadius:14))
                Spacer()
                Text("Badan terlihat utuh dari samping").font(.headline).padding(12).background(.ultraThinMaterial,in:Capsule())
                Text(error ?? service.status).multilineTextAlignment(.center).padding().background(.ultraThinMaterial,in:RoundedRectangle(cornerRadius:14))
                Button {
                    error=nil
                    service.capture {result in
                        switch result {
                        case .success(let c):capture=c;service.stop()
                        case .failure(let e):error=e.localizedDescription
                        }
                    }
                } label: {
                    ZStack {Circle().fill(.white).frame(width:74,height:74);Circle().stroke(.teal,lineWidth:4).frame(width:64,height:64);if service.busy {ProgressView()}}
                }.accessibilityLabel("Ambil foto dan LiDAR").disabled(!service.ready || service.busy)
            }.padding()
        }.onAppear {service.start()}.onDisappear {service.stop()}
            .onChange(of:scenePhase) {_,phase in
                if phase == .active && capture == nil {service.start()} else if phase != .active {service.stop()}
            }
            .fullScreenCover(item:$capture,onDismiss:{service.start()}) {c in NavigationStack {ReviewScreen(model:ReviewModel(capture:c,mode:mode))}}
    }
}
@MainActor struct HistoryScreen:View {
    @EnvironmentObject private var history:HistoryStore
    @Environment(\.dismiss) private var dismiss
    var body:some View {
        List {
            if let error=history.error {Text(error).foregroundStyle(.orange)}
            if history.records.isEmpty {Text("Hasil yang disimpan akan muncul di sini.").foregroundStyle(.secondary)}
            ForEach(history.records) {r in
                NavigationLink {
                    HistoryDetail(record:r)
                } label: {
                    VStack(alignment:.leading,spacing:6) {
                        Text(r.cowID.isEmpty ? r.mode.rawValue : r.cowID).font(.headline)
                        if let weight=r.result.weightKG {Text("≈ \(weight.formatted(.number.precision(.fractionLength(0)))) kg · eksperimental")}
                        else {Text("\(r.result.lengthCM.formatted(.number.precision(.fractionLength(1)))) cm")}
                        Text(r.date.formatted(date:.abbreviated,time:.shortened)).font(.caption).foregroundStyle(.secondary)
                    }
                }.swipeActions {Button("Hapus",role:.destructive) {history.delete(r)}}
            }
        }.navigationTitle("Riwayat").toolbar {ToolbarItem(placement:.topBarTrailing) {Button("Selesai") {dismiss()}}}
    }
}
@MainActor struct HistoryDetail:View {
    let record:SavedMeasurement
    @EnvironmentObject private var history:HistoryStore
    @State private var restored:Capture?
    @State private var error:String?
    var body:some View {
        ScrollView {
            VStack(alignment:.leading,spacing:16) {
                if let image=history.photo(record) {Image(uiImage:image).resizable().scaledToFit().clipShape(RoundedRectangle(cornerRadius:16))}
                Text("Estimasi eksperimental").font(.headline).foregroundStyle(.orange)
                Text("Panjang: \(record.result.lengthCM.formatted()) cm")
                if let g=record.result.girth {Text("Lingkar dada: \(g.centimeters.formatted()) cm")}
                if let kg=record.result.weightKG {Text("Winter: \(kg.formatted()) kg")}
                Text("Model: \(record.model)").font(.caption)
                Text("Bangsa: \(record.breed.isEmpty ? "Belum dicatat" : record.breed)")
                Button("Buka ulang capture") {
                    do {restored=try history.restore(record)} catch {self.error=error.localizedDescription}
                }.buttonStyle(.borderedProminent)
                if let error=error {Text(error).foregroundStyle(.orange)}
            }.padding()
        }.navigationTitle(record.cowID.isEmpty ? record.mode.rawValue : record.cowID)
            .sheet(item:$restored) {capture in
                NavigationStack {ReviewScreen(model:reviewModel(capture))}
            }
    }
    private func reviewModel(_ capture:Capture)->ReviewModel {
        let model=ReviewModel(capture:capture,mode:record.mode)
        model.landmarks=record.landmarks;model.pose=record.pose;model.modelName=record.model
        model.cowID=record.cowID;model.breed=record.breed;model.selectingTarget=false
        if record.target.count==4 {model.target=CGRect(x:record.target[0],y:record.target[1],width:record.target[2],height:record.target[3])}
        return model
    }
}
