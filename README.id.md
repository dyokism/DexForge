[English](README.md) | [Bahasa Indonesia](README.id.md)

# DexForge

Modul Magisk/KernelSU profesional yang dirancang untuk menganalisis sumber daya perangkat secara dinamis dan mengoptimalkan cache ART/Dalvik menggunakan strategi kompilasi cerdas berbasis tingkatan perangkat (*tier-based*).

### Cara Kerja
DexForge mengoptimalkan cache Android Runtime (ART) secara dinamis:
1. **Profiling**: Membaca RAM, penyimpanan kosong, dan versi SDK untuk menentukan tingkatan perangkat (Flagship, Mid, atau Entry).
2. **Pencegahan Layar Tidur**: Mengambil alih `screen_off_timeout` agar layar tetap menyala selama proses berlangsung, lalu memulihkannya secara otomatis saat selesai.
3. **Rute Cerdas**: Mengompilasi seluruh paket (`-a`) pada flagship demi kelancaran maksimal, atau aplikasi pengguna saja (`-3`) pada mid/entry untuk menghemat penyimpanan dan menjaga suhu.
4. **Penangkapan Keluaran**: Menangkap keluaran log kompilasi via variabel shell sebelum ditulis ke `/data/adb/` untuk menghindari hambatan izin dari sub-proses sistem.


### Standar Keamanan & Kualitas
- **Proteksi Penyimpanan Rendah**: Proses otomatis dibatalkan jika sisa penyimpanan di bawah 512MB demi mencegah bootloop.
- **Ambang Batas Baterai**: Proses diblokir jika daya baterai di bawah 15% dan tidak terhubung ke pengisi daya.
- **Pembersihan Cache Interaktif**: Opsi interaktif via tombol volume fisik untuk membersihkan cache sebelum optimasi dimulai, lengkap dengan detail konsekuensi waktu kompilasi yang lebih lama.
- **Pemasangan Hening (Magisk Silent Install)**: Pemasangan instan tanpa gangguan interaksi tombol volume saat flashing, seluruh interaksi dipindahkan ke tombol Action.

### Persyaratan
- Magisk v20.4+ atau KernelSU / APatch
- Android 7.0+ (SDK 24+)

### Instalasi
1. Unduh berkas rilis `DexForge-v1.1.zip` terbaru.
2. Buka aplikasi Magisk, KernelSU, atau APatch.
3. Masuk ke bagian Modul.
4. Pilih **Instal dari penyimpanan** lalu tentukan berkas zip yang telah diunduh.
5. Reboot perangkat Anda.

### Cara Pakai
1. Buka aplikasi root manager Anda.
2. Navigasikan ke bagian modul.
3. Tekan tombol **Action** (atau tombol "Jalankan") pada modul DexForge.
4. Gunakan tombol volume fisik untuk memilih opsi pembersihan cache dalam waktu 10 detik.
5. Tunggu proses hingga selesai (layar akan tetap menyala secara otomatis). Reboot perangkat sangat disarankan setelah kompilasi selesai.

### Disclaimer
Ini adalah alat optimasi tingkat lanjut. Meskipun sistem keamanan ketat telah diterapkan, memodifikasi cache sistem melibatkan operasi tingkat rendah. Gunakan secara bijak.
