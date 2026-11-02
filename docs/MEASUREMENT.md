# Spesifikasi pengukuran v0

## Panjang badan

Dua titik pengguna: ujung bahu dan tulang duduk/pin yang terlihat pada sisi yang sama. Definisi final perlu diselaraskan dengan prosedur referensi peternakan. Kandidat AP10K hanya titik awal. Kedua piksel dipetakan melalui LiDAR ke 3D. PB = norma Euclidean selisih koordinat × 100 cm/m.

## Lingkar dada sementara

Pengguna menempatkan titik atas dan bawah tubuh pada bidang tepat di belakang kaki depan. Estimator mengambil 37 lokasi di sepanjang garis penghubung, membaca median neighborhood depth dengan confidence, lalu memproyeksikan titik 3D ke sumbu section.

Asumsi sementara: kedua ujung mewakili batas tinggi pada bidang tengah tubuh; kurva sisi dekat kamera mengikuti separuh ellipse; sisi tersembunyi simetris; arah pengambilan mendekati tegak lurus tubuh. Asumsi ujung section khususnya dapat bias karena perspektif dan silhouette; ini perlu diuji pada data nyata.

Setengah tinggi `b = |P_bawah - P_atas|/2`. Untuk setiap titik, `t` adalah posisi sepanjang sumbu, dinormalisasi oleh b, dan `r` adalah tonjolan depth menuju kamera relatif chord. Fit least squares `r ≈ a sqrt(1-t²)` menghasilkan setengah lebar a. Keliling dihitung dengan pendekatan Ramanujan ellipse.

Syarat teknis awal: minimal 24 sampel dari 37; a > 4 cm; 0.12 < a/b < 1.5; residual fit < 6 cm. Ini **heuristik awal** untuk mencegah output invalid, bukan confidence interval atau bukti akurasi. Metode ini adalah implementasi baseline sendiri, bukan replikasi lengkap paper Peng et al.

Satu foto satu sisi tidak mengobservasi sisi tersembunyi. Jangan menggandakan lebar silhouette gambar dan menyebutnya lingkar aktual. Jika fit gagal, hanya panjang yang ditampilkan; LD dan bobot tidak tersedia.

## Sampling depth

Neighborhood 3×3; sedikitnya 3 nilai finite dalam rentang 0.25–5 m, confidence ARKit ≥ medium. Selisih maksimum-minimum harus < 8 cm untuk menolak percampuran tubuh dan latar. Konstanta ini perlu ditinjau pada iPhone di kandang; belum menjadi rekomendasi jarak penggunaan.

## Winter

`BW_kg = HG_cm² × BL_cm / 10815.15`.

Hanya mode Sapi yang memanggil rumus. Tidak ada faktor breed otomatis. Galat lingkar berpengaruh dua kali dalam pendekatan galat relatif: `dBW/BW ≈ 2 dHG/HG + dBL/BL`. Karena itu penggantian model pose saja mungkin belum cukup memperbaiki bobot.

## Pemisahan galat saat Iterasi 2–3

1. Ukur hasil dengan titik yang ditentukan ahli: evaluasi depth/geometri.
2. Bandingkan titik otomatis dengan titik ahli: evaluasi pose.
3. Bandingkan PB/LD dengan pita ukur referensi: evaluasi ukuran.
4. Masukkan PB/LD referensi ke Winter dan bandingkan timbangan: evaluasi formula.
5. Baru evaluasi seluruh pipeline pada sapi yang tidak masuk data latihan.
