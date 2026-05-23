[English](README.md) | [Bahasa Indonesia](README.id.md)

# DexForge

**Format ulang cache Android Runtime Anda dengan optimasi dinamis ART/Dalvik berbasis tingkatan perangkat.**

![License](https://img.shields.io/badge/Lisensi-MIT-blue.svg)
![Android](https://img.shields.io/badge/Android-7.0%2B-green.svg)
![Version](https://img.shields.io/badge/Versi-1.1-orange.svg)
![Root](https://img.shields.io/badge/Root-Magisk%20%7C%20KernelSU%20%7C%20APatch-red.svg)

## Ringkasan

DexForge adalah modul Magisk/KernelSU/APatch profesional yang dirancang untuk menganalisis sumber daya perangkat secara dinamis dan mengoptimalkan cache ART (Android Runtime) serta Dalvik menggunakan strategi kompilasi cerdas berbasis tingkatan perangkat (*tier-based*).

### Cara Kerja

- **Hardware Profiling**: Mendeteksi kapasitas RAM dan spesifikasi HP untuk menentukan metode kompilasi terbaik.
- **Layar Tetap Menyala**: Menjaga layar ponsel Anda tetap menyala secara otomatis selama proses kompilasi.
- **Kompilasi Cerdas**: Mengompilasi semua aplikasi (speed) di flagship, atau aplikasi pengguna saja (speed-profile) di HP mid/entry agar hemat ruang.
- **Log Terpusat**: Menyimpan riwayat hasil kompilasi langsung di dalam folder modul.

---

## Kenapa Harus Menggunakan DexForge?

Kalau Anda sering merasakan aplikasi lambat terbuka atau antarmuka sistem patah-patah (micro-stutters) saat digunakan, DexForge membantu menyusun ulang cache sistem Anda demi menghasilkan:
- **Buka Aplikasi Lebih Cepat**: Mempersiapkan aplikasi Anda agar langsung terbuka instan saat diklik.
- **Navigasi Super Mulus**: Menghilangkan patah-patah gambar (frame drops) secara menyeluruh.
- **Hemat Daya Baterai**: Mengurangi beban kerja prosesor saat aplikasi dijalankan.
- **Optimasi Ramah Penyimpanan**: Menyesuaikan tingkat optimasi dengan kapasitas penyimpanan ponsel Anda.

---

## Fitur Proteksi

- **Anti-Bootloop**: Membatalkan kompilasi secara otomatis jika sisa penyimpanan di bawah 512MB.
- **Proteksi Baterai**: Menunda proses jika daya baterai di bawah 15% tanpa terhubung ke pengisi daya.
- **Reset Cache Pilihan**: Membersihkan cache ART menggunakan tombol volume fisik sebelum kompilasi dimulai.
- **Flashing Instan**: Pemasangan modul tanpa interaksi tombol volume saat flashing di recovery/manajer root.

---

## Persyaratan

| Persyaratan | Detail |
|-------------|--------|
| Android | 7.0+ (API 24+) |
| Root | Magisk v20.4+, KernelSU, atau APatch |

---

## Instalasi

1. Unduh berkas rilis `DexForge-v1.1.zip` terbaru.
2. Buka aplikasi Magisk, KernelSU, atau APatch.
3. Instal berkas ZIP melalui tab **Modules** (Modul).
4. **Reboot** perangkat Anda.

---

## Cara Pakai

1. Buka aplikasi manajer root Anda (Magisk, KernelSU, atau APatch).
2. Masuk ke tab **Modules** (Modul).
3. Tekan tombol **Action** (atau tombol "Jalankan") pada modul DexForge.
4. Gunakan tombol volume fisik untuk memilih opsi pembersihan cache dalam waktu 10 detik.
5. Tunggu proses hingga selesai (layar akan tetap menyala secara otomatis).
6. **Reboot** perangkat sangat disarankan setelah kompilasi selesai.

---

## Pengembang & Lisensi

- **Pengembang**: [dyokism](https://github.com/dyokism)
- **Lisensi**: MIT
