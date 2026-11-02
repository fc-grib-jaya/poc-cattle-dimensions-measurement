# Pemeriksaan implementasi

Dijalankan pada lingkungan Linux, bukan perangkat iOS.

| Pemeriksaan | Hasil |
|---|---|
| Parse 11 file Swift dengan tree-sitter Swift | Lulus; ini pemeriksaan sintaks, bukan type checking atau build Swift |
| Referensi objek project Xcode, Info.plist, XML scheme | Lulus |
| SHA-256 model | Sesuai manifest: 1cfd1c86e0d9e5d5f95178bcd95ee9a4e8386a624cd3c57519f27ff58cac7f28 |
| ONNX Runtime CPU, input nol [1,3,256,256] | Lulus, dua output finite [1,17,512] |
| ONNX Runtime CPU, foto contoh kucing OpenMMLab | Lulus inferensi, 17 keypoint di atas skor 0.1. Tanpa evaluasi akurasi. Foto contoh tidak ikut didistribusikan. |
| XCTest core (6 kasus) | Sumber tes tersedia; belum dijalankan karena Swift toolchain tidak tersedia |
| Compile/link simulator/iPhone | Belum dijalankan; Xcode dan SDK iOS tidak tersedia |
| Lifecycle kamera, permission, native Vision, pose iOS | Belum dijalankan di perangkat |
| Transformasi sentuhan/portrait/depth pada kamera nyata | Belum diverifikasi di perangkat |
| Akurasi PB/LD/berat pada sapi | Belum divalidasi; sasaran Iterasi 2–3 |
| User testing | Belum dilakukan |

Baca DEVICE_CHECKLIST.md untuk kelanjutan di Mac/iPhone. Keberhasilan parser/ONNX CPU tidak membuktikan bahwa project iOS sudah berhasil dibuild.
