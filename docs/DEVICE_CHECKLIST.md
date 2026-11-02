# Pemeriksaan berikutnya di Mac/iPhone

Belum dijalankan di lingkungan pembuatan. Ini adalah pemeriksaan pengembangan internal, belum user testing.

1. `bash scripts/check_on_mac.sh`: Swift core tests dan build simulator harus lulus. Jika gagal, simpan error pertama dan versi Xcode.
2. Build Debug ke iPhone; izin kamera grant/deny; background/foreground; tutup/buka capture. Tidak boleh crash atau tetap memakai frame lama setelah kamera terjeda.
3. Foto objek asimetris berlabel atas/bawah/kiri/kanan. Pastikan overlay dan sentuhan selaras, lalu bandingkan jarak 3D dengan ukuran referensi. Ini menguji transform portrait dan aspect-fit.
4. Depth di titik tubuh/objek terbaca. Titik pada tepi tubuh/latar perlu ditolak bila depth bercampur. Uji juga capture sebelum depth tersedia.
5. Human dan Animal: inferensi pada subjek sesuai, tanpa subjek, dan beberapa subjek. Persempit kotak target; verifikasi crop model tidak menggeser output.
6. Sapi: kandidat pose muncul; dua titik badan bisa dikoreksi; dada diletakkan manual. Titik pinggul kandidat wajib dipindahkan jika bukan tulang duduk.
7. Edit titik setelah hasil muncul: angka dan konfirmasi lama harus hilang. Ubah target: semua titik lama harus hilang.
8. Foto impor tidak dapat menghasilkan cm atau kg. Human/Animal tidak dapat menghasilkan berat sapi. Tidak ada bobot jika lingkar gagal.
9. Simpan hasil, tutup app, buka lagi, buka ulang capture, edit, simpan sebagai hasil baru. Hapus hasil dan pastikan file tidak tampil lagi.
10. Airplane Mode setelah build/setup: capture, ketiga model, koreksi, dan riwayat berjalan tanpa internet. Catat waktu inferensi dan memori nyata pada iPhone.
11. Data sapi nyata: catat posisi kamera, jarak, kondisi kandang, dan apakah tubuh tertutup. Cek alur dari satu sisi sesuai prosedur keselamatan kandang. Target saat ini adalah fungsi berjalan; akurasi dicatat untuk Iterasi 2–3.
