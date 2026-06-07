# DexForge

<p align="center">
  <img src="DexForge.webp" alt="Logo DexForge" width="600">
</p>

<p align="center">
  <strong>Optimalkan kompilasi DEX/ART Android secara dinamis berdasarkan profil perangkat keras perangkat Anda.</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Lisensi-MIT-d35400?style=for-the-badge" alt="Lisensi">
  <img src="https://img.shields.io/badge/Android-7.0%2B-ff7300?style=for-the-badge&logo=android&logoColor=white" alt="Android">
  <img src="https://img.shields.io/badge/Versi-2.0-ff9f0a?style=for-the-badge&logo=github&logoColor=white" alt="Versi">
  <img src="https://img.shields.io/badge/Root-KSU%20%7C%20APatch%20%7C%20Magisk-e65c00?style=for-the-badge&logo=linux&logoColor=white" alt="Root">
  <br>
  <br>
  <a href="README.md">English</a> | <a href="README.id.md">Bahasa Indonesia</a>
</p>

## Deskripsi Umum

DexForge adalah modul root lintas platform Android yang dirancang untuk mengoptimalkan kompilasi DEX/ART sistem secara dinamis. Dengan menganalisis tier RAM perangkat, SDK level, status baterai, dan sisa penyimpanan saat eksekusi, DexForge secara otomatis menetapkan filter kompilasi yang paling sesuai—mulai dari `speed` untuk perangkat flagship berspesifikasi tinggi, hingga `speed-profile` atau `quicken` untuk perangkat keras entry dan mid-tier. Analisis berbasis perangkat keras ini memastikan waktu muat aplikasi dipersingkat dan kelancaran sistem dimaksimalkan tanpa membebani perangkat berspesifikasi lebih rendah.

---

## Mengapa Memilih DexForge?

- **Performa Terarah**: Memilih filter kompilasi terbaik secara otomatis (`speed`, `speed-profile`, atau `quicken`) sesuai dengan kapasitas RAM perangkat Anda.
- **Proteksi Failsafe**: Secara aktif memverifikasi kapasitas baterai dan sisa penyimpanan sebelum berjalan untuk mencegah kerusakan data sistem.
- **Reset Cache Interaktif**: Menyediakan opsi pembersihan cache kompilasi sebelum proses optimasi dimulai untuk penyegaran penuh.

---

## Cara Penggunaan

### 1. Instalasi & Konfigurasi
* Unduh berkas `DexForge.zip` terbaru dari halaman [Releases](https://github.com/dyokism/DexForge/releases).
* Pasang berkas ZIP melalui tab **Modules** di manajer root Anda (Magisk, KernelSU, atau APatch).
* **Mulai ulang (reboot)** perangkat Anda untuk menginisialisasi layanan latar belakang dan pengawas thread inti secara penuh.

### 2. Eksekusi Aksi (Tombol Action)
* Jalankan mesin kompilasi dengan mengetuk tombol **Action** di manajer root Anda.
* **Perintah Cache Interaktif**: Saat awal berjalan, tekan tombol **Volume ATAS** untuk melakukan pembersihan penuh (menghapus cache kompilasi yang ada terlebih dahulu) atau **Volume BAWAH** (atau tunggu 10 detik) untuk menjalankan kompilasi bertahap (incremental).
* Hasil optimasi dan catatan eksekusi disimpan di: `/data/adb/modules/DexForge/dexforge.log`

### 3. Mode Audit Dry-Run (CLI)
* Untuk mensimulasikan eksekusi dan memverifikasi pemilihan compiler tanpa menulis data fisik ke penyimpanan, jalankan perintah berikut menggunakan root shell:
  ```sh
  su
  /data/adb/modules/DexForge/action.sh --dry-run
  ```

---

## Detail Teknis

### Klasifikasi Berbasis Perangkat Keras
* **Tier Flagship (> 6144 MB RAM)**: Menerapkan filter `speed` (kompilasi penuh kode mesin AOT) untuk efisiensi CPU maksimal.
* **Tier Mid (3072 MB - 6144 MB RAM)**: Menerapkan filter `speed-profile` (Profile-Guided Optimization). Ini berfungsi sebagai pelindung, mengabaikan permintaan kompilasi `speed` penuh untuk melindungi sistem dari kehabisan ruang penyimpanan dan kegagalan memori virtual (OOM). Jika data profil tidak mencukupi, sistem akan beralih ke `verify` (API >= 31) atau `quicken` (API < 31).
* **Tier Entry (<= 3072 MB RAM)**: Menerapkan filter `verify` (API >= 31) atau `quicken` (API < 31) untuk menjaga penggunaan ruang penyimpanan tetap minimal dan mencegah tekanan memori pada RAM fisik.

### Protokol Validasi Keamanan Sistem
* **Proteksi Penyimpanan**: Memeriksa sisa penyimpanan kontigu pada partisi `/data` menggunakan pemisahan kolom whitespace POSIX atas output `df -k`. Jika sisa penyimpanan di bawah **512MB**, proses kompilasi akan dihentikan untuk mencegah kerusakan sistem file dan bootloop.
* **Proteksi Baterai**: Mengambil metrik baterai dari sysfs `/sys/class/power_supply/battery/` dengan fallback otomatis ke layanan binder `dumpsys battery`. Eksekusi akan diblokir jika perangkat tidak sedang diisi daya dan kapasitas baterai di bawah **15%**.

### Pengaturan Core Late-Boot (`service.sh`)
* **Core Affinity Pinning**: Menjalankan pengawas pemungutan suara awal booting yang mengait ke `sys.boot_completed`. Setelah booting selesai, ia mengonfigurasi properti sistem (`dalvik.vm.dex2oat-cpu-set=0,1,2,3` dan `dalvik.vm.dex2oat-threads=4`) untuk membatasi operasi compiler latar belakang hanya pada core efisiensi logis. Langkah ini mencegah throttling termal CPU dan menjaga responsivitas sistem.

---

## Persyaratan Sistem

| Persyaratan | Detail |
|-------------|--------|
| Android | 7.0+ (API 24+) |
| Penyimpanan | Sisa penyimpanan minimal 512MB pada partisi `/data` |
| Baterai | Kapasitas minimal 15% (diabaikan jika perangkat sedang diisi daya) |
| Root | Magisk, KernelSU, atau APatch |

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

## Cara Kerja

```mermaid
flowchart TD
    Start([Mulai: Flash ZIP Modul]) --> Install[1. Ekstrak action.sh & Aset Modul]
    Install --> Setup[2. Registrasi Aksi di Manajer Root]
    Setup --> Trigger[3. Jalankan action.sh via Tombol Aksi]
    Trigger --> EnvCheck[4. Profil RAM, SDK, Penyimpanan & Baterai]
    EnvCheck --> Verification{Validasi Persyaratan?}
    
    Verification -- Gagal --> Abort[Abort: Penghentian Sistem yang Aman]
    Verification -- Lolos --> VolumePrompt{Volume ATAS ditekan dalam 10 detik?}
    
    VolumePrompt -- Ya --> CacheReset[Aktifkan Reset Cache Kompilasi]
    VolumePrompt -- Tidak / Timeout --> CompileOnly[Matikan Reset Cache]
    
    CacheReset --> DeviceTier{Klasifikasi Tier RAM Perangkat?}
    CompileOnly --> DeviceTier
    
    DeviceTier -- Flagship --> Bulk[Jalankan kompilasi massal filter speed -a]
    DeviceTier -- Mid / Entry --> Scan[Pindai Aplikasi Pihak Ketiga -3]
    
    Scan --> ProcessApps[Kompilasi Aplikasi Satu-per-Satu + Progres]
    Bulk --> Output[Buat berkas dexforge.log & Ringkasan Hasil]
    ProcessApps --> Output
    
    Output --> Finish([Selesai: Mulai Ulang Perangkat])

    %% Kustomisasi Tampilan dan Warna (Tema Gelap Ultra-Redup)
    classDef startEnd fill:#1b2c24,stroke:#34d399,stroke-width:1.5px,color:#e6f4ea;
    classDef fail fill:#2c1b1b,stroke:#f87171,stroke-width:1.5px,color:#fce8e6;
    classDef decision fill:#2d2216,stroke:#fbbf24,stroke-width:1.5px,color:#fef3c7;
    classDef process fill:#1e293b,stroke:#475569,stroke-width:1px,color:#f1f5f9;
    
    class Start,Finish startEnd;
    class Abort fail;
    class Verification,VolumePrompt,DeviceTier decision;
    class Install,Setup,Trigger,EnvCheck,CacheReset,CompileOnly,Bulk,Scan,ProcessApps,Output process;
```

---

## Pengembang, Kredit & Lisensi

- **Pengembang**: [dyokism](https://github.com/dyokism)
- **Lisensi**: [MIT](LICENSE)
- **Kredit & Apresiasi**:
  - **Android Runtime (ART)** oleh [Google](https://source.android.com/devices/tech/dalvik)
  - **Manajer Root**: [Magisk](https://github.com/topjohnwu/Magisk), [KernelSU](https://github.com/tiann/KernelSU), dan [APatch](https://github.com/bmax121/APatch)
```
