# Smart Bin — Tempat Sampah Otomatis Berbasis Arduino

**Embedded System Final Project | Group 17**

| Nama | NPM |
|---|---|
| Raja Avicenna Al-Kindi Vijasa | 2406416352 |
| Haidar Rafif Radithya | 2406408836 |
| Tomas Warren Wuisang | 2406423963 |
| Ahmad Malik Prasetyo | 2406416270 |

---

## 1. Pendahuluan

### Latar Belakang

Pengelolaan sampah adalah salah satu tantangan utama di lingkungan, terutama di perkotaan. Tempat sampah yang penuh tapi tidak segera dikosongkan, serta keharusan menyentuh pegangan tempat sampah secara langsung, menjadi dua permasalahan umum yang berdampak pada kebersihan dan kesehatan.

Perkembangan teknologi sistem embedded membuka peluang untuk menciptakan solusi yang lebih untuk mengatasi permasalahan tersebut. Dengan memanfaatkan mikrokontroler seperti Arduino Uno dan berbagai sensor, tempat sampah konvensional dapat diubah menjadi tempat sampah pintar yang interaktif, higienis, dan informatif.

### Solusi

Smart Bin adalah tempat sampah otomatis berbasis Arduino Uno yang dirancang untuk:

- **Membuka tutup secara otomatis** saat mendeteksi keberadaan tangan pengguna, sehingga tidak perlu menyentuh tutup tempat sampah secara langsung.
- **Memantau tingkat kepenuhan sampah secara real-time** dan menampilkannya pada layar LCD.
- **Memberikan notifikasi visual (LED) dan mengunci sistem** ketika kapasitas sampah telah mencapai batas maksimal (< 5 cm), serta dilengkapi *Push Button* untuk kontrol manual (*Manual Override*).

Proyek ini juga mengimplementasikan beberapa konsep inti mata kuliah Sistem Embedded, yaitu Hardware PWM (Timer1), Software Polling Counter, I2C (Low-Level), dan Finite State Machine (FSM).

---

## 2. Desain dan Implementasi Hardware

### Daftar Komponen

| Komponen | Jumlah |
|---|---|
| Arduino Uno (ATmega328P) | 1 |
| Sensor Ultrasonik HC-SR04 | 2 |
| Motor Servo SG90 | 1 |
| LCD Display 16x2 + I2C PCF8574 | 1 |
| LED | 1 |
| Push Button | 1 |
| Breadboard | 1 |
| Kabel Jumper | Secukupnya |
| Kardus | Secukupnya |
| Lakban | Secukupnya |

### Arsitektur Sistem

Sistem Smart Bin terdiri dari tiga subsistem utama:

a. Subsistem Deteksi Tangan (Sensor Ultrasonik Luar)
Sensor ultrasonik HC-SR04 pertama dipasang di bagian luar tempat sampah. Sensor ini mendeteksi keberadaan tangan pengguna pada jarak kurang dari 50 cm. Saat tangan terdeteksi, sinyal dikirim ke Arduino untuk mengaktifkan motor servo SG90 yang menggerakkan tutup ke posisi terbuka dengan pergerakan yang diperhalus. Tutup akan kembali menutup secara otomatis setelah tangan tidak lagi terdeteksi.

b. Subsistem Pemantauan Kepenuhan (Sensor Ultrasonik Dalam)
Sensor ultrasonik HC-SR04 kedua dipasang di bagian atas dalam tempat sampah. Sensor ini mengukur jarak antara sensor dengan permukaan sampah. Data jarak diproses menggunakan *Software Counter* oleh Arduino untuk mengukur tingkat jarak kepenuhan dalam sentimeter (cm) dengan akurat, dan dibekukan (*disabled*) saat tutup sedang terbuka untuk mencegah pembacaan palsu.

c. Subsistem Notifikasi & Manual Override
LED terhubung ke Arduino sebagai indikator. Saat sampah penuh (< 5 cm), LED akan menyala sebagai tanda peringatan dan sensor luar akan dimatikan (Terkunci). Sistem juga dilengkapi Push Button untuk melakukan Manual Override (mengunci tutup tetap terbuka di mode normal, atau membuka dan mereset sistem setelah sampah dibuang di mode penuh).

### Skematik

Skematik sistem dirancang menggunakan Proteus dengan simulasi awal menggunakan potensiometer sebelum perakitan hardware dilakukan. Seluruh komponen dirakit di atas breadboard dan diintegrasikan ke dalam wadah berbahan kardus sebagai badan tempat sampah.

---

## 3. Implementasi Software

### Bahasa & Platform

- Assembly (AVR) — digunakan untuk seluruh logika sistem, kontrol perangkat keras, pembacaan sensor ultrasonik, dan protokol komunikasi I2C.

### Modul-Modul yang Diimplementasikan

**Modul 2 — Assembly**
Semua pemrograman menggunakan bahasa Assembly tanpa tambahan library dari luar.

**Modul 4 — Arithmetic**
Operasi aritmatika digunakan untuk perhitungan operasi pada pergerakan motor servo dan juga konversi digit angka pada LCD.

**Modul 5 — Timer**
Counter1 digunakan untuk membangkitkan sinyal Fast PWM. 

**Modul 6 — Interrupt**
External Interrupt (INT0) digunakan untuk mendeteksi input dari push button. Saat tombol ditekan, interupsi terpicu untuk override pergerakan motor servo secara manual atau mereset sistem dari mode sampah penuh kembali ke mode normal.

**Modul 7 — PWM & EEPROM**
Sinyal PWM (Pulse Width Modulation) dipakai untuk mengatur sudut bukaan motor servo.

**Modul 9 — SPI & I2C**
Protokol I2C digunakan untuk menghubungkan Arduino dengan LCD agar dapat berkomunikasi.

### Alur Kerja Sistem

```text
[Loop Utama]
 ├── Baca Sensor Luar & Dalam (Software Counter)
 ├── Baca Status Tombol (Edge Detection)
 │
 ├── Jika Sampah Penuh (Dalam < 5cm):
 │    ├── Sensor Luar Dimatikan (Abaikan Tangan)
 │    ├── LED Menyala
 │    └── Tunggu Tombol Ditekan -> Buka -> Tutup via Tombol -> Reset ke Normal.
 │
 └── Jika Normal (Dalam >= 5cm):
      ├── LED Mati
      ├── Jika Tombol Ditekan -> Buka & KUNCI (Abaikan Sensor Luar)
      └── Jika Tidak Terkunci -> Buka jika Luar < 50cm, Tutup jika Luar >= 50cm.
```
 
---
 
## 4. Hasil Pengujian dan Evaluasi Performa
 
### Pengujian Sensor Deteksi Tangan
 
Sensor diuji pada berbagai jarak (5, 10, 15, 20, dan 25 cm):
 
| Jarak Uji | Hasil Deteksi |
|---|---|
| 10 cm | Terdeteksi  |
| 30 cm | Terdeteksi  |
| 45 cm | Terdeteksi  |
| 55 cm | Tidak terdeteksi  |
| >100 cm | Tidak terdeteksi  |

### Pengujian FSM, Sensor Kepenuhan, & Manual Override

Smart Bin ini diuji dengan berbagai kondisi kepenuhan sampah:

| Kondisi Sampah (Sensor Dalam) | Status LED | Fungsi Sensor Luar | Fungsi Tombol (Manual Override) |
|---|---|---|---|
| Normal (Jarak > 5 cm) | Mati | Aktif Buka/Tutup | Mengunci Tutup Tetap Terbuka |
| Penuh (Jarak < 5 cm) | Menyala | Tidak Aktif (Disabled) | Membuka untuk membuang isinya |
| Mode Penuh Ditutup Kembali via Tombol | Mati | Kembali Aktif | Me-reset State kembali ke Normal |


### Ringkasan Performa

| Fitur | Target | Hasil |
|---|---|---|
| Deteksi tangan (jangkauan) | ≤ 50 cm | Tercapai |
| Deteksi kepenuhan | < 5 cm | Tercapai |
| Waktu respons deteksi | < 100 ms | Tercapai |
| Kecepatan buka tutup | Presisi & Halus | Tercapai (Sweep Servo) |
| Stabilitas Servo | Tanpa Getaran | Tercapai (Hardware PWM Timer1) |
| Logika Mode Penuh | Tombol sebagai Reset | Tercapai (FSM Validated) |

---

## 5. Kesimpulan dan Pengembangan

### Kesimpulan

Proyek Smart Bin berhasil dirancang dan diimplementasikan sebagai sistem embedded yang baik. Seluruh fitur yang direncanakan, mulai dari pembuka tutup otomatis, pemantauan kepenuhan real-time pada LCD, sampai dengan kontrol tombol secara manual berhasil berjalan dengan baik.

### Pengembangan

- Konektivitas IoT: Menambahkan modul Wi-Fi (seperti ESP8266/ESP32) agar data kepenuhan dapat dipantau dari jarak jauh melalui aplikasi web atau mobile.
- Notifikasi Push: Membuat sistem pengiriman notifikasi otomatis saat tempat sampah penuh.
- Pemilah Sampah Otomatis: Menambahkan sensor untuk mendeteksi jenis sampah (organik/anorganik).