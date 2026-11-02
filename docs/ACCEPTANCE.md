# Status terhadap Iterasi 0–1

| Persyaratan | Status implementasi sumber | Verifikasi perangkat |
|---|---|---|
| RGB + depth + metadata satu frame | Ditulis di CaptureService | Pending |
| Koreksi manual dan ukuran 3D | Ditulis di PhotoCanvas/MeasurementCore | Pending |
| Pilih sapi di kandang ramai | Kotak manual; deteksi instans otomatis belum ada | Pending |
| Human/Animal model | Apple Vision terintegrasi | Pending |
| Cattle baseline model | RTMPose AP10K terintegrasi + weights disertakan | CPU ONNX smoke pass; iOS pending |
| Landmark anatomi khusus sapi | Proxy bahu/hip + koreksi; dada manual | Perlu review ahli/pengguna internal |
| Lingkar dada visual | Fit ellipse sementara; menolak jika sampel tidak cukup | Belum tervalidasi |
| Winter | Implementasi core; hanya mode Sapi | XCTest disiapkan, belum dijalankan |
| Kualitas input | Depth, percampuran permukaan, fit section | Occlusion anatomi otomatis belum ada |
| Offline dan riwayat | Implementasi lokal tanpa networking app | Pending |
| User testing | Belum dilakukan | Di luar pekerjaan saat ini |

Jangan menandai seluruh Iterasi 1 sebagai lolos penerimaan sebelum build dan pemeriksaan perangkat selesai. Target galat akurasi tidak menjadi syarat kelulusan iterasi ini.
