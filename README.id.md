# DexForge

<p align="center">
  <img src="DexForge.webp" alt="Logo DexForge" width="600">
</p>

<p align="center">
  <strong>Optimalkan kompilasi DEX/ART Android secara dinamis berdasarkan perangkat keras Anda.</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Lisensi-MIT-d35400?style=for-the-badge" alt="Lisensi">
  <img src="https://img.shields.io/badge/Android-7.0%2B-ff7300?style=for-the-badge&logo=android&logoColor=white" alt="Android">
  <img src="https://img.shields.io/badge/Versi-2.2-ff9f0a?style=for-the-badge&logo=github&logoColor=white" alt="Versi">
  <img src="https://img.shields.io/badge/Root-KSU%20%7C%20APatch%20%7C%20Magisk-e65c00?style=for-the-badge&logo=linux&logoColor=white" alt="Root">
  <br>
  <br>
  <a href="README.md">English</a> | <a href="README.id.md">Bahasa Indonesia</a>
</p>

## Deskripsi

DexForge adalah modul root yang mengoptimalkan aplikasi kamu dengan memilih filter kompilasi DEX terbaik sesuai hardware perangkat.


## Kenapa Pakai DexForge?

- **Performa yang disesuaikan**: Otomatis memilih filter kompilasi terbaik (`speed`, `speed-profile`, atau `verify`/`quicken`) berdasarkan kapasitas RAM dan statistik penggunaan aplikasi.
- **Proteksi keamanan**: Cek level baterai dan sisa penyimpanan sebelum berjalan untuk mencegah error.
- **Menu cache interaktif**: Opsi untuk membersihkan cache kompilasi sebelum optimasi dimulai supaya mulai dari awal yang bersih.


## Cara Penggunaan

### 1. Instalasi
* Download `DexForge.zip` terbaru dari halaman [Releases](https://github.com/dyokism/DexForge/releases).
* Flash lewat root manager kamu (Magisk, KernelSU, atau APatch).
* **Reboot** supaya modul bisa mulai bekerja di latar belakang.

### 2. Menjalankan Optimizer
* Buka root manager dan tekan tombol **Action** pada modul DexForge.

> [!WARNING]
> Kalau kamu pilih bersihkan cache, kompilasi di beberapa (dan akhirnya semua) perangkat bakal jauh lebih lama. Lakukan dengan pertimbangan sendiri.

* **Menu Cache**: Saat dimulai, modul akan menanyakan pertanyaan. Tekan **Volume ATAS** kalau mau bersihkan cache lama dulu (mulai bersih). Tekan **Volume BAWAH** (atau tunggu 10 detik) kalau mau pertahankan cache lama dan cuma update.
* Kamu bisa baca hasilnya nanti di: `/data/adb/modules/DexForge/dexforge.log`

### 3. Mode Uji Coba
* Mau lihat apa yang DexForge akan lakukan tanpa mengubah apa pun? Buka terminal root (seperti Termux) dan ketik:
  ```sh
  su
  /data/adb/modules/DexForge/action.sh --dry-run
  ```


## Detail Teknis

### Optimasi Hardware & Prioritas Penggunaan Aplikasi
* **Ponsel flagship (RAM 6GB+)**: Optimasi semua aplikasi untuk `speed` maksimum. Proses satu per satu biar ponsel nggak freeze. Kalau kamu bersihkan cache, modul cek penggunaan aplikasi dan set aplikasi yang jarang dipakai ke `speed-profile` buat hemat waktu. Kalau nggak bersihkan cache, modul skip cek penggunaan biar prosesnya lebih cepat.
* **Ponsel mid-range (RAM 3GB sampai 6GB)**: Cek penggunaan aplikasi buat tentukan pengaturan terbaik. Aplikasi paling sering dipakai dapat `speed`, aplikasi biasa dapat `speed-profile`, dan aplikasi yang nggak pernah dipakai dapat `verify` (atau `quicken` di Android lama). Ini mencegah ponsel kehabisan memori atau penyimpanan.
* **Ponsel entry-level (RAM 3GB atau kurang)**: Batasi optimasi ke `speed-profile` untuk aplikasi teratas, dan `verify` atau `quicken` untuk sisanya. Hemat daya CPU dan penyimpanan.

>*Kalau ponsel kamu punya RAM 8GB, bukan berarti ponsel itu beneran "flagship". Ini cuma buat klasifikasi aja :)*

### Pemeriksaan Keamanan Sistem
* **Cek penyimpanan**: Kalau sisa ruang kosong kurang dari **512MB**, proses berhenti. Ini melindungi ponsel dari bootloop.
* **Cek baterai**: Kalau ponsel nggak lagi ngecas dan baterai di bawah **15%**, proses berhenti buat mencegah mati mendadak.

### Tuning Latar Belakang (`service.sh`)
* **Kontrol core CPU**: Setelah ponsel selesai booting, script latar belakang memaksa compiler sistem cuma pakai core CPU kecil yang hemat energi. Ini mencegah overheating atau lag saat kamu pakai ponsel.


## Persyaratan

| Persyaratan | Detail |
|-------------|--------|
| Android | 7.0+ (API 24+) |
| Penyimpanan | Minimal 512MB ruang kosong di partisi `/data` |
| Baterai | Minimal 15% (diabaikan kalau lagi ngecas) |
| Root | Magisk v20.4+, KernelSU, atau APatch |


## Lisensi

Proyek ini dilisensikan di bawah MIT License. Lihat [LICENSE](LICENSE) untuk detail lengkap.
