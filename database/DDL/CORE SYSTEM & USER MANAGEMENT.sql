-- DDL KHUSUS UNTUK KELOMPOK CORE SYSTEM & USER MANAGEMENT (PostgreSQL)

-- Ekstensi yang mungkin dibutuhkan:
-- Pastikan ekstensi ini terinstal di database Anda.
CREATE EXTENSION IF NOT EXISTS "uuid-ossp"; -- Jika Anda ingin menggunakan uuid_generate_v4()
CREATE EXTENSION IF NOT EXISTS "pgcrypto"; -- Untuk gen_random_uuid() (direkomendasikan)


-- Tabel Dasar & Master Data Fondasi Sistem

-- 1. Users
CREATE TABLE Users (
    user_id UUID PRIMARY KEY DEFAULT gen_random_uuid(), -- ID unik pengguna
    username VARCHAR(50) UNIQUE NOT NULL, -- Nama pengguna, harus unik. Cukup 50 karakter untuk sebagian besar kasus.
    password_hash TEXT NOT NULL, -- Hash kata sandi (penting: gunakan algoritma kuat seperti bcrypt/argon2). TEXT fleksibel.
    email VARCHAR(255) UNIQUE NOT NULL, -- Alamat email, harus unik. Diperpanjang hingga 255 untuk standar email.
    full_name VARCHAR(150), -- Nama lengkap pengguna
    phone_number VARCHAR(50), -- Ditambahkan: Nomor telepon untuk MFA atau kontak.
    is_active BOOLEAN DEFAULT TRUE, -- Status aktif/non-aktif pengguna
    last_login_at TIMESTAMP WITH TIME ZONE, -- Ditambahkan: Waktu terakhir pengguna login.
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP, -- Waktu pembuatan record
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP -- Waktu terakhir update record
);
COMMENT ON TABLE Users IS 'Tabel untuk menyimpan informasi dasar pengguna sistem.';
COMMENT ON COLUMN Users.password_hash IS 'Hash kata sandi pengguna menggunakan algoritma yang kuat (misalnya bcrypt).';
COMMENT ON COLUMN Users.last_login_at IS 'Waktu terakhir pengguna berhasil login.';

-- 2. Roles
CREATE TABLE Roles (
    role_id UUID PRIMARY KEY DEFAULT gen_random_uuid(), -- ID unik peran
    role_name VARCHAR(50) UNIQUE NOT NULL, -- Nama peran (misalnya 'Admin', 'Sales Manager')
    description TEXT, -- Deskripsi peran
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP, -- Ditambahkan: Untuk audit master data
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP -- Ditambahkan: Untuk audit master data
);
COMMENT ON TABLE Roles IS 'Tabel untuk mendefinisikan peran pengguna dalam sistem (RBAC).';

-- 3. Permissions
CREATE TABLE Permissions (
    permission_id UUID PRIMARY KEY DEFAULT gen_random_uuid(), -- ID unik izin
    permission_name VARCHAR(100) UNIQUE NOT NULL, -- Nama izin (misalnya 'item_create', 'sales_order_view_all')
    description TEXT, -- Deskripsi izin
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP, -- Ditambahkan: Untuk audit master data
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP -- Ditambahkan: Untuk audit master data
);
COMMENT ON TABLE Permissions IS 'Tabel untuk mendefinisikan hak akses granular.';


-- Tabel Level 1 (bergantung pada tabel dasar)

-- 4. UserRoles (Junction Table)
CREATE TABLE UserRoles (
    user_id UUID NOT NULL REFERENCES Users(user_id) ON DELETE CASCADE, -- Foreign Key ke Users, hapus jika user dihapus
    role_id UUID NOT NULL REFERENCES Roles(role_id) ON DELETE CASCADE, -- Foreign Key ke Roles, hapus jika role dihapus
    PRIMARY KEY (user_id, role_id) -- Kombinasi unik user dan role
);
COMMENT ON TABLE UserRoles IS 'Tabel relasi many-to-many antara pengguna dan peran.';
-- Indeks tidak diperlukan pada kolom individual PRIMARY KEY karena sudah diindeks secara otomatis.

-- 5. RolePermissions (Junction Table)
CREATE TABLE RolePermissions (
    role_id UUID NOT NULL REFERENCES Roles(role_id) ON DELETE CASCADE, -- Foreign Key ke Roles
    permission_id UUID NOT NULL REFERENCES Permissions(permission_id) ON DELETE CASCADE, -- Foreign Key ke Permissions
    PRIMARY KEY (role_id, permission_id) -- Kombinasi unik role dan permission
);
COMMENT ON TABLE RolePermissions IS 'Tabel relasi many-to-many antara peran dan izin.';
-- Indeks tidak diperlukan pada kolom individual PRIMARY KEY karena sudah diindeks secara otomatis.


-- 6. AuditLogs
CREATE TABLE AuditLogs (
    log_id BIGSERIAL PRIMARY KEY, -- ID auto-increment untuk log, menggunakan BIGSERIAL untuk kapasitas besar
    user_id UUID REFERENCES Users(user_id), -- Foreign Key ke Users (bisa NULL jika tindakan sistem)
    action_type VARCHAR(50) NOT NULL, -- Tipe aksi (misalnya 'CREATE_USER', 'UPDATE_SALES_ORDER', 'LOGIN')
    table_name VARCHAR(100), -- Nama tabel yang terpengaruh
    record_id UUID, -- Diubah: Jika semua PK tabel lain adalah UUID, gunakan UUID. Jika beragam, kembali ke TEXT.
    old_data JSONB, -- Data sebelum perubahan (JSONB untuk penyimpanan JSON yang efisien)
    new_data JSONB, -- Data setelah perubahan (JSONB)
    ip_address INET, -- Alamat IP pengguna
    user_agent TEXT, -- Informasi browser/aplikasi pengguna
    additional_info JSONB, -- Ditambahkan: Untuk detail kontekstual tambahan yang fleksibel
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP -- Waktu kejadian log
);
COMMENT ON TABLE AuditLogs IS 'Mencatat setiap aktivitas pengguna dan perubahan sistem.';
COMMENT ON COLUMN AuditLogs.record_id IS 'ID dari record yang terpengaruh. Asumsi UUID jika semua PK lain adalah UUID.';
COMMENT ON COLUMN AuditLogs.additional_info IS 'Informasi tambahan dalam format JSON tentang event log.';
CREATE INDEX idx_auditlogs_user_id ON AuditLogs(user_id);
CREATE INDEX idx_auditlogs_timestamp ON AuditLogs(timestamp DESC); -- Dioptimalkan untuk query log terbaru
CREATE INDEX idx_auditlogs_table_record ON AuditLogs(table_name, record_id);
CREATE INDEX idx_auditlogs_action_type ON AuditLogs(action_type); -- Ditambahkan: Berguna untuk mencari jenis aksi spesifik

-- 7. DocumentVersions
CREATE TABLE DocumentVersions (
    version_id BIGSERIAL PRIMARY KEY, -- ID auto-increment untuk versi dokumen
    document_type VARCHAR(50) NOT NULL, -- Tipe dokumen (misalnya 'SalesOrder', 'PurchaseInvoice')
    document_id UUID NOT NULL, -- ID dokumen asli
    version_number INT NOT NULL, -- Nomor versi dokumen
    changes JSONB, -- Detail perubahan antara versi ini dan sebelumnya
    full_document_snapshot JSONB, -- Ditambahkan: Opsional, snapshot lengkap dokumen pada versi ini (pertimbangkan ukuran DB).
    changed_by UUID REFERENCES Users(user_id), -- Siapa yang melakukan perubahan
    changed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP, -- Waktu perubahan
    UNIQUE (document_type, document_id, version_number) -- Memastikan versi unik per dokumen
);
COMMENT ON TABLE DocumentVersions IS 'Melacak riwayat perubahan untuk dokumen penting.';
COMMENT ON COLUMN DocumentVersions.full_document_snapshot IS 'Snapshot lengkap dokumen pada versi ini (opsional, dapat berdampak pada ukuran database).';
CREATE INDEX idx_docversions_document_id ON DocumentVersions(document_id);
CREATE INDEX idx_docversions_document_type ON DocumentVersions(document_type); -- Ditambahkan: Berguna untuk mencari semua versi dari tipe dokumen tertentu

-- 8. Notifications
CREATE TABLE Notifications (
    notification_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES Users(user_id) ON DELETE CASCADE, -- Pengguna yang akan menerima notifikasi
    message TEXT NOT NULL, -- Isi pesan notifikasi
    notification_type VARCHAR(50), -- Tipe notifikasi (misalnya 'Stock Alert', 'Approval Required', 'Payment Overdue')
    link TEXT, -- URL dalam aplikasi untuk navigasi cepat
    is_read BOOLEAN DEFAULT FALSE, -- Status notifikasi (sudah dibaca/belum)
    priority VARCHAR(20) DEFAULT 'Normal' CHECK (priority IN ('High', 'Medium', 'Low', 'Critical')), -- Ditambahkan: Prioritas notifikasi
    valid_until TIMESTAMP WITH TIME ZONE, -- Ditambahkan: Kapan notifikasi ini tidak lagi relevan (opsional)
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE Notifications IS 'Menyimpan notifikasi dan peringatan untuk pengguna.';
CREATE INDEX idx_notifications_user_id ON Notifications(user_id);
CREATE INDEX idx_notifications_is_read ON Notifications(is_read); -- Ditambahkan: Untuk mencari notifikasi yang belum dibaca
CREATE INDEX idx_notifications_type ON Notifications(notification_type); -- Ditambahkan: Untuk filtering berdasarkan tipe

-- 9. SystemSettings
CREATE TABLE SystemSettings (
    setting_key VARCHAR(100) PRIMARY KEY, -- Kunci pengaturan (misalnya 'company_name', 'default_currency')
    setting_value TEXT NOT NULL, -- Nilai pengaturan (gunakan TEXT untuk fleksibilitas)
    description TEXT, -- Deskripsi pengaturan
    value_type VARCHAR(50) DEFAULT 'text', -- Ditambahkan: Menunjukkan tipe data nilai sebenarnya (e.g., 'text', 'number', 'boolean', 'json')
    is_sensitive BOOLEAN DEFAULT FALSE, -- Ditambahkan: Menandai pengaturan sensitif (misalnya API keys)
    last_updated_by UUID REFERENCES Users(user_id),
    last_updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE SystemSettings IS 'Menyimpan pengaturan konfigurasi umum sistem.';
COMMENT ON COLUMN SystemSettings.setting_value IS 'Nilai pengaturan. Parsing ke tipe data yang benar dilakukan di aplikasi.';
COMMENT ON COLUMN SystemSettings.value_type IS 'Menunjukkan tipe data semantik dari setting_value (misalnya, "string", "integer", "boolean", "json").';

-- 10. Tasks
CREATE TABLE Tasks (
    task_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(255) NOT NULL, -- Judul tugas
    description TEXT, -- Deskripsi tugas
    assignee_id UUID REFERENCES Users(user_id), -- Pengguna yang ditugaskan
    creator_id UUID NOT NULL REFERENCES Users(user_id), -- Pengguna yang membuat tugas
    due_date DATE, -- Tanggal jatuh tempo
    completed_at TIMESTAMP WITH TIME ZONE, -- Ditambahkan: Waktu tugas selesai
    priority VARCHAR(20) DEFAULT 'Medium' CHECK (priority IN ('High', 'Medium', 'Low')), -- Prioritas tugas
    status VARCHAR(50) NOT NULL DEFAULT 'Pending' CHECK (status IN ('Pending', 'In Progress', 'Completed', 'Cancelled')), -- Status tugas
    related_document_type VARCHAR(50), -- Tipe dokumen terkait (opsional)
    related_document_id UUID, -- ID dokumen terkait (opsional)
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE Tasks IS 'Tabel untuk manajemen tugas harian.';
COMMENT ON COLUMN Tasks.completed_at IS 'Waktu tugas ditandai sebagai selesai.';
CREATE INDEX idx_tasks_assignee_id ON Tasks(assignee_id);
CREATE INDEX idx_tasks_creator_id ON Tasks(creator_id); -- Ditambahkan: Berguna untuk mencari tugas yang dibuat oleh user
CREATE INDEX idx_tasks_related_doc ON Tasks(related_document_type, related_document_id);
CREATE INDEX idx_tasks_status_due_date ON Tasks(status, due_date); -- Ditambahkan: Untuk mencari tugas yang belum selesai atau jatuh tempo

-- 11. Employees
-- Diasumsikan Departments adalah tabel master terpisah jika diperlukan skalabilitas yang besar,
-- namun untuk konteks ini, department bisa tetap sebagai VARCHAR.
CREATE TABLE Employees (
    employee_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID UNIQUE REFERENCES Users(user_id) ON DELETE SET NULL, -- Foreign Key ke Users (jika karyawan memiliki akun login). Diubah: SET NULL jika user dihapus.
    employee_code VARCHAR(50) UNIQUE NOT NULL, -- Kode karyawan
    full_name VARCHAR(150) NOT NULL, -- Nama lengkap karyawan
    job_title VARCHAR(100), -- Jabatan
    department VARCHAR(100), -- Departemen (pertimbangkan tabel master terpisah untuk skalabilitas)
    hire_date DATE, -- Tanggal mulai bekerja
    termination_date DATE, -- Ditambahkan: Tanggal berhenti bekerja (jika tidak aktif)
    salary NUMERIC(19, 4), -- Gaji pokok (pertimbangkan enkripsi di level aplikasi untuk data sensitif)
    is_active BOOLEAN DEFAULT TRUE,
    contact_email VARCHAR(100),
    contact_phone VARCHAR(50),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE Employees IS 'Master data untuk informasi karyawan.';
COMMENT ON COLUMN Employees.user_id IS 'Opsional, user_id jika karyawan juga memiliki akun sistem. SET NULL jika user dihapus.';
COMMENT ON COLUMN Employees.termination_date IS 'Tanggal karyawan berhenti bekerja, jika is_active FALSE.';
CREATE INDEX idx_employees_code ON Employees(employee_code);
CREATE INDEX idx_employees_name ON Employees(full_name);
CREATE INDEX idx_employees_department ON Employees(department); -- Ditambahkan: Untuk mencari karyawan berdasarkan departemen

-- 12. GamificationRewards
CREATE TABLE GamificationRewards (
    reward_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    reward_name VARCHAR(100) UNIQUE NOT NULL, -- Nama reward (misalnya 'First PO Created', 'Sales Champion')
    description TEXT,
    points_awarded INT NOT NULL CHECK (points_awarded >= 0), -- Poin yang diberikan
    badge_image_url TEXT, -- URL gambar badge
    is_active BOOLEAN DEFAULT TRUE, -- Ditambahkan: Status aktif reward
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP, -- Ditambahkan: Untuk audit master data
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP -- Ditambahkan: Untuk audit master data
);
COMMENT ON TABLE GamificationRewards IS 'Master data untuk definisi reward gamifikasi.';

-- 13. UserAchievements
CREATE TABLE UserAchievements (
    achievement_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES Users(user_id) ON DELETE CASCADE, -- Foreign Key ke Users
    reward_id UUID NOT NULL REFERENCES GamificationRewards(reward_id) ON DELETE CASCADE, -- Foreign Key ke GamificationRewards
    achievement_date TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP, -- Diubah: Lebih granular dengan TIMESTAMP
    earned_points INT NOT NULL, -- Poin yang didapatkan dari pencapaian ini
    notes TEXT, -- Ditambahkan: Catatan tambahan tentang pencapaian
    UNIQUE (user_id, reward_id, achievement_date) -- Untuk mencegah duplikasi reward pada waktu yang persis sama
);
COMMENT ON TABLE UserAchievements IS 'Mencatat pencapaian gamifikasi pengguna.';
COMMENT ON COLUMN UserAchievements.achievement_date IS 'Waktu spesifik pencapaian didapatkan.';
CREATE INDEX idx_user_achievements_user_id ON UserAchievements(user_id);
CREATE INDEX idx_user_achievements_reward_id ON UserAchievements(reward_id); -- Ditambahkan: Untuk melihat siapa saja yang mendapatkan reward tertentu


-- 14. ReportConfigurations
CREATE TABLE ReportConfigurations (
    report_config_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES Users(user_id) ON DELETE CASCADE, -- Pengguna yang membuat konfigurasi laporan
    report_name VARCHAR(100) NOT NULL, -- Nama laporan kustom
    description TEXT,
    base_table VARCHAR(100) NOT NULL, -- Tabel dasar untuk laporan (misalnya 'SalesInvoices', 'Items')
    columns_selected JSONB, -- Array dari nama kolom yang akan ditampilkan (JSONB)
    filters JSONB, -- Objek JSON berisi kondisi filter (JSONB)
    sorting_order JSONB, -- Objek JSON berisi field dan arah pengurutan (JSONB)
    grouping_fields JSONB, -- Array dari field untuk pengelompokan (JSONB)
    is_public BOOLEAN DEFAULT FALSE, -- Apakah laporan bisa dilihat oleh pengguna lain
    shared_with JSONB, -- Ditambahkan: Array UUID user_id atau role_id yang dibagikan (opsional)
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE ReportConfigurations IS 'Menyimpan konfigurasi laporan kustom yang dibuat oleh pengguna.';
COMMENT ON COLUMN ReportConfigurations.shared_with IS 'Daftar user_id atau role_id (sebagai JSONB array) yang dapat melihat laporan publik.';
CREATE INDEX idx_report_configs_user_id ON ReportConfigurations(user_id);
CREATE INDEX idx_report_configs_name ON ReportConfigurations(report_name); -- Ditambahkan: Untuk pencarian laporan
CREATE INDEX idx_report_configs_public ON ReportConfigurations(is_public); -- Ditambahkan: Untuk mencari laporan publik


-- 15. LLMRequests
CREATE TABLE LLMRequests (
    request_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES Users(user_id) ON DELETE SET NULL, -- Pengguna yang memicu request LLM. Diubah: SET NULL jika user dihapus.
    request_timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP, -- Waktu request
    prompt_text TEXT NOT NULL, -- Teks prompt yang dikirim ke LLM
    llm_response TEXT, -- Respon dari LLM
    model_used VARCHAR(100), -- Model LLM yang digunakan
    temperature NUMERIC(5, 2), -- Parameter suhu LLM
    max_tokens INT, -- Maksimum token yang diminta
    usage_tokens INT, -- Jumlah token yang digunakan
    cost NUMERIC(10, 6), -- Diperpanjang: Presisi biaya mungkin lebih tinggi.
    response_latency_ms INT, -- Ditambahkan: Latensi respons LLM
    feedback_rating INT CHECK (feedback_rating >= 1 AND feedback_rating <= 5), -- Rating feedback dari pengguna (1-5)
    human_validated BOOLEAN DEFAULT FALSE, -- Apakah output sudah divalidasi manusia
    validation_by UUID REFERENCES Users(user_id), -- Pengguna yang melakukan validasi
    validation_at TIMESTAMP WITH TIME ZONE, -- Waktu validasi
    error_message TEXT, -- Pesan error jika ada
    related_document_type VARCHAR(50), -- Tipe dokumen yang relevan dengan request
    related_document_id UUID, -- ID dokumen yang relevan
    UNIQUE (request_id, request_timestamp) -- Ditambahkan: Untuk memastikan unik jika ada duplikasi UUID (walau jarang)
);
COMMENT ON TABLE LLMRequests IS 'Mencatat setiap interaksi dengan Large Language Models (LLM) untuk audit dan analisis.';
COMMENT ON COLUMN LLMRequests.cost IS 'Perkiraan biaya interaksi LLM (misalnya dalam USD), dengan presisi lebih tinggi.';
COMMENT ON COLUMN LLMRequests.response_latency_ms IS 'Waktu yang dibutuhkan LLM untuk merespons, dalam milidetik.';
CREATE INDEX idx_llm_requests_user_id ON LLMRequests(user_id);
CREATE INDEX idx_llm_requests_timestamp ON LLMRequests(request_timestamp DESC); -- Dioptimalkan untuk mencari request terbaru
CREATE INDEX idx_llm_requests_model_used ON LLMRequests(model_used); -- Ditambahkan: Untuk analisis penggunaan model
CREATE INDEX idx_llm_requests_feedback ON LLMRequests(feedback_rating, human_validated); -- Ditambahkan: Untuk analisis kualitas LLM