# 📍 Aplikasi Pelacak GPS (Flutter)

## 🧠 Deskripsi Singkat
Aplikasi pelacak GPS berbasis **Flutter** dengan integrasi backend untuk pelacakan lokasi real-time, manajemen perangkat, geofence, dan notifikasi pengguna.

---

## ⚙️ Backend

> Saat ini belum termasuk dalam struktur proyek Flutter.

Aplikasi pelacak GPS memerlukan backend yang kuat untuk penyimpanan data, komunikasi real-time, dan logika bisnis. Berikut komponen utamanya:

### 🗄️ Basis Data (Database)
**Tujuan:** Menyimpan akun pengguna, perangkat GPS, data lokasi real-time & historis, konfigurasi geofence, dan peringatan.  
**Contoh:** PostgreSQL, MongoDB, Firebase Firestore, AWS DynamoDB.

### 🧩 API / Server
**Tujuan:** Menyediakan endpoint agar frontend Flutter bisa berinteraksi dengan backend.  
**Contoh:** Node.js (Express/NestJS), Python (Django/FastAPI), Go (Gin/Echo), Java (Spring Boot).

### 🔐 Otentikasi & Otorisasi
**Tujuan:** Kelola login, registrasi, reset password, dan akses data pengguna.  
**Contoh:** JWT, OAuth 2.0, Firebase Authentication, AWS Cognito.

### 🔁 Komunikasi Real-time
**Tujuan:** Mengirim pembaruan lokasi instan tanpa polling.  
**Contoh:** WebSockets (Socket.IO), Firebase Realtime Database, AWS IoT Core.

### 📍 Geocoding & Reverse Geocoding
**Tujuan:** Konversi koordinat geografis ↔ alamat.  
**Contoh:** Google Maps API, OpenStreetMap Nominatim, Mapbox Geocoding API.

### 🚧 Geofencing
**Tujuan:** Menentukan batas virtual & memicu notifikasi saat perangkat masuk/keluar area.  
**Contoh:** Implementasi geospasial database, API Geofencing.

### 🔔 Notifikasi Push
**Tujuan:** Kirim peringatan (geofence, baterai lemah, SOS, dll).  
**Contoh:** Firebase Cloud Messaging (FCM), Apple Push Notification service (APNs).

### ☁️ Hosting / Deployment
**Contoh:** AWS, Google Cloud Platform, Microsoft Azure, Heroku, DigitalOcean.

---

## 📱 Frontend (Aplikasi Flutter)

### 🔄 Manajemen State
Direktori `providers` menunjukkan penggunaan **Provider**. Pastikan strategi yang konsisten dan skalabel.  
**Alternatif:** Riverpod, Bloc, MobX.

### 🧭 Navigasi & Routing
Gunakan solusi routing yang jelas.  
**Contoh:** go_router, Navigator 2.0, auto_route.

### 📍 Layanan Lokasi
**Tujuan:** Mengambil lokasi perangkat & izin.  
**Pustaka:** geolocator, location.

### 🗺️ Integrasi Peta
**Tujuan:** Menampilkan peta interaktif.  
**Pustaka:** google_maps_flutter, flutter_map.

### 📡 Integrasi Bluetooth
**Tujuan:** Komunikasi dengan perangkat GPS eksternal.  
**Pustaka:** flutter_blue_plus, flutter_reactive_ble.

### 🧩 Komponen UI Utama
- Dashboard / Home Screen  
- Manajemen Perangkat  
- Pelacakan Real-time  
- Manajemen Geofence  
- Peringatan / Notifikasi  
- Profil & Akun Pengguna  
- Visualisasi Data (grafik, statistik)

### ⚠️ Penanganan Error & Logging
Gunakan penanganan kesalahan yang kuat dan logging untuk debugging.  
**Pustaka:** logger, sentry.

### 💾 Penyimpanan Lokal
**Tujuan:** Cache data, preferensi, mode offline.  
**Pustaka:** shared_preferences, hive, sqflite.

### 🧪 Pengujian
- **Unit Test**  
- **Widget Test**  
- **Integration Test**

---

## 🎨 Aset (Gambar, Ikon, Logo)

### 🖼️ Logo Aplikasi
Digunakan di splash screen, ikon aplikasi, dan dalam UI.  
**Format:** PNG / SVG.

### 🧭 Ikon
Untuk navigasi, tombol, perangkat, status, dll.  
**Format:** SVG / PNG.

### 📍 Penanda Peta
Ikon kustom untuk perangkat, pusat geofence, atau POI.  
**Format:** PNG.

### 🪶 Ilustrasi / Empty State
Untuk halaman kosong seperti “Belum ada perangkat yang ditambahkan”.

### 🚀 Splash Screen
**Format:** PNG / JPG.

### 🌐 Favicon (Web)
**Lokasi:** `web/favicon.png`

---

## 💡 Catatan
- Struktur backend belum diimplementasikan.  
- Aplikasi Flutter masih fokus pada UI, integrasi lokasi, dan Bluetooth.  
- Backend dan API akan ditambahkan di tahap berikutnya.

---

## 📦 Teknologi Utama
- **Frontend:** Flutter (Dart)  
- **Backend (rencana):** Node.js / Firebase / Go  
- **Database (rencana):** PostgreSQL / Firestore  
- **Real-time:** WebSocket / FCM  
- **Map:** Google Maps / OpenStreetMap

---

## 👨‍💻 Kontributor
- Akmal Ghani – Pengembang Flutter & UI/UX

---

## 📥 Get the app

Tester dapat mengunduh APK langsung dari GitHub Releases. Klik nama aplikasi di bawah untuk mengunduh APK terbaru:

- [GPS Tracker (Android APK)](https://github.com/GhaniPutra/GPS_Tracker/releases/latest/download/GPS_Tracker.apk)
