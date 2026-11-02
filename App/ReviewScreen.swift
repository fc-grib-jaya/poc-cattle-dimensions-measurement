import SwiftUI

@MainActor struct ReviewScreen:View {
    @StateObject var model:ReviewModel
    @EnvironmentObject private var history:HistoryStore
    @Environment(\.dismiss) private var dismiss
    var body:some View {
        ScrollView {
            VStack(alignment:.leading,spacing:16) {
                Label("PROTOTIPE · BELUM TERVALIDASI",systemImage:"flask").font(.caption.bold()).foregroundStyle(.orange)
                Text(model.selectingTarget ? "Pilih satu tubuh" : "Periksa titik ukur").font(.title2.bold())
                Text(model.selectingTarget ? "Tarik kotak mengelilingi satu target yang terlihat utuh. Hindari memasukkan sapi di sebelahnya." : "Pilih nama titik, lalu ketuk foto atau geser lingkarannya.").foregroundStyle(.secondary)
                PhotoCanvas(image:model.capture.image,target:model.target,pose:model.pose,landmarks:model.landmarks,activeID:model.activeID,selecting:model.selectingTarget,enabled:!model.busy,onTarget:model.changeTarget,onMove:model.move)
                    .frame(height:400)
                if model.selectingTarget {
                    Button("Gunakan area & cari pose",action:model.detect).buttonStyle(.borderedProminent)
                    Button("Letakkan titik manual") {model.selectingTarget=false;model.modelName="Manual"}
                } else {
                    ScrollView(.horizontal,showsIndicators:false) {
                        HStack {
                            ForEach(model.anchorSpecs,id:\.0) {item in
                                Button(item.1) {model.activeID=item.0}
                                    .buttonStyle(.bordered).tint(model.activeID==item.0 ? .mint : .gray)
                            }
                        }
                    }
                    if model.mode == .cattle {
                        Text("1–2: panjang badan. 3–4: batas atas dan bawah tubuh, tepat di belakang kaki depan. Titik pinggul model perlu dikoreksi ke tulang duduk.").font(.footnote).foregroundStyle(.secondary)
                    }
                    HStack {
                        Button("Ubah area") {model.selectingTarget=true;model.result=nil;model.confirmed=false}
                        Spacer()
                        Button("Cari pose lagi",action:model.detect)
                    }.font(.subheadline)
                    Toggle("Saya sudah memeriksa semua titik",isOn:$model.confirmed)
                        .disabled(!model.hasAllPoints || model.busy)
                        .onChange(of:model.confirmed) {_,value in if !value {model.result=nil;model.saved=false}}
                    Button(model.mode == .cattle ? "Hitung estimasi" : "Hitung jarak A–B",action:model.compute)
                        .buttonStyle(.borderedProminent).disabled(!model.confirmed || model.busy || model.capture.metadata.depth == nil)
                }
                if model.busy {ProgressView("Menganalisis foto…")}
                if model.capture.metadata.depth == nil {
                    Label("Foto impor: uji pose saja, tanpa ukuran metrik.",systemImage:"photo").font(.callout).foregroundStyle(.orange)
                }
                if let message=model.message {Text(message).font(.callout).foregroundStyle(.orange)}
                if let result=model.result {
                    resultCard(result)
                    TextField("ID sapi / subjek (opsional)",text:$model.cowID).textFieldStyle(.roundedBorder)
                    if model.mode == .cattle {TextField("Bangsa sapi (opsional)",text:$model.breed).textFieldStyle(.roundedBorder)}
                    Button(model.saved ? "Tersimpan di perangkat" : "Simpan hasil") {model.save(to:history)}
                        .buttonStyle(.borderedProminent).disabled(model.saved)
                }
                DisclosureGroup("Lihat proses teknis") {
                    VStack(alignment:.leading,spacing:8) {
                        Text("Mode: \(model.mode.rawValue)\nModel: \(model.modelName)")
                        Text("Sumber: \(model.capture.metadata.source)\nRGB dan depth disimpan bersama. Semua koordinat layar memakai origin kiri atas pada foto portrait.")
                        if let d=model.capture.metadata.depth {
                            Text("Depth: \(d.width) × \(d.height), timestamp: \(model.capture.metadata.timestamp)")
                        }
                        Text("Lingkar: ellipse dari kurva depth yang terlihat, dilengkapi simetris. Asumsi ini belum tervalidasi untuk sapi.")
                    }.font(.caption).frame(maxWidth:.infinity,alignment:.leading)
                }
                Button("Ambil ulang") {dismiss()}.frame(maxWidth:.infinity)
            }.padding()
        }.navigationTitle(model.mode.rawValue).navigationBarTitleDisplayMode(.inline)
            .toolbar {ToolbarItem(placement:.topBarLeading) {Button("Kembali") {dismiss()}}}
    }
    @ViewBuilder private func resultCard(_ result:MeasurementResult)->some View {
        VStack(alignment:.leading,spacing:12) {
            if let kg=result.weightKG {
                Text("≈ \(kg.formatted(.number.precision(.fractionLength(0)))) kg").font(.system(size:42,weight:.bold,design:.rounded))
                Text("Estimasi eksperimental · Winter").font(.caption).foregroundStyle(.orange)
            }
            LabeledContent(model.mode == .cattle ? "Panjang badan" : "Jarak A–B",value:"\(result.lengthCM.formatted(.number.precision(.fractionLength(1)))) cm")
            if let girth=result.girth {
                LabeledContent("Estimasi lingkar dada",value:"\(girth.centimeters.formatted(.number.precision(.fractionLength(1)))) cm")
                Text("Deviasi fit kurva: \((girth.residualMeters*100).formatted(.number.precision(.fractionLength(1)))) cm · \(girth.validSamples) sampel. Ini bukan ukuran akurasi bobot.").font(.caption).foregroundStyle(.secondary)
            } else if model.mode == .cattle {Text("Lingkar dada belum tersedia; bobot belum dihitung.").foregroundStyle(.orange)}
        }.padding().frame(maxWidth:.infinity,alignment:.leading).background(.quaternary,in:RoundedRectangle(cornerRadius:16))
    }
}
