# SapiMeasure — Iterasi 0–1

Project iOS native untuk Salman. SwiftUI + ARKit LiDAR + Vision + RTMPose AP10K. Sumber dan model sudah disertakan; ini prototipe pengembangan internal.

**Status:** implementasi sumber tersedia. Pemeriksaan sintaks Swift, struktur project, checksum model, dan inferensi ONNX CPU telah dijalankan di Linux. Build/link iOS, XCTest Swift, kamera, orientasi overlay, inferensi Apple Vision, serta performa di iPhone **belum diverifikasi** karena lingkungan pembuatan tidak memiliki Xcode/SDK iOS. Akurasi ukuran/bobot belum divalidasi.

## Buka di Mac

1. Ekstrak ZIP, buka `SapiMeasure.xcodeproj` di Xcode. Gunakan Xcode yang mendukung versi iOS di iPhone 17 Pro milikmu.
2. Tunggu Swift Package Manager menyelesaikan dependency **ONNX Runtime 1.20.0**. Internet diperlukan pada setup/build pertama; app tidak memanggil server untuk inferensi.
3. Pilih target **SapiMeasure → Signing & Capabilities → Team** akunmu. Ganti bundle identifier bila perlu. Kode tidak menyertakan kredensial/signing milik siapa pun.
4. Sambungkan iPhone, pilih sebagai Run Destination, aktifkan Developer Mode jika diminta iPhone, lalu Run.
5. Izinkan kamera. Pegang ponsel **portrait**; orientasi ini sengaja dikunci untuk mengurangi variasi transformasi koordinat pada Iterasi 0–1.

Tidak perlu menambahkan file model secara manual. `Resources/AnimalPose.onnx` sudah menjadi resource target. Simulator bisa dipakai untuk UI/impor foto dan inferensi; capture LiDAR membutuhkan perangkat fisik.

## Coba alurnya

- **Sapi:** Buka kamera → Ambil → tarik kotak pada satu sapi → Gunakan area & cari pose → periksa kandidat bahu/pinggul → koreksi titik 1–2 → letakkan titik 3–4 di dada → centang konfirmasi → Hitung estimasi → Simpan.
- Pilih chip titik, lalu ketuk lokasi di foto. Lingkaran juga bisa digeser. Garis hijau menandai panjang; garis kuning menandai bidang dada.
- **Human / Kucing/anjing:** kamera LiDAR atau foto impor → pilih area → pose Apple → tempatkan dua titik A–B → hitung jarak jika capture memiliki depth. Mode ini tidak menghitung bobot sapi.
- **Foto impor:** hanya pose, pemilihan area, dan editing titik. Tanpa pasangan depth, tombol pengukuran metrik dinonaktifkan.
- **Riwayat:** hasil, foto, data capture/depth, koordinat sebelum/sesudah koreksi, model, formula, ID, dan bangsa tersimpan lokal. Buka ulang capture untuk mengulang analisis; swipe untuk menghapus.

Pilihan Human/Animal memang tampil di build pengembangan ini. Menyembunyikannya pada build untuk peternak merupakan pekerjaan rilis setelah fase pengembangan.

## Implementasi dan penyesuaian PRD

| Bagian | Implementasi saat ini |
|---|---|
| Capture RGB + LiDAR | Memakai `capturedImage`, `sceneDepth`, confidence, intrinsics, transform, timestamp dari satu ARFrame. Buffer disalin saat capture. |
| Pemilihan sapi | **Kotak manual** pada foto beku. Detektor instans sapi otomatis / satu-tap belum diimplementasikan. |
| Pose sapi | RTMPose-m AP10K asli, 17 keypoint quadruped, berjalan lewat ONNX Runtime. Ini baseline, belum dilatih pada landmark pengukuran sapi. |
| Pose manusia & kucing/anjing | Apple Vision; hanya mode pengembangan. |
| Koreksi titik | Tap/drag, reset hasil ketika titik/area berubah, konfirmasi wajib sebelum hitung. |
| Panjang badan | Jarak Euclidean 3D dua titik yang dikonfirmasi. |
| Lingkar dada | Fit ellipse sementara dari kurva depth terlihat. Asumsi dan batas di `docs/MEASUREMENT.md`. |
| Winter | LD² × PB / 10815.15, cm → kg. Hanya untuk mode Sapi. |
| Kualitas | Depth invalid/low confidence, campuran kedalaman, section tidak cukup, dan fit buruk ditolak. Occlusion anatomi belum dideteksi otomatis. |
| Riwayat/offline | File lokal, tanpa upload; direktori dikecualikan dari backup. |

Jika bagian dada gagal, panjang masih ditampilkan, lingkar dan bobot kosong. Sistem tidak mengisi angka pengganti.

## Cara memahami dan mengambil keputusan

Baca berurutan: `docs/OWNERSHIP.md` → `docs/ARCHITECTURE.md` → `docs/MEASUREMENT.md`. Peta implementasi ada di `docs/ACCEPTANCE.md`.

Titik yang perlu kamu tinjau: definisi ujung bahu/tulang duduk bersama orang peternakan, posisi bidang dada, kenyamanan memilih sapi di kandang, dan apakah hasil depth cukup terbaca pada jarak pemakaianmu. Model umum tidak menentukan definisi ukuran tersebut.

## Pemeriksaan di Mac

```bash
cd SapiMeasure
swift test
bash scripts/check_on_mac.sh
```

`swift test` memeriksa modul geometri murni. Script kedua menjalankan tes yang sama lalu build simulator tanpa signing. Setelah build berhasil, pemeriksaan perangkat ada di `docs/DEVICE_CHECKLIST.md`.

Untuk mengulang pemeriksaan portable yang sudah dijalankan:

```bash
python3 -m pip install numpy onnxruntime tree-sitter tree-sitter-swift
python3 scripts/verify_artifacts.py
```

Project Xcode sudah disediakan. Jika menambah file Swift, jalankan `python3 scripts/generate_project.py` untuk meregenerasinya (pengaturan signing lokal perlu dipilih kembali).

## Batas Iterasi 0–1

Angka adalah estimasi eksperimental. Buruknya hasil dapat berasal dari pose, titik anatomi, depth, pendekatan lingkar satu sisi, maupun rumus Winter. Peningkatan pose saja belum tentu memperbaiki semuanya. Iterasi 2–3 perlu mengukur sumber galat secara terpisah.

Tidak ada APK, IPA bertanda tangan, TestFlight, atau klaim kelulusan pengujian iPhone dalam paket ini. User testing belum dilakukan.
