[English](README.md) | [Bahasa Indonesia](README.id.md)

# DexForge

Modul Magisk/KernelSU profesional yang dirancang untuk menganalisis sumber daya perangkat secara dinamis dan mengoptimalkan cache ART/Dalvik menggunakan strategi kompilasi cerdas berbasis tingkatan perangkat (*tier-based*).

### Cara Kerja
Android mengompilasi aplikasi menggunakan Android Runtime (ART). Seiring waktu, atau setelah pembaruan sistem, kode terkompilasi dapat kehilangan tingkat optimasinya, mengakibatkan kelambatan peluncuran aplikasi (*sluggishness*) dan pemborosan baterai.
1. **Profiling Sumber Daya**: DexForge membaca RAM, sisa ruang penyimpanan, dan versi SDK Android HP.
2. **Klasifikasi Perangkat**: Mengelompokkan perangkat ke dalam kategori Flagship, Mid, atau Entry.
3. **Pencegahan Layar Tidur**: Melakukan override dinamis pada setelan timeout layar (`screen_off_timeout` + `svc power stayon`) agar layar tetap menyala penuh selama kompilasi tanpa bergantung pada status pengisian daya baterai (charger), lalu memulihkan setelan asli secara otomatis saat selesai atau batal.
4. **Rute Optimasi Cerdas**:
   - **Flagship**: Menggunakan kompilasi massal (`-a`) untuk mengompilasi seluruh aplikasi termasuk sistem bawaan (Settings, SystemUI) demi pengalaman penggunaan yang super lancar.
   - **Mid & Entry**: Menggunakan kompilasi bertahap khusus aplikasi pihak ketiga (`-3`) untuk menghemat penyimpanan, menjaga suhu perangkat, dan menghemat baterai.
5. **SELinux Safe Pipe**: Mengambil data standar output dan error melalui pipa shell internal terlebih dahulu untuk memintas pembatasan penulisan langsung ke `/data/adb/` oleh kebijakan SELinux Android.

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
