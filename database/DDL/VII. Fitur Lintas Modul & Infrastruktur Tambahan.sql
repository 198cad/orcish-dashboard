-- Notifikasi & Alerts
CREATE TABLE Notifications (
    notification_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES Users(user_id), -- Pengguna yang akan menerima notifikasi
    message TEXT NOT NULL, -- Isi pesan notifikasi
    notification_type VARCHAR(50), -- Tipe notifikasi (misalnya 'Stock Alert', 'Approval Required', 'Payment Overdue')
    link TEXT, -- URL dalam aplikasi untuk navigasi cepat
    is_read BOOLEAN DEFAULT FALSE, -- Status notifikasi (sudah dibaca/belum)
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE Notifications IS 'Menyimpan notifikasi dan peringatan untuk pengguna.';
CREATE INDEX idx_notifications_user_id ON Notifications(user_id);

-- Manajemen Dokumen (Attachment)
CREATE TABLE Attachments (
    attachment_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    file_name VARCHAR(255) NOT NULL, -- Nama file asli
    file_path TEXT NOT NULL, -- Path atau URL ke lokasi penyimpanan file (misalnya S3, GCS, atau lokal)
    file_type VARCHAR(50), -- Tipe MIME file (misalnya 'application/pdf', 'image/jpeg')
    file_size_bytes BIGINT, -- Ukuran file dalam byte
    related_document_type VARCHAR(50), -- Tipe dokumen yang terkait (misalnya 'PurchaseInvoice', 'SalesOrder')
    related_document_id UUID, -- ID dokumen yang terkait
    uploaded_by UUID REFERENCES Users(user_id), -- Pengguna yang mengunggah
    uploaded_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE Attachments IS 'Menyimpan metadata untuk lampiran dokumen digital.';
CREATE INDEX idx_attachments_related_doc ON Attachments(related_document_type, related_document_id);

-- Pengaturan Sistem (General System Settings)
CREATE TABLE SystemSettings (
    setting_key VARCHAR(100) PRIMARY KEY, -- Kunci pengaturan (misalnya 'company_name', 'default_currency')
    setting_value TEXT NOT NULL, -- Nilai pengaturan
    description TEXT, -- Deskripsi pengaturan
    last_updated_by UUID REFERENCES Users(user_id),
    last_updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE SystemSettings IS 'Menyimpan pengaturan konfigurasi umum sistem.';

-- Manajemen Tugas Harian Terpandu
CREATE TABLE Tasks (
    task_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(255) NOT NULL, -- Judul tugas
    description TEXT, -- Deskripsi tugas
    assignee_id UUID REFERENCES Users(user_id), -- Pengguna yang ditugaskan
    creator_id UUID NOT NULL REFERENCES Users(user_id), -- Pengguna yang membuat tugas
    due_date DATE, -- Tanggal jatuh tempo
    priority VARCHAR(20) DEFAULT 'Medium' CHECK (priority IN ('High', 'Medium', 'Low')), -- Prioritas tugas
    status VARCHAR(50) NOT NULL DEFAULT 'Pending' CHECK (status IN ('Pending', 'In Progress', 'Completed', 'Cancelled')), -- Status tugas
    related_document_type VARCHAR(50), -- Tipe dokumen terkait (opsional)
    related_document_id UUID, -- ID dokumen terkait (opsional)
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE Tasks IS 'Tabel untuk manajemen tugas harian.';
CREATE INDEX idx_tasks_assignee_id ON Tasks(assignee_id);
CREATE INDEX idx_tasks_related_doc ON Tasks(related_document_type, related_document_id);

-- Gamifikasi
CREATE TABLE GamificationRewards (
    reward_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    reward_name VARCHAR(100) UNIQUE NOT NULL, -- Nama reward (misalnya 'First PO Created', 'Sales Champion')
    description TEXT,
    points_awarded INT NOT NULL CHECK (points_awarded >= 0), -- Poin yang diberikan
    badge_image_url TEXT -- URL gambar badge
);
COMMENT ON TABLE GamificationRewards IS 'Master data untuk definisi reward gamifikasi.';

CREATE TABLE UserAchievements (
    achievement_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES Users(user_id) ON DELETE CASCADE, -- Foreign Key ke Users
    reward_id UUID NOT NULL REFERENCES GamificationRewards(reward_id) ON DELETE CASCADE, -- Foreign Key ke GamificationRewards
    achievement_date DATE NOT NULL DEFAULT CURRENT_DATE, -- Tanggal pencapaian
    earned_points INT NOT NULL, -- Poin yang didapatkan dari pencapaian ini
    UNIQUE (user_id, reward_id, achievement_date) -- Untuk mencegah duplikasi reward pada hari yang sama
);
COMMENT ON TABLE UserAchievements IS 'Mencatat pencapaian gamifikasi pengguna.';
CREATE INDEX idx_user_achievements_user_id ON UserAchievements(user_id);

-- Manajemen Keuangan Karyawan Terintegrasi
CREATE TABLE Employees (
    employee_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES Users(user_id) UNIQUE, -- Foreign Key ke Users (jika karyawan memiliki akun login)
    employee_code VARCHAR(50) UNIQUE NOT NULL, -- Kode karyawan
    full_name VARCHAR(150) NOT NULL, -- Nama lengkap karyawan
    job_title VARCHAR(100), -- Jabatan
    department VARCHAR(100), -- Departemen
    hire_date DATE, -- Tanggal mulai bekerja
    salary NUMERIC(19, 4), -- Gaji pokok
    is_active BOOLEAN DEFAULT TRUE,
    contact_email VARCHAR(100),
    contact_phone VARCHAR(50),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE Employees IS 'Master data untuk informasi karyawan.';

CREATE TABLE Payrolls (
    payroll_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    employee_id UUID NOT NULL REFERENCES Employees(employee_id) ON DELETE CASCADE, -- Foreign Key ke Employees
    payroll_period_start DATE NOT NULL, -- Tanggal mulai periode penggajian
    payroll_period_end DATE NOT NULL, -- Tanggal akhir periode penggajian
    gross_salary NUMERIC(19, 4) NOT NULL CHECK (gross_salary >= 0), -- Gaji kotor
    deductions NUMERIC(19, 4) DEFAULT 0 CHECK (deductions >= 0), -- Potongan
    net_salary NUMERIC(19, 4) GENERATED ALWAYS AS (gross_salary - deductions) STORED, -- Gaji bersih
    payroll_date DATE NOT NULL DEFAULT CURRENT_DATE, -- Tanggal penggajian diproses
    status VARCHAR(50) NOT NULL DEFAULT 'Processed', -- Status penggajian (e.g., 'Processed', 'Paid')
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE Payrolls IS 'Tabel untuk mencatat data penggajian karyawan.';
CREATE UNIQUE INDEX idx_payrolls_employee_period ON Payrolls(employee_id, payroll_period_start, payroll_period_end);

CREATE TABLE EmployeeLoans (
    loan_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    employee_id UUID NOT NULL REFERENCES Employees(employee_id) ON DELETE CASCADE, -- Foreign Key ke Employees
    loan_date DATE NOT NULL DEFAULT CURRENT_DATE, -- Tanggal pinjaman diberikan
    loan_amount NUMERIC(19, 4) NOT NULL CHECK (loan_amount > 0), -- Jumlah pinjaman
    remaining_balance NUMERIC(19, 4) NOT NULL, -- Sisa saldo pinjaman
    interest_rate NUMERIC(5, 2) DEFAULT 0 CHECK (interest_rate >= 0), -- Tingkat bunga
    repayment_start_date DATE, -- Tanggal mulai pembayaran kembali
    status VARCHAR(50) NOT NULL DEFAULT 'Active' CHECK (status IN ('Active', 'Paid Off', 'Default')), -- Status pinjaman
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE EmployeeLoans IS 'Tabel untuk mencatat pinjaman karyawan.';

CREATE TABLE EmployeeLoanRepayments (
    repayment_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    loan_id UUID NOT NULL REFERENCES EmployeeLoans(loan_id) ON DELETE CASCADE, -- Foreign Key ke EmployeeLoans
    repayment_date DATE NOT NULL DEFAULT CURRENT_DATE, -- Tanggal pembayaran kembali
    amount_paid NUMERIC(19, 4) NOT NULL CHECK (amount_paid > 0), -- Jumlah yang dibayar
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE EmployeeLoanRepayments IS 'Tabel untuk mencatat pembayaran kembali pinjaman karyawan.';
CREATE INDEX idx_employee_loan_repayments_loan_id ON EmployeeLoanRepayments(loan_id);

-- Otomatisasi Cerdas Berbasis LLM (untuk logging dan manajemen interaksi)
CREATE TABLE LLMRequests (
    request_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES Users(user_id), -- Pengguna yang memicu request LLM
    request_timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP, -- Waktu request
    prompt_text TEXT NOT NULL, -- Teks prompt yang dikirim ke LLM
    llm_response TEXT, -- Respon dari LLM
    model_used VARCHAR(100), -- Model LLM yang digunakan
    temperature NUMERIC(5, 2), -- Parameter suhu LLM
    max_tokens INT, -- Maksimum token yang diminta
    usage_tokens INT, -- Jumlah token yang digunakan
    cost NUMERIC(10, 4), -- Perkiraan biaya (jika ada)
    feedback_rating INT CHECK (feedback_rating >= 1 AND feedback_rating <= 5), -- Rating feedback dari pengguna (1-5)
    human_validated BOOLEAN DEFAULT FALSE, -- Apakah output sudah divalidasi manusia
    validation_by UUID REFERENCES Users(user_id), -- Pengguna yang melakukan validasi
    validation_at TIMESTAMP WITH TIME ZONE, -- Waktu validasi
    error_message TEXT, -- Pesan error jika ada
    related_document_type VARCHAR(50), -- Tipe dokumen yang relevan dengan request
    related_document_id UUID -- ID dokumen yang relevan
);
COMMENT ON TABLE LLMRequests IS 'Mencatat setiap interaksi dengan Large Language Models (LLM) untuk audit dan analisis.';
CREATE INDEX idx_llm_requests_user_id ON LLMRequests(user_id);
CREATE INDEX idx_llm_requests_timestamp ON LLMRequests(request_timestamp);