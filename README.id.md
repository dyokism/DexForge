# DexForge

<p align="center">
  <img src="DexForge.webp" alt="Logo DexForge" width="600">
</p>

<p align="center">
  <strong>Optimasi kompilasi ART dan penyelarasan thread CPU Android secara adaptif.</strong>
</p>

<p align="center">
  <a href="README.md">English</a> | <a href="README.id.md">Bahasa Indonesia</a>
</p>

## Ringkasan

Sistem Android menjalankan kompilasi latar belakang dengan profil seragam tanpa mempertimbangkan batas memori atau pola pemakaian aplikasi. DexForge mengoptimalkan eksekusi bytecode DEX dengan memilih filter kompilasi yang disesuaikan dengan kapasitas RAM dan riwayat peluncuran aplikasi. Modul ini juga mengatur alokasi thread compiler dan pembagian core CPU agar proses di latar belakang tidak mengganggu responsivitas antarmuka aplikasi.

Penjelasan teknis mekanisme kompilasi tersedia di [COMPILATION_REFERENCE.md](COMPILATION_REFERENCE.md).

## Fitur

- Membatasi thread compiler latar belakang ke core efisiensi agar antarmuka tetap lancar.
- Menentukan filter kompilasi (`speed`, `speed-profile`, `verify`, `quicken`) berdasarkan kapasitas RAM dan frekuensi pemakaian.
- Tombol Action di root manager untuk menjalankan optimasi manual dengan laporan progres per aplikasi.
- Menu tombol volume interaktif untuk memilih antara reset total atau kompilasi inkremental.
- Validasi awal level baterai dan sisa ruang penyimpanan sebelum proses berjalan.

## Persyaratan

| Komponen | Spesifikasi Minimum |
| :--- | :--- |
| Versi Android | Android 7.0 (API 24) atau lebih baru |
| Ruang Bebas | Minimal 512 MB pada partisi `/data` |
| Baterai | Minimal 15% (diabaikan jika sedang mengisi daya) |
| Manajer Root | Magisk (v20.4+), KernelSU, atau APatch |

## Instalasi

1. Unduh arsip `DexForge.zip` terbaru dari halaman [Releases](https://github.com/dyokism/DexForge/releases).
2. Pasang berkas zip melalui menu **Modules** di root manager.
3. Muat ulang (reboot) perangkat agar konfigurasi alokasi CPU aktif.

## Konfigurasi
 
Setelah boot selesai, DexForge membaca topologi CPU dan menetapkan properti sistem berikut untuk mengisolasi beban kerja compiler:

- **Berkas log**: `/data/adb/modules/DexForge/dexforge.log`

```properties
pm.dexopt.bg-dexopt=speed-profile
pm.dexopt.shared=speed
dalvik.vm.dex2oat-cpu-set=<core_efisiensi>
dalvik.vm.dex2oat-threads=<jumlah_thread>
dalvik.vm.background-dex2oat-cpu-set=<core_efisiensi>
dalvik.vm.background-dex2oat-threads=<jumlah_thread>
```

## Tombol Action

Kamu bisa menekan tombol **Action** pada kartu DexForge di KernelSU, APatch, atau Magisk kapan saja untuk menjalankan optimasi langsung:

- **Menu Reset Cache**: Tekan tombol **Volume Atas** untuk menghapus cache lama dan mengompilasi ulang dari awal. Tekan **Volume Bawah** (atau tunggu 10 detik) untuk melanjutkan kompilasi inkremental.
- **Mode Uji Coba (Dry-Run)**: Untuk melihat tindakan tanpa mengubah sistem, jalankan perintah berikut di terminal root:
  ```bash
  su -c "/data/adb/modules/DexForge/action.sh --dry-run"
  ```
