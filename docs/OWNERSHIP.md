# Cara Salman tetap memegang keputusan

Kerjakan dalam potongan yang bisa dilihat hasilnya di iPhone. Di tiap checkpoint, catat apa yang kamu lihat dan satu keputusan berikutnya.

| Checkpoint | Yang kamu lihat | Pertanyaan yang kamu jawab |
|---|---|---|
| 1. Capture manual | Foto beku dan dua titik pada objek berukuran diketahui | Apakah titik benar-benar menempel pada bagian foto yang disentuh? |
| 2. Human | Titik pose putih dari Vision; A–B dapat dipilih manual | Apakah pembacaan depth dan titik pose bertemu pada lokasi yang sama? |
| 3. Kucing/anjing | Format pose hewan, error ketika pose hilang | Apakah alur koreksi cukup jelas? |
| 4. Sapi | Kandidat bahu/pinggul, dada manual, panjang/lingkar/berat awal | Apakah definisi titik sesuai prosedur ukur ternak? |
| 5. Kandang | Pemilihan satu tubuh dari foto ramai | Apakah bisa dijalankan dari posisi yang aman dan realistis? |

Baca `ReviewModel.swift` dahulu: ini cerita alurnya. Setelah itu baca `MeasurementCore.swift`: ini alasan angka muncul. `PoseService.swift` menerjemahkan output model. `CaptureService.swift` memasok data sensor.

Ubah satu hal setiap kali: posisi titik, metode lingkar, atau model. Simpan capture yang sama dan gunakan Buka ulang capture untuk membandingkan. Jangan mengubah tiga hal sekaligus karena sumber perubahan hasil menjadi sulit dinilai.

Keputusan sementara yang diambil dalam implementasi ini: portrait-only, kotak target manual, RTMPose AP10K sebagai baseline, dan fit ellipse untuk lingkar. Semua punya lokasi kode dan asumsi yang terdokumentasi sehingga dapat kamu ganti.
