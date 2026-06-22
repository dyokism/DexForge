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
  <img src="https://img.shields.io/badge/Versi-2.1.1-ff9f0a?style=for-the-badge&logo=github&logoColor=white" alt="Versi">
  <img src="https://img.shields.io/badge/Root-KSU%20%7C%20APatch%20%7C%20Magisk-e65c00?style=for-the-badge&logo=linux&logoColor=white" alt="Root">
  <br>
  <br>
  <a href="README.md">English</a> | <a href="README.id.md">Bahasa Indonesia</a>
</p>

## Deskripsi Umum

DexForge adalah modul root Android yang mengoptimalkan aplikasi di ponsel Anda agar terbuka lebih cepat dan berjalan lebih lancar. 

Alih-alih menggunakan pengaturan yang sama untuk setiap ponsel, DexForge memeriksa perangkat keras Anda—seperti RAM, versi Android, tingkat baterai, dan sisa penyimpanan. Berdasarkan pemeriksaan ini, modul akan secara otomatis memilih metode optimasi terbaik untuk perangkat spesifik Anda. 

Untuk ponsel kelas atas, ia berfokus pada kecepatan maksimum. Untuk ponsel lama atau kelas bawah, ia menyeimbangkan kecepatan dan ruang penyimpanan agar ponsel Anda tidak kelebihan beban atau melambat.

---

## Mengapa Memilih DexForge?

- **Performa Terarah**: Secara otomatis memilih filter kompilasi terbaik (`speed`, `speed-profile`, atau `verify`/`quicken`) berdasarkan kapasitas RAM dan statistik penggunaan aplikasi Anda.
- **Proteksi Keamanan**: Aktif memeriksa level baterai dan sisa ruang penyimpanan sebelum berjalan untuk mencegah kerusakan/error.
- **Menu Cache Interaktif**: Memberikan opsi untuk membersihkan cache kompilasi sebelum optimasi dimulai untuk penyegaran penuh.

---

## Cara Penggunaan

### 1. Instalasi
* Unduh berkas `DexForge.zip` terbaru dari halaman [Releases](https://github.com/dyokism/DexForge/releases).
* Pasang berkas ZIP menggunakan manajer root Anda (Magisk, KernelSU, atau APatch).
* **Mulai ulang (Reboot)** ponsel Anda agar modul dapat mulai bekerja di latar belakang.

### 2. Menjalankan Optimizer
* Buka manajer root Anda dan tekan tombol **Action** pada modul DexForge.

> [!WARNING]
> Jika Anda memilih untuk membersihkan cache, kompilasi pada beberapa (dan pada akhirnya semua) perangkat akan memakan waktu jauh lebih lama. Lakukan dengan kebijaksanaan Anda sendiri.

* **Menu Cache**: Saat dimulai, modul akan menanyakan sebuah pertanyaan. Tekan **Volume ATAS** jika Anda ingin membersihkan cache lama terlebih dahulu (mulai dari awal yang bersih). Tekan **Volume BAWAH** (atau tunggu 10 detik) jika Anda ingin mempertahankan cache lama dan hanya memperbaruinya.
* Anda dapat membaca hasil log-nya nanti di: `/data/adb/modules/DexForge/dexforge.log`

### 3. Mode Uji Coba (Test Mode)
* Jika Anda ingin melihat apa yang akan dilakukan DexForge tanpa benar-benar mengubah apa pun di ponsel Anda, Anda dapat menjalankan uji coba. Buka terminal root (seperti Termux) dan ketik:
  ```sh
  su
  /data/adb/modules/DexForge/action.sh --dry-run
  ```

---

## Detail Teknis

### Optimasi Perangkat Keras & Prioritas Penggunaan Aplikasi

* **Ponsel Flagship (RAM Lebih dari 6GB)**: Mengoptimalkan semua aplikasi untuk `speed` maksimum. Memproses aplikasi satu per satu untuk menghindari freeze pada ponsel. Jika Anda memilih untuk membersihkan cache, modul akan memeriksa penggunaan aplikasi Anda dan mengatur aplikasi yang jarang digunakan ke `speed-profile` untuk menghemat waktu. Jika Anda tidak membersihkan cache, modul melewati pemeriksaan penggunaan aplikasi untuk mempercepat proses.
* **Ponsel Kelas Menengah (RAM 3GB hingga 6GB)**: Memeriksa penggunaan aplikasi Anda untuk menentukan pengaturan terbaik. Aplikasi yang paling sering digunakan mendapat pengaturan `speed`, aplikasi normal mendapat `speed-profile`, dan aplikasi yang tidak pernah digunakan mendapat `verify` (atau `quicken` di versi Android lama). Ini mencegah ponsel kehabisan memori atau ruang penyimpanan.
* **Ponsel Entry-Level (RAM 3GB atau kurang)**: Membatasi optimasi ke `speed-profile` untuk aplikasi teratas Anda, dan `verify` atau `quicken` untuk aplikasi lainnya. Ini menghemat daya CPU dan ruang penyimpanan ponsel Anda.

>*Jika ponsel Anda memiliki RAM 8GB, bukan berarti ponsel tersebut benar-benar "flagship". Ini hanya untuk memudahkan klasifikasi! :)*

### Pemeriksaan Keamanan Sistem
* **Pemeriksaan Penyimpanan**: Memeriksa berapa banyak sisa ruang kosong di ponsel Anda. Jika sisa ruang kosong kurang dari **512MB**, proses akan dihentikan. Ini melindungi ponsel Anda dari bootloop.
* **Pemeriksaan Baterai**: Memeriksa level baterai Anda. Jika ponsel tidak sedang diisi daya dan baterai di bawah **15%**, proses akan dihentikan untuk mencegah ponsel mati mendadak.

### Penyesuaian Latar Belakang (`service.sh`)
* **Kontrol Inti CPU**: Setelah ponsel Anda selesai booting, skrip latar belakang akan memeriksa prosesor Anda. Skrip ini memaksa compiler latar belakang sistem untuk hanya menggunakan inti CPU kecil yang hemat energi. Ini mencegah ponsel Anda dari overheating atau lag saat Anda menggunakannya.

---

## Persyaratan Sistem

| Persyaratan | Detail |
|-------------|--------|
| Android | 7.0+ (API 24+) |
| Penyimpanan | Sisa penyimpanan minimal 512MB pada partisi `/data` |
| Baterai | Kapasitas minimal 15% (diabaikan jika perangkat sedang diisi daya) |
| Root | Magisk v20.4+, KernelSU, atau APatch |

---

## Struktur Berkas

```text
DexForge/
├── META-INF/
│   └── com/
│       └── google/
│           └── android/
│               ├── update-binary
│               └── updater-script
├── action.sh        # mesin utama pemilihan dan eksekusi kompilasi
├── changelog.md     # catatan perubahan untuk melacak riwayat versi modul
├── customize.sh     # pemasangan dan konfigurasi saat modul diinstal
├── module.prop      # metadata properti modul
├── service.sh       # late-boot watchdog & pengatur thread/core affinity
├── uninstall.sh     # menghapus berkas sisa saat modul dihapus
└── update.json      # konfigurasi metadata pembaruan
```

---

## Pengembang, Kredit & Lisensi

- **Pengembang**: [dyokism](https://github.com/dyokism)
- **Lisensi**: [MIT](LICENSE)
- **Kredit & Apresiasi**:
  - **Android Runtime (ART)** oleh [Google](https://source.android.com/devices/tech/dalvik)
  - **Manajer Root**: [Magisk](https://github.com/topjohnwu/Magisk), [KernelSU](https://github.com/tiann/KernelSU), dan [APatch](https://github.com/bmax121/APatch)
