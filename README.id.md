[English](README.md) | [Bahasa Indonesia](README.id.md)

# DexForge

Modul Magisk/KernelSU yang dirancang untuk menganalisis HP secara otomatis dan membangun ulang (*rebuild*) cache ART/Dalvik menggunakan filter kompilasi yang paling optimal.

### Cara Kerja
Android menggunakan ART (Android Runtime) untuk mengompilasi aplikasi. Seiring waktu, atau setelah update sistem, cache ini bisa jadi kurang optimal, bikin HP kerasa lemot atau boros baterai.
1. DexForge membaca kapasitas RAM, sisa storage, dan versi Android HP.
2. Modul ini mengklasifikasikan HP ke dalam tier (Flagship, Mid, atau Entry).
3. Berdasarkan tier dan sisa ruang, modul memilih filter compiler `dex2oat` terbaik (misalnya, `speed-profile`, `speed`, `verify`, atau `quicken`).
4. Melakukan kompilasi ulang pada aplikasi yang terinstal untuk mengembalikan performa maksimal.

### Standar Keamanan & Kualitas
**Kenapa nggak dipaksa ke 'speed' semua?** Mengompilasi semua aplikasi pakai filter `speed` bakal ngabisin storage yang gede banget dan prosesnya lama. DexForge pakai sistem profiling pintar buat terapin filter agresif cuma di HP high-end yang storage-nya lega, dan pakai filter yang lebih aman buat HP kelas menengah atau entry-level. Modul ini juga punya fitur keamanan buat otomatis batalin proses kalau sisa storage di bawah 512MB.

### Fitur Utama
- **Smart Profiling**: Otomatis deteksi kemampuan HP (RAM & Storage).
- **Filter Dinamis**: Menerapkan filter kompilasi yang paling pas sesuai spesifikasi HP.
- **Safety Guards**: Mencegah bootloop atau sistem crash dengan mengecek batas storage dan versi Android.
- **Support Action Button**: Nggak perlu repot buka terminal; tinggal klik tombol dari aplikasi Magisk/KernelSU.

### Persyaratan
- Magisk v20.4+ atau KernelSU / APatch
- Android 7.0+ (SDK 24+)

### Instalasi
1. Download file `.zip` DexForge terbaru.
2. Buka aplikasi Magisk / KernelSU / APatch.
3. Masuk ke menu Modules.
4. Klik **Install from storage** lalu pilih file zip yang udah di-download.
5. Reboot HP.

### Cara Pakai

**01 Buka aplikasi root manager**
Buka Magisk, KernelSU, atau APatch di HP.

**02 Masuk ke Modules**
Buka tab modul tempat install DexForge.

**03 Tekan Action Button**
Cari modul DexForge, terus klik tombol **Action** (atau ikon play). Skripnya bakal otomatis jalan, baca spek HP, dan mulai proses *recompile*.

**04 Tunggu dan Reboot**
Biarin prosesnya jalan sampai selesai. Kalo udah muncul ringkasannya, sangat disarankan buat reboot HP biar efeknya maksimal.

### Disclaimer
Ini adalah alat eksperimental. Walaupun udah dikasih sistem pengaman, memodifikasi cache sistem kadang bisa bikin aplikasi error. Gunakan dengan bijak dan pastikan punya backup data penting.
