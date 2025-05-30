# Dokumentasi Skema Database

Dokumen ini menjelaskan struktur skema database yang didefinisikan dalam `database/schema/schema.ts`.

## Ringkasan Tabel

| Nama Tabel           | Fungsi                                                                                                                         |
| :------------------- | :----------------------------------------------------------------------------------------------------------------------------- |
| `users`              | Menyimpan data dasar pengguna, termasuk kredensial dan status akun, serta informasi audit dasar.                               |
| `roles`              | Mendefinisikan peran-peran yang ada dalam sistem, mendukung hierarki peran melalui `parentRoleId`.                             |
| `permissions`        | Mencatat semua izin diskrit yang dapat diberikan dalam sistem.                                                                 |
| `user_roles`         | Menghubungkan pengguna dengan peran yang mereka miliki, memungkinkan satu pengguna memiliki banyak peran.                      |
| `role_permissions`   | Menghubungkan peran dengan izin yang terkait dengannya, mendefinisikan izin apa yang dimiliki oleh setiap peran.               |
| `object_types`       | Mengkategorikan jenis-jenis objek dalam sistem yang dapat memiliki izin spesifik.                                              |
| `object_permissions` | Mengelola izin yang diberikan pada objek individual, memungkinkan kontrol akses yang granular berdasarkan pengguna atau peran. |
| `audit_log`          | Mencatat setiap tindakan penting yang terjadi dalam sistem untuk tujuan keamanan, kepatuhan, dan pemecahan masalah.            |

## Tabel `users`

Tabel `users` menyimpan data dasar pengguna, termasuk kredensial dan status akun, serta informasi audit dasar.

| Kolom          | Tipe Data   | Keterangan                                                                      | Contoh Nilai                                  |
| :------------- | :---------- | :------------------------------------------------------------------------------ | :-------------------------------------------- |
| `userId`       | `uuid`      | Kunci utama, ID unik untuk setiap pengguna. Dihasilkan secara acak.             | `a1b2c3d4-e5f6-7890-1234-567890abcdef`        |
| `username`     | `varchar`   | Nama pengguna unik (maks 255 karakter). Tidak boleh null.                       | `john.doe`                                    |
| `email`        | `varchar`   | Alamat email unik pengguna (maks 255 karakter). Tidak boleh null.               | `john.doe@example.com`                        |
| `passwordHash` | `text`      | Hash kata sandi pengguna. Tidak boleh null.                                     | `$2a$10$abcdefghijklmnopqrstuvwxyz1234567890` |
| `isActive`     | `boolean`   | Menunjukkan apakah akun pengguna aktif. Default: `true`.                        | `true`                                        |
| `createdAt`    | `timestamp` | Waktu pembuatan catatan. Tidak boleh null. Default: waktu saat ini.             | `2023-01-01 10:00:00+07`                      |
| `createdBy`    | `uuid`      | ID pengguna yang membuat catatan ini. Referensi ke `users.userId`.              | `a1b2c3d4-e5f6-7890-1234-567890abcdef`        |
| `updatedAt`    | `timestamp` | Waktu terakhir catatan diperbarui. Tidak boleh null. Default: waktu saat ini.   | `2023-01-01 10:00:00+07`                      |
| `updatedBy`    | `uuid`      | ID pengguna yang terakhir memperbarui catatan ini. Referensi ke `users.userId`. | `a1b2c3d4-e5f6-7890-1234-567890abcdef`        |

**Indeks Unik:**

- `idx_users_username` pada kolom `username`
- `idx_users_email` pada kolom `email`

## Tabel `roles`

Tabel `roles` mendefinisikan peran-peran yang ada dalam sistem, mendukung hierarki peran melalui `parentRoleId`.

| Kolom          | Tipe Data   | Keterangan                                                                      | Contoh Nilai                              |
| :------------- | :---------- | :------------------------------------------------------------------------------ | :---------------------------------------- |
| `roleId`       | `uuid`      | Kunci utama, ID unik untuk setiap peran. Dihasilkan secara acak.                | `b1c2d3e4-f5a6-7890-1234-567890abcdef`    |
| `roleName`     | `varchar`   | Nama peran unik (maks 100 karakter). Tidak boleh null.                          | `admin`                                   |
| `description`  | `text`      | Deskripsi peran.                                                                | `Administrator sistem dengan akses penuh` |
| `parentRoleId` | `uuid`      | ID peran induk, jika ada. Referensi ke `roles.roleId`.                          | `null` (untuk peran tanpa induk)          |
| `createdAt`    | `timestamp` | Waktu pembuatan catatan. Tidak boleh null. Default: waktu saat ini.             | `2023-01-01 10:00:00+07`                  |
| `createdBy`    | `uuid`      | ID pengguna yang membuat catatan ini. Referensi ke `users.userId`.              | `a1b2c3d4-e5f6-7890-1234-567890abcdef`    |
| `updatedAt`    | `timestamp` | Waktu terakhir catatan diperbarui. Tidak boleh null. Default: waktu saat ini.   | `2023-01-01 10:00:00+07`                  |
| `updatedBy`    | `uuid`      | ID pengguna yang terakhir memperbarui catatan ini. Referensi ke `users.userId`. | `a1b2c3d4-e5f6-7890-1234-567890abcdef`    |

**Indeks:**

- `idx_roles_role_name` (unik) pada kolom `roleName`
- `idx_roles_parent_role_id` pada kolom `parentRoleId`

## Tabel `permissions`

Tabel `permissions` mencatat semua izin diskrit yang dapat diberikan dalam sistem.

| Kolom            | Tipe Data   | Keterangan                                                                      | Contoh Nilai                           |
| :--------------- | :---------- | :------------------------------------------------------------------------------ | :------------------------------------- |
| `permissionId`   | `uuid`      | Kunci utama, ID unik untuk setiap izin. Dihasilkan secara acak.                 | `c1d2e3f4-a5b6-7890-1234-567890abcdef` |
| `permissionName` | `varchar`   | Nama izin unik (maks 100 karakter). Tidak boleh null.                           | `user:create`                          |
| `description`    | `text`      | Deskripsi izin.                                                                 | `Izin untuk membuat pengguna baru`     |
| `createdAt`      | `timestamp` | Waktu pembuatan catatan. Tidak boleh null. Default: waktu saat ini.             | `2023-01-01 10:00:00+07`               |
| `createdBy`      | `uuid`      | ID pengguna yang membuat catatan ini. Referensi ke `users.userId`.              | `a1b2c3d4-e5f6-7890-1234-567890abcdef` |
| `updatedAt`      | `timestamp` | Waktu terakhir catatan diperbarui. Tidak boleh null. Default: waktu saat ini.   | `2023-01-01 10:00:00+07`               |
| `updatedBy`      | `uuid`      | ID pengguna yang terakhir memperbarui catatan ini. Referensi ke `users.userId`. | `a1b2c3d4-e5f6-7890-1234-567890abcdef` |

**Indeks Unik:**

- `idx_permissions_permission_name` pada kolom `permissionName`

## Tabel `user_roles`

Tabel `user_roles` menghubungkan pengguna dengan peran yang mereka miliki, memungkinkan satu pengguna memiliki banyak peran (many-to-many relationship).

| Kolom        | Tipe Data   | Keterangan                                                         | Contoh Nilai                           |
| :----------- | :---------- | :----------------------------------------------------------------- | :------------------------------------- |
| `userId`     | `uuid`      | ID pengguna. Tidak boleh null. Referensi ke `users.userId`.        | `a1b2c3d4-e5f6-7890-1234-567890abcdef` |
| `roleId`     | `uuid`      | ID peran. Tidak boleh null. Referensi ke `roles.roleId`.           | `b1c2d3e4-f5a6-7890-1234-567890abcdef` |
| `assignedAt` | `timestamp` | Waktu peran ditetapkan. Tidak boleh null. Default: waktu saat ini. | `2023-01-01 10:00:00+07`               |
| `assignedBy` | `uuid`      | ID pengguna yang menetapkan peran. Referensi ke `users.userId`.    | `a1b2c3d4-e5f6-7890-1234-567890abcdef` |

**Kunci Utama:**

- Komposit: `userId`, `roleId`

**Indeks:**

- `idx_user_roles_user_id` pada kolom `userId`
- `idx_user_roles_role_id` pada kolom `roleId`

## Tabel `role_permissions`

Tabel `role_permissions` menghubungkan peran dengan izin yang terkait dengannya, mendefinisikan izin apa yang dimiliki oleh setiap peran.

| Kolom          | Tipe Data   | Keterangan                                                                 | Contoh Nilai                           |
| :------------- | :---------- | :------------------------------------------------------------------------- | :------------------------------------- |
| `roleId`       | `uuid`      | ID peran. Tidak boleh null. Referensi ke `roles.roleId`.                   | `b1c2d3e4-f5a6-7890-1234-567890abcdef` |
| `permissionId` | `uuid`      | ID izin. Tidak boleh null. Referensi ke `permissions.permissionId`.        | `c1d2e3f4-a5b6-7890-1234-567890abcdef` |
| `assignedAt`   | `timestamp` | Waktu izin ditetapkan ke peran. Tidak boleh null. Default: waktu saat ini. | `2023-01-01 10:00:00+07`               |
| `assignedBy`   | `uuid`      | ID pengguna yang menetapkan izin. Referensi ke `users.userId`.             | `a1b2c3d4-e5f6-7890-1234-567890abcdef` |

**Kunci Utama:**

- Komposit: `roleId`, `permissionId`

**Indeks:**

- `idx_role_permissions_role_id` pada kolom `roleId`
- `idx_role_permissions_permission_id` pada kolom `permissionId`

## Tabel `object_types`

Tabel `object_types` mengkategorikan jenis-jenis objek dalam sistem yang dapat memiliki izin spesifik.

| Kolom          | Tipe Data | Keterangan                                                             | Contoh Nilai                           |
| :------------- | :-------- | :--------------------------------------------------------------------- | :------------------------------------- |
| `objectTypeId` | `uuid`    | Kunci utama, ID unik untuk setiap jenis objek. Dihasilkan secara acak. | `d1e2f3a4-b5c6-7890-1234-567890abcdef` |
| `typeName`     | `varchar` | Nama jenis objek unik (maks 100 karakter). Tidak boleh null.           | `document`                             |
| `description`  | `text`    | Deskripsi jenis objek.                                                 | `Dokumen dalam sistem`                 |

**Indeks Unik:**

- `idx_object_types_type_name` pada kolom `typeName`

## Tabel `object_permissions`

Tabel `object_permissions` mengelola izin yang diberikan pada objek individual, memungkinkan kontrol akses yang granular berdasarkan pengguna atau peran.

| Kolom                | Tipe Data   | Keterangan                                                                                      | Contoh Nilai                                       |
| :------------------- | :---------- | :---------------------------------------------------------------------------------------------- | :------------------------------------------------- |
| `objectPermissionId` | `uuid`      | Kunci utama, ID unik untuk setiap izin objek. Dihasilkan secara acak.                           | `e1f2a3b4-c5d6-7890-1234-567890abcdef`             |
| `userId`             | `uuid`      | ID pengguna yang memiliki izin ini. Referensi ke `users.userId`.                                | `a1b2c3d4-e5f6-7890-1234-567890abcdef`             |
| `roleId`             | `uuid`      | ID peran yang memiliki izin ini. Referensi ke `roles.roleId`.                                   | `null` (jika izin berlaku untuk pengguna langsung) |
| `objectTypeId`       | `uuid`      | ID jenis objek. Tidak boleh null. Referensi ke `object_types.objectTypeId`.                     | `d1e2f3a4-b5c6-7890-1234-567890abcdef`             |
| `objectId`           | `text`      | ID objek spesifik. Tidak boleh null.                                                            | `doc_12345`                                        |
| `permissionId`       | `uuid`      | ID izin yang diberikan. Tidak boleh null. Referensi ke `permissions.permissionId`.              | `c1d2e3f4-a5b6-7890-1234-567890abcdef`             |
| `grantedAt`          | `timestamp` | Waktu izin diberikan. Tidak boleh null. Default: waktu saat ini.                                | `2023-01-01 10:00:00+07`                           |
| `grantedBy`          | `uuid`      | ID pengguna yang memberikan izin. Referensi ke `users.userId`.                                  | `a1b2c3d4-e5f6-7890-1234-567890abcdef`             |
| `revokedAt`          | `timestamp` | Waktu izin dicabut.                                                                             | `null`                                             |
| `isActive`           | `boolean`   | Menunjukkan apakah izin aktif. Tidak boleh null. Default: `true`.                               | `true`                                             |
| `appliesTo`          | `varchar`   | Menunjukkan apakah izin berlaku untuk pengguna atau peran (maks 10 karakter). Tidak boleh null. | `user`                                             |

**Indeks:**

- `idx_obj_perm_user_id` pada kolom `userId`
- `idx_obj_perm_role_id` pada kolom `roleId`
- `idx_obj_perm_object_type_id` pada kolom `objectTypeId`
- `idx_obj_perm_object_id` pada kolom `objectId`
- `idx_obj_perm_permission_id` pada kolom `permissionId`

## Tabel `audit_log`

Tabel `audit_log` mencatat setiap tindakan penting yang terjadi dalam sistem untuk tujuan keamanan, kepatuhan, dan pemecahan masalah.

| Kolom        | Tipe Data   | Keterangan                                                           | Contoh Nilai                                |
| :----------- | :---------- | :------------------------------------------------------------------- | :------------------------------------------ |
| `logId`      | `uuid`      | Kunci utama, ID unik untuk setiap entri log. Dihasilkan secara acak. | `f1a2b3c4-d5e6-7890-1234-567890abcdef`      |
| `userId`     | `uuid`      | ID pengguna yang melakukan tindakan. Referensi ke `users.userId`.    | `a1b2c3d4-e5f6-7890-1234-567890abcdef`      |
| `actionType` | `varchar`   | Jenis tindakan yang dilakukan (maks 100 karakter). Tidak boleh null. | `user_login`                                |
| `tableName`  | `varchar`   | Nama tabel yang terpengaruh oleh tindakan (maks 100 karakter).       | `users`                                     |
| `recordId`   | `text`      | ID catatan yang terpengaruh.                                         | `a1b2c3d4-e5f6-7890-1234-567890abcdef`      |
| `oldValue`   | `jsonb`     | Nilai lama catatan sebelum perubahan.                                | `{"isActive": true}`                        |
| `newValue`   | `jsonb`     | Nilai baru catatan setelah perubahan.                                | `{"isActive": false}`                       |
| `timestamp`  | `timestamp` | Waktu tindakan terjadi. Tidak boleh null. Default: waktu saat ini.   | `2023-01-01 10:00:00+07`                    |
| `ipAddress`  | `text`      | Alamat IP dari mana tindakan berasal.                                | `192.168.1.100`                             |
| `userAgent`  | `text`      | User agent dari klien yang melakukan tindakan.                       | `Mozilla/5.0 (Windows NT 10.0; Win64; x64)` |

**Indeks:**

- `idx_audit_log_user_id` pada kolom `userId`
- `idx_audit_log_action_type` pada kolom `actionType`
- `idx_audit_log_timestamp` pada kolom `timestamp`
