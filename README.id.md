[English](README.md) | [Bahasa Indonesia](README.id.md)

# DexForge

**Optimalkan kompilasi DEX/ART Android secara dinamis berdasarkan spesifikasi hardware perangkat Anda.**

![Lisensi](https://img.shields.io/badge/Lisensi-MIT-blue.svg)
![Android](https://img.shields.io/badge/Android-7.0%2B-green.svg)
![Versi](https://img.shields.io/badge/Versi-1.4-orange.svg)
![Root](https://img.shields.io/badge/Root-Magisk%20%7C%20KernelSU%20%7C%20APatch-red.svg)

## Deskripsi Umum

DexForge adalah modul root yang secara dinamis mengoptimalkan kompilasi DEX/ART Android. Modul ini menganalisis RAM dan versi Android Anda untuk memilih filter kompilasi terbaik, meningkatkan kelancaran sistem tanpa membebani hardware berspesifikasi rendah.

---

## Mengapa Memilih DexForge?

- **Performa yang Disesuaikan**: Memilih otomatis filter kompilasi terbaik (`speed`, `speed-profile`, atau `quicken`) sesuai kapasitas RAM perangkat.
- **Proteksi Keamanan**: Memeriksa daya baterai dan sisa ruang penyimpanan secara aktif sebelum berjalan untuk menghindari error.
- **Reset Cache Opsional**: Memungkinkan pembersihan cache kompilasi sebelum optimasi dimulai jika Anda ingin segar dari awal.

---

## Persyaratan Sistem

| Persyaratan | Detail |
|-------------|--------|
| Android | 7.0+ (API 24+) |
| Penyimpanan | Sisa penyimpanan minimal 512MB pada partisi `/data` |
| Baterai | Kapasitas minimal 15% (diabaikan jika perangkat sedang diisi daya) |
| Root | Magisk v20.4+, KernelSU, atau APatch |

---

## Instalasi & Konfigurasi

1. Pasang berkas ZIP modul melalui tab **Modules** di manajer root Anda (Magisk, KernelSU, atau APatch).
2. Jalankan kompilasi melalui tab **Action** di manajer root Anda.
3. **Reboot** (Mulai ulang) perangkat Anda untuk menerapkan kompilasi runtime secara penuh.
4. Periksa log eksekusi di: `/data/adb/modules/DexForge/dexforge.log`

---

## Penggunaan

### Konfigurasi Kompilasi Interaktif
Saat Anda menjalankan script aksi DexForge, Anda akan diminta menekan tombol fisik perangkat:
* Tekan **Volume ATAS** untuk membersihkan cache kompilasi dan melakukan optimasi bersih.
* Tekan **Volume BAWAH** (atau tunggu 10 detik) untuk mengkompilasi data yang ada secara bertahap.

### Simulasi Dry-Run (Developer CLI)
Mengaudit luaran compiler modul tanpa menulis data fisik ke penyimpanan (membutuhkan root shell):
```sh
su
/data/adb/modules/DexForge/action.sh --dry-run
```

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
├── customize.sh     # pemasangan dan konfigurasi saat modul diinstal
├── module.prop      # properti metadata modul
├── service.sh       # stub layanan booting
├── uninstall.sh     # mereset cache filter kompilasi dan menghapus log
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

## Pengembang & Lisensi

- **Pengembang**: [dyokism](https://github.com/dyokism)
- **Lisensi**: MIT
