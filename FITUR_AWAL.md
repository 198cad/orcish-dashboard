# Dokumentasi Fitur Awal (Berdasarkan Skema Database Sistem & Manajemen Pengguna)

Dokumen ini menguraikan fitur-fitur UI awal yang dapat diimplementasikan berdasarkan struktur tabel dalam `database/DDL/CORE SYSTEM & USER MANAGEMENT.sql` dan skema validasi Zod di `database/interfaces/system-user-management.ts`. Fitur-fitur ini berpusat pada pengelolaan pengguna, peran, izin, dan fungsionalitas inti sistem.

## 1. Modul Manajemen Pengguna (User Management)

### 1.1. Pengelolaan Pengguna

- **Deskripsi:** Memungkinkan administrator untuk mengelola akun pengguna yang dapat mengakses sistem.
- **Fungsionalitas UI:**
  - **Daftar Pengguna:** Menampilkan daftar semua pengguna dengan informasi kunci (username, email, nama lengkap, status aktif).
  - **Tambah Pengguna Baru:** Formulir untuk membuat akun pengguna baru dengan validasi input untuk:
    - `username`: Wajib, minimal 3 karakter, maksimal 50 karakter.
    - `password`: Wajib, minimal 8 karakter (untuk input mentah, akan di-hash di backend).
    - `email`: Wajib, format email valid, maksimal 255 karakter.
    - `full_name`: Opsional, maksimal 150 karakter.
    - `phone_number`: Opsional, maksimal 50 karakter.
    - `is_active`: Checkbox untuk mengaktifkan/menonaktifkan akun (default: aktif).
  - **Edit Detail Pengguna:** Formulir untuk memperbarui informasi pengguna yang sudah ada.
  - **Hapus Pengguna:** Konfirmasi penghapusan pengguna.
  - **Login/Logout:** Antarmuka untuk otentikasi pengguna.
  - **Reset Kata Sandi:** Fungsionalitas untuk pengguna atau admin mereset kata sandi.

## 2. Modul Manajemen Peran & Izin (Role & Permission Management)

### 2.1. Pengelolaan Peran

- **Deskripsi:** Mendefinisikan dan mengelola peran yang dapat ditugaskan kepada pengguna untuk mengimplementasikan kontrol akses berbasis peran (RBAC).
- **Fungsionalitas UI:**
  - **Daftar Peran:** Menampilkan daftar peran yang tersedia (misalnya 'Admin', 'Sales Manager').
  - **Tambah/Edit Peran:** Formulir untuk membuat atau memperbarui peran dengan validasi untuk:
    - `role_name`: Wajib, minimal 1 karakter, maksimal 50 karakter.
    - `description`: Opsional.

### 2.2. Pengelolaan Izin

- **Deskripsi:** Mendefinisikan hak akses granular dalam sistem.
- **Fungsionalitas UI:**
  - **Daftar Izin:** Menampilkan daftar izin yang tersedia (misalnya 'item_create', 'sales_order_view_all').
  - **Tambah/Edit Izin:** Formulir untuk membuat atau memperbarui izin dengan validasi untuk:
    - `permission_name`: Wajib, minimal 1 karakter, maksimal 100 karakter.
    - `description`: Opsional.

### 2.3. Penugasan Peran Pengguna

- **Deskripsi:** Menghubungkan pengguna dengan satu atau lebih peran.
- **Fungsionalitas UI:**
  - Antarmuka untuk memilih pengguna dan menugaskan peran yang relevan.

### 2.4. Penugasan Izin Peran

- **Deskripsi:** Menghubungkan peran dengan satu atau lebih izin.
- **Fungsionalitas UI:**
  - Antarmuka untuk memilih peran dan menugaskan izin yang relevan.

## 3. Modul Log & Notifikasi Sistem (System Logs & Notifications)

### 3.1. Log Audit

- **Deskripsi:** Mencatat setiap aktivitas pengguna dan perubahan sistem untuk tujuan audit dan pemecahan masalah.
- **Fungsionalitas UI:**
  - **Tampilan Log:** Menampilkan daftar log dengan detail seperti tipe aksi, tabel/record yang terpengaruh, data lama/baru (dalam format JSON), alamat IP, user agent, dan timestamp.
  - **Filter & Pencarian:** Kemampuan untuk memfilter log berdasarkan pengguna, tipe aksi, tabel, atau rentang waktu.

### 3.2. Notifikasi

- **Deskripsi:** Menyediakan sistem notifikasi dalam aplikasi untuk memberi tahu pengguna tentang peristiwa penting.
- **Fungsionalitas UI:**
  - **Pusat Notifikasi:** Menampilkan daftar notifikasi untuk pengguna yang sedang login.
  - **Detail Notifikasi:** Menampilkan pesan, tipe notifikasi, link terkait, status baca, dan prioritas.
  - **Tandai sebagai Dibaca:** Fungsionalitas untuk menandai notifikasi sebagai sudah dibaca.

## 4. Modul Pengaturan Sistem (System Settings)

### 4.1. Pengelolaan Pengaturan

- **Deskripsi:** Mengelola pengaturan konfigurasi umum sistem yang dapat disesuaikan.
- **Fungsionalitas UI:**
  - **Daftar Pengaturan:** Menampilkan daftar kunci pengaturan dan nilainya.
  - **Edit Pengaturan:** Formulir untuk memperbarui nilai pengaturan dengan validasi untuk:
    - `setting_key`: Wajib, maksimal 100 karakter.
    - `setting_value`: Wajib, tidak boleh kosong.
    - `description`: Opsional.
    - `value_type`: Menunjukkan tipe data nilai (misalnya 'text', 'number', 'boolean', 'json').
    - `is_sensitive`: Checkbox untuk menandai pengaturan sensitif.

## 5. Modul Manajemen Tugas (Task Management)

### 5.1. Pengelolaan Tugas

- **Deskripsi:** Memungkinkan pengguna untuk membuat, menugaskan, dan melacak tugas-tugas.
- **Fungsionalitas UI:**
  - **Daftar Tugas:** Menampilkan daftar tugas dengan judul, deskripsi, penugasan, tanggal jatuh tempo, prioritas, dan status.
  - **Tambah/Edit Tugas:** Formulir untuk membuat atau memperbarui tugas dengan validasi untuk:
    - `title`: Wajib, minimal 1 karakter, maksimal 255 karakter.
    - `description`: Opsional.
    - `assignee_id`: Opsional, memilih pengguna yang ditugaskan.
    - `creator_id`: Wajib, pengguna yang membuat tugas.
    - `due_date`: Opsional, format tanggal YYYY-MM-DD.
    - `priority`: Pilihan 'High', 'Medium', 'Low' (default: 'Medium').
    - `status`: Pilihan 'Pending', 'In Progress', 'Completed', 'Cancelled' (default: 'Pending').
    - `completed_at`: Opsional, tanggal/waktu penyelesaian.
    - `related_document_type`, `related_document_id`: Opsional, untuk mengaitkan tugas dengan dokumen lain.

## 6. Modul Manajemen Karyawan (Employee Management)

### 6.1. Pengelolaan Karyawan

- **Deskripsi:** Mengelola informasi dasar karyawan perusahaan.
- **Fungsionalitas UI:**
  - **Daftar Karyawan:** Menampilkan daftar karyawan dengan kode, nama lengkap, jabatan, departemen, dll.
  - **Tambah/Edit Karyawan:** Formulir untuk membuat atau memperbarui data karyawan dengan validasi untuk:
    - `employee_code`: Wajib, unik, maksimal 50 karakter.
    - `full_name`: Wajib, minimal 1 karakter, maksimal 150 karakter.
    - `job_title`: Opsional, maksimal 100 karakter.
    - `department`: Opsional, maksimal 100 karakter.
    - `hire_date`: Opsional, format tanggal YYYY-MM-DD.
    - `termination_date`: Opsional, format tanggal YYYY-MM-DD.
    - `salary`: Opsional, angka positif.
    - `is_active`: Checkbox (default: aktif).
    - `contact_email`: Opsional, format email valid, maksimal 100 karakter.
    - `contact_phone`: Opsional, maksimal 50 karakter.
    - `user_id`: Opsional, untuk mengaitkan karyawan dengan akun pengguna.

## 7. Modul Gamifikasi (Gamification)

### 7.1. Pengelolaan Reward Gamifikasi

- **Deskripsi:** Mendefinisikan reward yang dapat diperoleh pengguna dalam sistem.
- **Fungsionalitas UI:**
  - **Daftar Reward:** Menampilkan daftar reward (nama, deskripsi, poin, URL gambar badge).
  - **Tambah/Edit Reward:** Formulir untuk membuat atau memperbarui reward dengan validasi untuk:
    - `reward_name`: Wajib, unik, maksimal 100 karakter.
    - `points_awarded`: Wajib, integer non-negatif.
    - `badge_image_url`: Opsional, URL valid.
    - `is_active`: Checkbox (default: aktif).

### 7.2. Pencapaian Pengguna

- **Deskripsi:** Mencatat reward yang telah diperoleh pengguna.
- **Fungsionalitas UI:**
  - **Daftar Pencapaian:** Menampilkan pencapaian pengguna (pengguna, reward, tanggal, poin yang didapat).

## 8. Modul Konfigurasi Laporan (Report Configuration)

### 8.1. Pembuatan Laporan Kustom

- **Deskripsi:** Memungkinkan pengguna untuk membuat dan menyimpan konfigurasi laporan kustom.
- **Fungsionalitas UI:**
  - **Daftar Konfigurasi Laporan:** Menampilkan laporan yang disimpan.
  - **Tambah/Edit Konfigurasi:** Formulir untuk mendefinisikan laporan dengan validasi untuk:
    - `report_name`: Wajib, minimal 1 karakter, maksimal 100 karakter.
    - `base_table`: Wajib, nama tabel dasar.
    - `columns_selected`: Pilihan kolom yang akan ditampilkan.
    - `filters`: Input untuk kondisi filter (misalnya, rentang tanggal, nilai tertentu).
    - `sorting_order`: Pilihan untuk pengurutan data.
    - `grouping_fields`: Pilihan untuk pengelompokan data.
    - `is_public`: Checkbox untuk membuat laporan dapat diakses publik.
    - `shared_with`: Pilihan pengguna/peran untuk berbagi laporan publik.

## 9. Modul Permintaan LLM (LLM Requests)

### 9.1. Log Interaksi LLM

- **Deskripsi:** Mencatat setiap interaksi dengan Large Language Models (LLM) untuk audit dan analisis.
- **Fungsionalitas UI:**
  - **Tampilan Log Permintaan LLM:** Menampilkan detail permintaan (prompt, respons, model yang digunakan, biaya, latensi, rating feedback, status validasi manusia).
  - **Filter & Pencarian:** Kemampuan untuk memfilter log berdasarkan pengguna, model, rating, atau status validasi.

Dokumentasi ini mencakup fitur-fitur inti yang dapat dibangun langsung dari skema database yang disediakan. Setiap fitur akan memerlukan implementasi UI yang sesuai (misalnya, tabel data, formulir input, tombol aksi) dan integrasi dengan backend untuk operasi CRUD dan logika bisnis.
