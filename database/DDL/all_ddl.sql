-- Skema: public (default)
-- Ekstensi yang mungkin dibutuhkan:
-- CREATE EXTENSION IF NOT EXISTS "uuid-ossp"; -- Jika Anda ingin menggunakan uuid_generate_v4()
-- CREATE EXTENSION IF NOT EXISTS "pgcrypto"; -- Untuk gen_random_uuid()

-- Tabel Dasar & Master Data Fondasi Sistem
CREATE TABLE Users (
    user_id UUID PRIMARY KEY DEFAULT gen_random_uuid(), -- ID unik pengguna, menggunakan UUID
    username VARCHAR(50) UNIQUE NOT NULL, -- Nama pengguna, harus unik
    password_hash TEXT NOT NULL, -- Hash kata sandi (penting: jangan simpan plain text)
    email VARCHAR(100) UNIQUE NOT NULL, -- Alamat email, harus unik
    full_name VARCHAR(150), -- Nama lengkap pengguna
    is_active BOOLEAN DEFAULT TRUE, -- Status aktif/non-aktif pengguna
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP, -- Waktu pembuatan record
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP -- Waktu terakhir update record
);
COMMENT ON TABLE Users IS 'Tabel untuk menyimpan informasi dasar pengguna sistem.';
COMMENT ON COLUMN Users.password_hash IS 'Hash kata sandi pengguna menggunakan algoritma yang kuat (misalnya bcrypt).';

CREATE TABLE Roles (
    role_id UUID PRIMARY KEY DEFAULT gen_random_uuid(), -- ID unik peran
    role_name VARCHAR(50) UNIQUE NOT NULL, -- Nama peran (misalnya 'Admin', 'Sales Manager')
    description TEXT -- Deskripsi peran
);
COMMENT ON TABLE Roles IS 'Tabel untuk mendefinisikan peran pengguna dalam sistem (RBAC).';

CREATE TABLE Permissions (
    permission_id UUID PRIMARY KEY DEFAULT gen_random_uuid(), -- ID unik izin
    permission_name VARCHAR(100) UNIQUE NOT NULL, -- Nama izin (misalnya 'item_create', 'sales_order_view_all')
    description TEXT -- Deskripsi izin
);
COMMENT ON TABLE Permissions IS 'Tabel untuk mendefinisikan hak akses granular.';

CREATE TABLE UnitsOfMeasure (
    uom_id UUID PRIMARY KEY DEFAULT gen_random_uuid(), -- ID unik satuan pengukuran
    uom_name VARCHAR(50) UNIQUE NOT NULL, -- Nama satuan (misalnya 'Pcs', 'Kg', 'Liter')
    base_conversion_factor NUMERIC(10, 4) NOT NULL DEFAULT 1 -- Faktor konversi ke UoM dasar (jika ada)
);
COMMENT ON TABLE UnitsOfMeasure IS 'Master data untuk satuan pengukuran barang.';

CREATE TABLE ItemGroups (
    item_group_id UUID PRIMARY KEY DEFAULT gen_random_uuid(), -- ID unik grup barang
    group_name VARCHAR(100) UNIQUE NOT NULL, -- Nama grup barang
    description TEXT -- Deskripsi grup
);
COMMENT ON TABLE ItemGroups IS 'Master data untuk kategori atau grup barang.';

CREATE TABLE PaymentTerms (
    payment_term_id UUID PRIMARY KEY DEFAULT gen_random_uuid(), -- ID unik term pembayaran
    term_name VARCHAR(50) UNIQUE NOT NULL, -- Nama term (misalnya 'Net 30', 'Cash on Delivery')
    days_due INT NOT NULL CHECK (days_due >= 0), -- Jumlah hari jatuh tempo
    description TEXT -- Deskripsi term pembayaran
);
COMMENT ON TABLE PaymentTerms IS 'Master data untuk syarat pembayaran.';

CREATE TABLE CustomerGroups (
    customer_group_id UUID PRIMARY KEY DEFAULT gen_random_uuid(), -- ID unik grup pelanggan
    group_name VARCHAR(100) UNIQUE NOT NULL, -- Nama grup pelanggan
    description TEXT -- Deskripsi grup
);
COMMENT ON TABLE CustomerGroups IS 'Master data untuk kategori atau grup pelanggan.';

CREATE TABLE Currencies (
    currency_id UUID PRIMARY KEY DEFAULT gen_random_uuid(), -- ID unik mata uang
    currency_code VARCHAR(3) UNIQUE NOT NULL, -- Kode mata uang (misalnya 'USD', 'JPY', 'IDR')
    currency_name VARCHAR(50) NOT NULL, -- Nama mata uang
    symbol VARCHAR(10) -- Simbol mata uang (misalnya '$', '¥', 'Rp')
);
COMMENT ON TABLE Currencies IS 'Master data untuk mata uang yang didukung.';

CREATE TABLE SupplierGroups (
    supplier_group_id UUID PRIMARY KEY DEFAULT gen_random_uuid(), -- ID unik grup supplier
    group_name VARCHAR(100) UNIQUE NOT NULL, -- Nama grup supplier
    description TEXT -- Deskripsi grup
);
COMMENT ON TABLE SupplierGroups IS 'Master data untuk kategori atau grup supplier.';

CREATE TABLE Warehouses (
    warehouse_id UUID PRIMARY KEY DEFAULT gen_random_uuid(), -- ID unik gudang
    warehouse_name VARCHAR(100) UNIQUE NOT NULL, -- Nama gudang
    address TEXT, -- Alamat gudang
    is_active BOOLEAN DEFAULT TRUE
);
COMMENT ON TABLE Warehouses IS 'Master data untuk gudang.';

CREATE TABLE StockEntryTypes (
    entry_type_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    type_name VARCHAR(50) UNIQUE NOT NULL, -- Tipe entry stok (misalnya 'Adjustment', 'Transfer', 'Production', 'Consumption')
    description TEXT
);
COMMENT ON TABLE StockEntryTypes IS 'Master data untuk tipe-tipe entry stok.';

CREATE TABLE Promotions (
    promotion_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    promotion_code VARCHAR(50) UNIQUE NOT NULL, -- Kode promosi
    promotion_name VARCHAR(100) NOT NULL, -- Nama promosi
    description TEXT,
    valid_from TIMESTAMP WITH TIME ZONE,
    valid_to TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE Promotions IS 'Master data untuk definisi promosi.';

CREATE TABLE TaxAuthorities (
    authority_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    authority_name VARCHAR(100) UNIQUE NOT NULL -- Nama otoritas pajak (misalnya 'Ditjen Pajak')
);
COMMENT ON TABLE TaxAuthorities IS 'Master data untuk otoritas pajak.';

CREATE TABLE KPIAggregations (
    kpi_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    kpi_name VARCHAR(100) UNIQUE NOT NULL, -- Nama KPI (misalnya 'Total Penjualan', 'Nilai Stok')
    aggregation_interval VARCHAR(50), -- Interval agregasi (misalnya 'Daily', 'Weekly', 'Monthly')
    last_computed_at TIMESTAMP WITH TIME ZONE, -- Waktu terakhir KPI dihitung
    definition JSONB -- Bagaimana KPI ini dihitung (misalnya, SQL query atau formula)
);
COMMENT ON TABLE KPIAggregations IS 'Master data untuk definisi Key Performance Indicators (KPIs).';

CREATE TABLE AccountTypes (
    account_type_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    type_name VARCHAR(50) UNIQUE NOT NULL, -- Tipe akun (misalnya 'Asset', 'Liability', 'Equity', 'Revenue', 'Expense')
    classification VARCHAR(50) NOT NULL CHECK (classification IN ('Balance Sheet', 'Profit and Loss')) -- Klasifikasi laporan keuangan
);
COMMENT ON TABLE AccountTypes IS 'Master data untuk tipe akun GL.';

CREATE TABLE GamificationRewards (
    reward_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    reward_name VARCHAR(100) UNIQUE NOT NULL, -- Nama reward (misalnya 'First PO Created', 'Sales Champion')
    description TEXT,
    points_awarded INT NOT NULL CHECK (points_awarded >= 0), -- Poin yang diberikan
    badge_image_url TEXT -- URL gambar badge
);
COMMENT ON TABLE GamificationRewards IS 'Master data untuk definisi reward gamifikasi.';

-- Tabel Level 1 (bergantung pada tabel dasar)
CREATE TABLE UserRoles (
    user_id UUID NOT NULL REFERENCES Users(user_id) ON DELETE CASCADE, -- Foreign Key ke Users, hapus jika user dihapus
    role_id UUID NOT NULL REFERENCES Roles(role_id) ON DELETE CASCADE, -- Foreign Key ke Roles, hapus jika role dihapus
    PRIMARY KEY (user_id, role_id) -- Kombinasi unik user dan role
);
COMMENT ON TABLE UserRoles IS 'Tabel relasi many-to-many antara pengguna dan peran.';

CREATE TABLE RolePermissions (
    role_id UUID NOT NULL REFERENCES Roles(role_id) ON DELETE CASCADE, -- Foreign Key ke Roles
    permission_id UUID NOT NULL REFERENCES Permissions(permission_id) ON DELETE CASCADE, -- Foreign Key ke Permissions
    PRIMARY KEY (role_id, permission_id) -- Kombinasi unik role dan permission
);
COMMENT ON TABLE RolePermissions IS 'Tabel relasi many-to-many antara peran dan izin.';

CREATE TABLE AuditLogs (
    log_id BIGSERIAL PRIMARY KEY, -- ID auto-increment untuk log, menggunakan BIGSERIAL untuk kapasitas besar
    user_id UUID REFERENCES Users(user_id), -- Foreign Key ke Users (bisa NULL jika tindakan sistem)
    action_type VARCHAR(50) NOT NULL, -- Tipe aksi (misalnya 'CREATE', 'UPDATE', 'DELETE', 'LOGIN')
    table_name VARCHAR(100), -- Nama tabel yang terpengaruh
    record_id TEXT, -- ID record yang terpengaruh (tipe TEXT untuk fleksibilitas ID dari berbagai tabel)
    old_data JSONB, -- Data sebelum perubahan (JSONB untuk penyimpanan JSON yang efisien)
    new_data JSONB, -- Data setelah perubahan (JSONB)
    ip_address INET, -- Alamat IP pengguna
    user_agent TEXT, -- Informasi browser/aplikasi pengguna
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP -- Waktu kejadian log
);
COMMENT ON TABLE AuditLogs IS 'Mencatat setiap aktivitas pengguna dan perubahan sistem.';
CREATE INDEX idx_auditlogs_user_id ON AuditLogs(user_id);
CREATE INDEX idx_auditlogs_timestamp ON AuditLogs(timestamp);
CREATE INDEX idx_auditlogs_table_record ON AuditLogs(table_name, record_id);

CREATE TABLE DocumentVersions (
    version_id BIGSERIAL PRIMARY KEY, -- ID auto-increment untuk versi dokumen
    document_type VARCHAR(50) NOT NULL, -- Tipe dokumen (misalnya 'SalesOrder', 'PurchaseInvoice')
    document_id UUID NOT NULL, -- ID dokumen asli
    version_number INT NOT NULL, -- Nomor versi dokumen
    changes JSONB, -- Detail perubahan antara versi ini dan sebelumnya
    changed_by UUID REFERENCES Users(user_id), -- Siapa yang melakukan perubahan
    changed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP, -- Waktu perubahan
    UNIQUE (document_type, document_id, version_number) -- Memastikan versi unik per dokumen
);
COMMENT ON TABLE DocumentVersions IS 'Melacak riwayat perubahan untuk dokumen penting.';
CREATE INDEX idx_docversions_document_id ON DocumentVersions(document_id);

CREATE TABLE Items (
    item_id UUID PRIMARY KEY DEFAULT gen_random_uuid(), -- ID unik barang
    sku VARCHAR(100) UNIQUE NOT NULL, -- Stock Keeping Unit, harus unik
    item_name VARCHAR(255) NOT NULL, -- Nama barang
    description TEXT, -- Deskripsi barang
    uom_id UUID NOT NULL REFERENCES UnitsOfMeasure(uom_id), -- Foreign Key ke UnitsOfMeasure
    item_group_id UUID REFERENCES ItemGroups(item_group_id), -- Foreign Key ke ItemGroups
    purchase_price NUMERIC(19, 4), -- Harga beli standar
    sales_price NUMERIC(19, 4), -- Harga jual standar
    weight NUMERIC(10, 2), -- Berat barang
    dimensions VARCHAR(100), -- Dimensi barang (misalnya "10x5x3 cm")
    is_active BOOLEAN DEFAULT TRUE, -- Status aktif/non-aktif barang
    image_url TEXT, -- URL gambar produk
    oem_part_number VARCHAR(100), -- Nomor part OEM
    supplier_part_number VARCHAR(100), -- Nomor part supplier
    has_serial_number BOOLEAN DEFAULT FALSE, -- Indikator apakah barang ini memiliki nomor seri
    has_batch_number BOOLEAN DEFAULT FALSE, -- Indikator apakah barang ini memiliki nomor batch
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE Items IS 'Master data untuk semua produk atau barang.';
CREATE INDEX idx_items_sku ON Items(sku);
CREATE INDEX idx_items_name ON Items(item_name);

CREATE TABLE Customers (
    customer_id UUID PRIMARY KEY DEFAULT gen_random_uuid(), -- ID unik pelanggan
    customer_name VARCHAR(255) NOT NULL, -- Nama pelanggan
    address TEXT, -- Alamat lengkap
    city VARCHAR(100),
    province VARCHAR(100),
    postal_code VARCHAR(20),
    country VARCHAR(100),
    phone_number VARCHAR(50),
    email VARCHAR(100),
    contact_person VARCHAR(150), -- Nama kontak person
    payment_term_id UUID REFERENCES PaymentTerms(payment_term_id), -- Foreign Key ke PaymentTerms
    customer_group_id UUID REFERENCES CustomerGroups(customer_group_id), -- Foreign Key ke CustomerGroups
    credit_limit NUMERIC(19, 4) DEFAULT 0 CHECK (credit_limit >= 0), -- Batas kredit pelanggan
    current_receivable_balance NUMERIC(19, 4) DEFAULT 0, -- Saldo piutang saat ini (bisa dihitung atau di-maintain)
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE Customers IS 'Master data untuk semua pelanggan.';
CREATE INDEX idx_customers_name ON Customers(customer_name);
CREATE INDEX idx_customers_email ON Customers(email);

CREATE TABLE CurrencyExchangeRates (
    rate_id BIGSERIAL PRIMARY KEY, -- ID auto-increment untuk kurs
    from_currency_id UUID NOT NULL REFERENCES Currencies(currency_id), -- Mata uang asal
    to_currency_id UUID NOT NULL REFERENCES Currencies(currency_id), -- Mata uang tujuan
    exchange_rate NUMERIC(19, 6) NOT NULL CHECK (exchange_rate > 0), -- Nilai tukar
    rate_date DATE NOT NULL, -- Tanggal kurs berlaku
    entered_by UUID REFERENCES Users(user_id), -- Siapa yang memasukkan kurs
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (from_currency_id, to_currency_id, rate_date) -- Hanya satu kurs per hari per pasangan mata uang
);
COMMENT ON TABLE CurrencyExchangeRates IS 'Menyimpan kurs mata uang historis.';
CREATE INDEX idx_exchange_rates_date ON CurrencyExchangeRates(rate_date);

CREATE TABLE Suppliers (
    supplier_id UUID PRIMARY KEY DEFAULT gen_random_uuid(), -- ID unik supplier
    supplier_name VARCHAR(255) NOT NULL, -- Nama supplier
    address TEXT,
    city VARCHAR(100),
    province VARCHAR(100),
    postal_code VARCHAR(20),
    country VARCHAR(100),
    phone_number VARCHAR(50),
    email VARCHAR(100),
    contact_person VARCHAR(150),
    payment_term_id UUID REFERENCES PaymentTerms(payment_term_id), -- Foreign Key ke PaymentTerms
    supplier_group_id UUID REFERENCES SupplierGroups(supplier_group_id), -- Foreign Key ke SupplierGroups
    default_currency_id UUID REFERENCES Currencies(currency_id), -- Mata uang default untuk transaksi dengan supplier ini
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE Suppliers IS 'Master data untuk semua vendor atau supplier.';
CREATE INDEX idx_suppliers_name ON Suppliers(supplier_name);
CREATE INDEX idx_suppliers_email ON Suppliers(email);

CREATE TABLE Bins (
    bin_id UUID PRIMARY KEY DEFAULT gen_random_uuid(), -- ID unik lokasi bin
    warehouse_id UUID NOT NULL REFERENCES Warehouses(warehouse_id) ON DELETE CASCADE, -- Foreign Key ke Warehouses
    bin_code VARCHAR(50) NOT NULL, -- Kode bin (misalnya 'A-01-01')
    description TEXT,
    UNIQUE (warehouse_id, bin_code) -- Memastikan kode bin unik dalam satu gudang
);
COMMENT ON TABLE Bins IS 'Master data untuk lokasi spesifik dalam gudang (rak, lorong, bin).';
CREATE INDEX idx_bins_warehouse_id ON Bins(warehouse_id);

CREATE TABLE StockEntries (
    stock_entry_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    entry_number VARCHAR(50) UNIQUE NOT NULL, -- Nomor entry stok
    entry_date DATE NOT NULL DEFAULT CURRENT_DATE, -- Tanggal entry
    entry_type_id UUID NOT NULL REFERENCES StockEntryTypes(entry_type_id), -- Foreign Key ke StockEntryTypes
    purpose TEXT, -- Tujuan entry stok
    from_warehouse_id UUID REFERENCES Warehouses(warehouse_id), -- Gudang asal (untuk transfer)
    to_warehouse_id UUID REFERENCES Warehouses(warehouse_id), -- Gudang tujuan (untuk transfer)
    status VARCHAR(50) NOT NULL DEFAULT 'Draft', -- Status entry (e.g., 'Draft', 'Submitted', 'Approved', 'Completed', 'Cancelled')
    created_by UUID REFERENCES Users(user_id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE StockEntries IS 'Tabel header untuk semua jenis pergerakan atau penyesuaian stok.';
CREATE INDEX idx_stockentries_entry_number ON StockEntries(entry_number);
CREATE INDEX idx_stockentries_type ON StockEntries(entry_type_id);

CREATE TABLE ReportConfigurations (
    report_config_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES Users(user_id), -- Pengguna yang membuat konfigurasi laporan
    report_name VARCHAR(100) NOT NULL, -- Nama laporan kustom
    description TEXT,
    base_table VARCHAR(100) NOT NULL, -- Tabel dasar untuk laporan (misalnya 'SalesInvoices', 'Items')
    columns_selected JSONB, -- Array dari nama kolom yang akan ditampilkan (JSONB)
    filters JSONB, -- Objek JSON berisi kondisi filter (JSONB)
    sorting_order JSONB, -- Objek JSON berisi field dan arah pengurutan (JSONB)
    grouping_fields JSONB, -- Array dari field untuk pengelompokan (JSONB)
    is_public BOOLEAN DEFAULT FALSE, -- Apakah laporan bisa dilihat oleh pengguna lain
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE ReportConfigurations IS 'Menyimpan konfigurasi laporan kustom yang dibuat oleh pengguna.';
CREATE INDEX idx_report_configs_user_id ON ReportConfigurations(user_id);

CREATE TABLE KPIDataPoints (
    data_point_id BIGSERIAL PRIMARY KEY,
    kpi_id UUID NOT NULL REFERENCES KPIAggregations(kpi_id) ON DELETE CASCADE, -- Foreign Key ke KPIAggregations
    period_start DATE NOT NULL, -- Tanggal mulai periode data
    period_end DATE NOT NULL, -- Tanggal akhir periode data
    value NUMERIC(19, 4) NOT NULL, -- Nilai KPI untuk periode tersebut
    UNIQUE (kpi_id, period_start) -- Memastikan data unik per KPI dan periode
);
COMMENT ON TABLE KPIDataPoints IS 'Menyimpan nilai historis untuk setiap KPI.';
CREATE INDEX idx_kpi_data_points_kpi_period ON KPIDataPoints(kpi_id, period_start);

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

CREATE TABLE SystemSettings (
    setting_key VARCHAR(100) PRIMARY KEY, -- Kunci pengaturan (misalnya 'company_name', 'default_currency')
    setting_value TEXT NOT NULL, -- Nilai pengaturan
    description TEXT, -- Deskripsi pengaturan
    last_updated_by UUID REFERENCES Users(user_id),
    last_updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE SystemSettings IS 'Menyimpan pengaturan konfigurasi umum sistem.';

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

CREATE TABLE ChartOfAccounts (
    account_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    account_code VARCHAR(50) UNIQUE NOT NULL, -- Kode akun unik
    account_name VARCHAR(100) NOT NULL, -- Nama akun
    account_type_id UUID NOT NULL REFERENCES AccountTypes(account_type_id), -- Foreign Key ke AccountTypes
    parent_account_id UUID REFERENCES ChartOfAccounts(account_id), -- Untuk hierarki akun (self-referencing FK)
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE ChartOfAccounts IS 'Master data untuk Bagan Akun (Chart of Accounts).';
CREATE INDEX idx_coa_code ON ChartOfAccounts(account_code);

CREATE TABLE BankAccounts (
    bank_account_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    bank_name VARCHAR(100) NOT NULL, -- Nama bank
    account_number VARCHAR(100) UNIQUE NOT NULL, -- Nomor rekening bank
    account_name VARCHAR(100), -- Nama pemilik rekening
    currency_id UUID NOT NULL REFERENCES Currencies(currency_id), -- Mata uang rekening
    initial_balance NUMERIC(19, 4) DEFAULT 0 -- Saldo awal rekening
);
COMMENT ON TABLE BankAccounts IS 'Master data untuk rekening bank perusahaan.';

CREATE TABLE TaxRates (
    tax_rate_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tax_name VARCHAR(100) UNIQUE NOT NULL, -- Nama pajak (misalnya 'PPN Masukan', 'Bea Masuk')
    rate NUMERIC(5, 2) NOT NULL CHECK (rate >= 0), -- Persentase tarif pajak (misalnya 11.00 untuk 11%)
    tax_type VARCHAR(50) NOT NULL, -- Tipe pajak (misalnya 'VAT_Input', 'VAT_Output', 'Import_Tax')
    authority_id UUID REFERENCES TaxAuthorities(authority_id), -- Foreign Key ke TaxAuthorities
    is_active BOOLEAN DEFAULT TRUE,
    valid_from DATE, -- Tanggal mulai berlaku tarif
    valid_to DATE, -- Tanggal berakhir berlaku tarif
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE TaxRates IS 'Master data untuk tarif pajak dan bea cukai.';

CREATE TABLE ExpenseCategories (
    category_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    category_name VARCHAR(100) UNIQUE NOT NULL, -- Nama kategori pengeluaran
    description TEXT,
    default_gl_account_id UUID REFERENCES ChartOfAccounts(account_id) -- Akun GL default untuk kategori ini
);
COMMENT ON TABLE ExpenseCategories IS 'Master data untuk kategori pengeluaran.';

CREATE TABLE AssetCategories (
    category_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    category_name VARCHAR(100) UNIQUE NOT NULL, -- Nama kategori aset
    description TEXT,
    default_depreciation_account_id UUID REFERENCES ChartOfAccounts(account_id) -- Akun GL default untuk depresiasi
);
COMMENT ON TABLE AssetCategories IS 'Master data untuk kategori aset tetap.';

-- Tabel Level 2 (bergantung pada tabel Level 1)
CREATE TABLE RequestForQuotations (
    rfq_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    rfq_number VARCHAR(50) UNIQUE NOT NULL, -- Nomor RFQ
    rfq_date DATE NOT NULL DEFAULT CURRENT_DATE, -- Tanggal RFQ
    supplier_id UUID REFERENCES Suppliers(supplier_id), -- Supplier yang dituju (bisa NULL jika RFQ umum)
    status VARCHAR(50) NOT NULL DEFAULT 'Draft', -- Status RFQ (e.g., 'Draft', 'Sent', 'Received', 'Closed')
    valid_until_date DATE, -- Tanggal validitas penawaran yang diharapkan
    requested_by UUID REFERENCES Users(user_id), -- Pengguna yang membuat RFQ
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE RequestForQuotations IS 'Tabel header untuk Permintaan Penawaran (RFQ).';
CREATE INDEX idx_rfq_number ON RequestForQuotations(rfq_number);

CREATE TABLE SupplierQuotations (
    sq_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sq_number VARCHAR(50) UNIQUE NOT NULL, -- Nomor Penawaran Supplier
    rfq_id UUID REFERENCES RequestForQuotations(rfq_id), -- Foreign Key ke RFQ (bisa NULL jika penawaran tidak diminta)
    supplier_id UUID NOT NULL REFERENCES Suppliers(supplier_id), -- Foreign Key ke Suppliers
    quotation_date DATE NOT NULL DEFAULT CURRENT_DATE, -- Tanggal penawaran
    validity_date DATE, -- Tanggal validitas penawaran
    currency_id UUID NOT NULL REFERENCES Currencies(currency_id), -- Mata uang penawaran
    total_amount NUMERIC(19, 4), -- Total jumlah penawaran
    status VARCHAR(50) NOT NULL DEFAULT 'Received', -- Status penawaran (e.g., 'Received', 'Accepted', 'Rejected')
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE SupplierQuotations IS 'Tabel header untuk Penawaran dari Supplier (Vendor Quotation).';
CREATE INDEX idx_sq_number ON SupplierQuotations(sq_number);
CREATE INDEX idx_sq_rfq_id ON SupplierQuotations(rfq_id);
CREATE INDEX idx_sq_supplier_id ON SupplierQuotations(supplier_id);

CREATE TABLE PurchaseOrders (
    po_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    po_number VARCHAR(50) UNIQUE NOT NULL, -- Nomor Purchase Order
    supplier_id UUID NOT NULL REFERENCES Suppliers(supplier_id), -- Foreign Key ke Suppliers
    order_date DATE NOT NULL DEFAULT CURRENT_DATE, -- Tanggal PO dibuat
    required_delivery_date DATE, -- Tanggal pengiriman yang dibutuhkan
    currency_id UUID NOT NULL REFERENCES Currencies(currency_id), -- Mata uang PO
    exchange_rate NUMERIC(19, 6) NOT NULL DEFAULT 1, -- Kurs pada saat PO dibuat (untuk transaksi multi-currency)
    total_amount NUMERIC(19, 4), -- Total jumlah PO
    status VARCHAR(50) NOT NULL DEFAULT 'Draft', -- Status PO (e.g., 'Draft', 'Pending Approval', 'Approved', 'Ordered', 'Partially Received', 'Completed', 'Cancelled')
    approved_by UUID REFERENCES Users(user_id), -- Pengguna yang menyetujui PO
    approved_at TIMESTAMP WITH TIME ZONE, -- Waktu PO disetujui
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE PurchaseOrders IS 'Tabel header untuk Purchase Order (PO).';
CREATE INDEX idx_po_number ON PurchaseOrders(po_number);
CREATE INDEX idx_po_supplier_id ON PurchaseOrders(supplier_id);

CREATE TABLE GoodReceiptNotes (
    grn_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    grn_number VARCHAR(50) UNIQUE NOT NULL, -- Nomor Good Receipt Note
    po_id UUID REFERENCES PurchaseOrders(po_id), -- Foreign Key ke PO (bisa NULL untuk GRN non-PO)
    supplier_id UUID NOT NULL REFERENCES Suppliers(supplier_id), -- Foreign Key ke Suppliers
    receipt_date DATE NOT NULL DEFAULT CURRENT_DATE, -- Tanggal penerimaan barang
    warehouse_id UUID NOT NULL REFERENCES Warehouses(warehouse_id), -- Gudang tempat barang diterima
    status VARCHAR(50) NOT NULL DEFAULT 'Draft', -- Status GRN (e.g., 'Draft', 'Completed', 'Cancelled')
    received_by UUID REFERENCES Users(user_id), -- Pengguna yang menerima barang
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE GoodReceiptNotes IS 'Tabel header untuk Penerimaan Barang (GRN).';
CREATE INDEX idx_grn_number ON GoodReceiptNotes(grn_number);
CREATE INDEX idx_grn_po_id ON GoodReceiptNotes(po_id);

CREATE TABLE PurchaseInvoices (
    pi_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pi_number VARCHAR(50) UNIQUE NOT NULL, -- Nomor Purchase Invoice
    supplier_id UUID NOT NULL REFERENCES Suppliers(supplier_id), -- Foreign Key ke Suppliers
    po_id UUID REFERENCES PurchaseOrders(po_id), -- Foreign Key ke PO (opsional)
    grn_id UUID REFERENCES GoodReceiptNotes(grn_id), -- Foreign Key ke GRN (opsional)
    invoice_date DATE NOT NULL, -- Tanggal invoice dari supplier
    due_date DATE NOT NULL, -- Tanggal jatuh tempo pembayaran
    currency_id UUID NOT NULL REFERENCES Currencies(currency_id), -- Mata uang invoice
    exchange_rate NUMERIC(19, 6) NOT NULL DEFAULT 1, -- Kurs pada saat PI dibuat
    total_amount NUMERIC(19, 4) NOT NULL, -- Total jumlah invoice
    tax_amount NUMERIC(19, 4) DEFAULT 0, -- Jumlah pajak
    net_amount NUMERIC(19, 4) GENERATED ALWAYS AS (total_amount - tax_amount) STORED, -- Jumlah bersih (total - pajak)
    status VARCHAR(50) NOT NULL DEFAULT 'Draft', -- Status PI (e.g., 'Draft', 'Pending Approval', 'Approved', 'Paid', 'Partially Paid', 'Cancelled')
    is_3_way_matched BOOLEAN DEFAULT FALSE, -- Indikator apakah sudah cocok 3 arah (PO, GRN, PI)
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE PurchaseInvoices IS 'Tabel header untuk Purchase Invoice (PI).';
CREATE INDEX idx_pi_number ON PurchaseInvoices(pi_number);
CREATE INDEX idx_pi_supplier_id ON PurchaseInvoices(supplier_id);
CREATE INDEX idx_pi_po_id ON PurchaseInvoices(po_id);

CREATE TABLE AccountsPayables (
    ap_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pi_id UUID NOT NULL REFERENCES PurchaseInvoices(pi_id) ON DELETE CASCADE UNIQUE, -- Foreign Key ke PurchaseInvoices (one-to-one)
    supplier_id UUID NOT NULL REFERENCES Suppliers(supplier_id), -- Foreign Key ke Suppliers
    amount_due NUMERIC(19, 4) NOT NULL, -- Jumlah yang harus dibayar
    amount_paid NUMERIC(19, 4) DEFAULT 0, -- Jumlah yang sudah dibayar
    currency_id UUID NOT NULL REFERENCES Currencies(currency_id), -- Mata uang hutang
    due_date DATE NOT NULL, -- Tanggal jatuh tempo
    status VARCHAR(50) NOT NULL DEFAULT 'Outstanding', -- Status hutang (e.g., 'Outstanding', 'Partially Paid', 'Paid', 'Overdue')
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE AccountsPayables IS 'Tabel untuk mencatat hutang dagang (Accounts Payable).';
CREATE INDEX idx_ap_supplier_id ON AccountsPayables(supplier_id);
CREATE INDEX idx_ap_due_date ON AccountsPayables(due_date);

CREATE TABLE LandedCostVouchers (
    lc_voucher_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    lc_voucher_number VARCHAR(50) UNIQUE NOT NULL, -- Nomor voucher landed cost
    purchase_invoice_id UUID NOT NULL REFERENCES PurchaseInvoices(pi_id), -- PI yang akan dialokasikan biayanya
    voucher_date DATE NOT NULL DEFAULT CURRENT_DATE, -- Tanggal voucher
    description TEXT,
    total_cost_amount NUMERIC(19, 4) NOT NULL CHECK (total_cost_amount >= 0), -- Total biaya landed cost
    status VARCHAR(50) NOT NULL DEFAULT 'Draft', -- Status voucher (e.g., 'Draft', 'Completed')
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE LandedCostVouchers IS 'Tabel header untuk perhitungan Landed Cost.';
CREATE INDEX idx_lc_voucher_pi_id ON LandedCostVouchers(purchase_invoice_id);

CREATE TABLE SalesQuotations (
    sq_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sq_number VARCHAR(50) UNIQUE NOT NULL, -- Nomor Sales Quotation
    customer_id UUID NOT NULL REFERENCES Customers(customer_id), -- Foreign Key ke Customers
    quotation_date DATE NOT NULL DEFAULT CURRENT_DATE, -- Tanggal quotation
    validity_date DATE, -- Tanggal validitas quotation
    currency_id UUID NOT NULL REFERENCES Currencies(currency_id), -- Mata uang quotation
    exchange_rate NUMERIC(19, 6) NOT NULL DEFAULT 1, -- Kurs pada saat SQ dibuat
    total_amount NUMERIC(19, 4), -- Total jumlah quotation
    status VARCHAR(50) NOT NULL DEFAULT 'Draft', -- Status SQ (e.g., 'Draft', 'Sent', 'Accepted', 'Rejected', 'Converted')
    created_by UUID REFERENCES Users(user_id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE SalesQuotations IS 'Tabel header untuk Sales Quotation (SQ).';
CREATE INDEX idx_sales_sq_number ON SalesQuotations(sq_number);
CREATE INDEX idx_sales_sq_customer_id ON SalesQuotations(customer_id);

CREATE TABLE SalesOrders (
    so_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    so_number VARCHAR(50) UNIQUE NOT NULL, -- Nomor Sales Order
    customer_id UUID NOT NULL REFERENCES Customers(customer_id), -- Foreign Key ke Customers
    sq_id UUID REFERENCES SalesQuotations(sq_id), -- Foreign Key ke SalesQuotations (jika dikonversi dari SQ)
    order_date DATE NOT NULL DEFAULT CURRENT_DATE, -- Tanggal SO dibuat
    required_delivery_date DATE, -- Tanggal pengiriman yang dibutuhkan
    currency_id UUID NOT NULL REFERENCES Currencies(currency_id), -- Mata uang SO
    exchange_rate NUMERIC(19, 6) NOT NULL DEFAULT 1, -- Kurs pada saat SO dibuat
    total_amount NUMERIC(19, 4), -- Total jumlah SO
    status VARCHAR(50) NOT NULL DEFAULT 'Draft', -- Status SO (e.g., 'Draft', 'Pending Approval', 'Approved', 'Processing', 'Partially Delivered', 'Completed', 'Cancelled')
    created_by UUID REFERENCES Users(user_id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE SalesOrders IS 'Tabel header untuk Sales Order (SO).';
CREATE INDEX idx_sales_so_number ON SalesOrders(so_number);
CREATE INDEX idx_sales_so_customer_id ON SalesOrders(customer_id);

CREATE TABLE DeliveryNotes (
    dn_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    dn_number VARCHAR(50) UNIQUE NOT NULL, -- Nomor Delivery Note / Surat Jalan
    so_id UUID NOT NULL REFERENCES SalesOrders(so_id), -- Foreign Key ke SalesOrders
    customer_id UUID NOT NULL REFERENCES Customers(customer_id), -- Foreign Key ke Customers
    delivery_date DATE NOT NULL DEFAULT CURRENT_DATE, -- Tanggal pengiriman
    warehouse_id UUID NOT NULL REFERENCES Warehouses(warehouse_id), -- Gudang asal pengiriman
    status VARCHAR(50) NOT NULL DEFAULT 'Draft', -- Status DN (e.g., 'Draft', 'Shipped', 'Delivered', 'Cancelled')
    prepared_by UUID REFERENCES Users(user_id), -- Pengguna yang menyiapkan DN
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE DeliveryNotes IS 'Tabel header untuk Delivery Note (Surat Jalan).';
CREATE INDEX idx_delivery_dn_number ON DeliveryNotes(dn_number);
CREATE INDEX idx_delivery_dn_so_id ON DeliveryNotes(so_id);

CREATE TABLE SalesInvoices (
    si_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    si_number VARCHAR(50) UNIQUE NOT NULL, -- Nomor Sales Invoice
    customer_id UUID NOT NULL REFERENCES Customers(customer_id), -- Foreign Key ke Customers
    so_id UUID REFERENCES SalesOrders(so_id), -- Foreign Key ke SO (opsional)
    dn_id UUID REFERENCES DeliveryNotes(dn_id), -- Foreign Key ke DN (opsional)
    invoice_date DATE NOT NULL DEFAULT CURRENT_DATE, -- Tanggal invoice
    due_date DATE NOT NULL, -- Tanggal jatuh tempo pembayaran
    currency_id UUID NOT NULL REFERENCES Currencies(currency_id), -- Mata uang invoice
    exchange_rate NUMERIC(19, 6) NOT NULL DEFAULT 1, -- Kurs pada saat SI dibuat
    total_amount NUMERIC(19, 4) NOT NULL, -- Total jumlah invoice
    tax_amount NUMERIC(19, 4) DEFAULT 0, -- Jumlah pajak
    net_amount NUMERIC(19, 4) GENERATED ALWAYS AS (total_amount - tax_amount) STORED, -- Jumlah bersih (total - pajak)
    status VARCHAR(50) NOT NULL DEFAULT 'Draft', -- Status SI (e.g., 'Draft', 'Pending Payment', 'Paid', 'Partially Paid', 'Overdue', 'Cancelled')
    created_by UUID REFERENCES Users(user_id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE SalesInvoices IS 'Tabel header untuk Sales Invoice (Faktur Penjualan).';
CREATE INDEX idx_sales_si_number ON SalesInvoices(si_number);
CREATE INDEX idx_sales_si_customer_id ON SalesInvoices(customer_id);
CREATE INDEX idx_sales_si_so_id ON SalesInvoices(so_id);

CREATE TABLE AccountsReceivables (
    ar_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    si_id UUID NOT NULL REFERENCES SalesInvoices(si_id) ON DELETE CASCADE UNIQUE, -- Foreign Key ke SalesInvoices (one-to-one)
    customer_id UUID NOT NULL REFERENCES Customers(customer_id), -- Foreign Key ke Customers
    amount_due NUMERIC(19, 4) NOT NULL, -- Jumlah yang harus diterima
    amount_paid NUMERIC(19, 4) DEFAULT 0, -- Jumlah yang sudah diterima
    currency_id UUID NOT NULL REFERENCES Currencies(currency_id), -- Mata uang piutang
    due_date DATE NOT NULL, -- Tanggal jatuh tempo
    status VARCHAR(50) NOT NULL DEFAULT 'Outstanding', -- Status piutang (e.g., 'Outstanding', 'Partially Paid', 'Paid', 'Overdue')
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE AccountsReceivables IS 'Tabel untuk mencatat piutang dagang (Accounts Receivable).';
CREATE INDEX idx_ar_customer_id ON AccountsReceivables(customer_id);
CREATE INDEX idx_ar_due_date ON AccountsReceivables(due_date);

CREATE TABLE Discounts (
    discount_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    discount_code VARCHAR(50) UNIQUE NOT NULL, -- Kode diskon
    discount_name VARCHAR(100) NOT NULL, -- Nama diskon
    discount_type VARCHAR(20) NOT NULL CHECK (discount_type IN ('Percentage', 'Amount')), -- Tipe diskon (Persentase atau Jumlah)
    discount_value NUMERIC(10, 2) NOT NULL CHECK (discount_value >= 0), -- Nilai diskon
    applies_to VARCHAR(50) NOT NULL CHECK (applies_to IN ('All', 'Item', 'Customer', 'ItemGroup', 'CustomerGroup')), -- Berlaku untuk apa
    item_id UUID REFERENCES Items(item_id), -- Jika berlaku untuk item tertentu
    customer_id UUID REFERENCES Customers(customer_id), -- Jika berlaku untuk pelanggan tertentu
    item_group_id UUID REFERENCES ItemGroups(item_group_id),
    customer_group_id UUID REFERENCES CustomerGroups(customer_group_id),
    minimum_quantity NUMERIC(19, 4) DEFAULT 0, -- Kuantitas minimum untuk mendapatkan diskon
    minimum_order_amount NUMERIC(19, 4) DEFAULT 0, -- Jumlah order minimum untuk mendapatkan diskon
    valid_from TIMESTAMP WITH TIME ZONE, -- Tanggal mulai berlaku
    valid_to TIMESTAMP WITH TIME ZONE, -- Tanggal berakhir
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE Discounts IS 'Master data untuk definisi diskon.';

CREATE TABLE SalesReturns (
    sr_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sr_number VARCHAR(50) UNIQUE NOT NULL, -- Nomor Sales Return
    customer_id UUID NOT NULL REFERENCES Customers(customer_id), -- Foreign Key ke Customers
    sales_invoice_id UUID REFERENCES SalesInvoices(si_id), -- Foreign Key ke SalesInvoices (jika terkait invoice tertentu)
    return_date DATE NOT NULL DEFAULT CURRENT_DATE, -- Tanggal pengembalian
    return_reason TEXT, -- Alasan pengembalian
    status VARCHAR(50) NOT NULL DEFAULT 'Pending Inspection', -- Status pengembalian (e.g., 'Pending Inspection', 'Approved', 'Rejected', 'Completed')
    credit_memo_issued BOOLEAN DEFAULT FALSE, -- Indikator apakah memo kredit sudah diterbitkan
    created_by UUID REFERENCES Users(user_id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE SalesReturns IS 'Tabel header untuk Pengembalian Barang (Sales Return).';
CREATE INDEX idx_sales_sr_number ON SalesReturns(sr_number);
CREATE INDEX idx_sales_sr_customer_id ON SalesReturns(customer_id);

CREATE TABLE ItemStock (
    stock_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    item_id UUID NOT NULL REFERENCES Items(item_id), -- Foreign Key ke Items
    warehouse_id UUID NOT NULL REFERENCES Warehouses(warehouse_id), -- Foreign Key ke Warehouses
    bin_id UUID REFERENCES Bins(bin_id), -- Foreign Key ke Bins (bisa NULL jika stok di level gudang saja)
    quantity NUMERIC(19, 4) NOT NULL DEFAULT 0 CHECK (quantity >= 0), -- Kuantitas stok saat ini
    valuation_rate NUMERIC(19, 4) NOT NULL DEFAULT 0, -- Rata-rata biaya perolehan atau FIFO cost
    last_updated TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP, -- Waktu terakhir stok diupdate
    UNIQUE (item_id, warehouse_id, bin_id) -- Memastikan stok unik per item di lokasi spesifik
);
COMMENT ON TABLE ItemStock IS 'Menyimpan kuantitas stok aktual setiap item di setiap lokasi gudang.';
CREATE INDEX idx_itemstock_item_id ON ItemStock(item_id);
CREATE INDEX idx_itemstock_warehouse_id ON ItemStock(warehouse_id);

CREATE TABLE JournalEntries (
    journal_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    journal_number VARCHAR(50) UNIQUE NOT NULL, -- Nomor jurnal
    entry_date DATE NOT NULL DEFAULT CURRENT_DATE, -- Tanggal entry jurnal
    posting_date DATE NOT NULL, -- Tanggal posting ke GL
    reference_document_type VARCHAR(50), -- Tipe dokumen referensi (misalnya 'PurchaseInvoice', 'SalesInvoice')
    reference_document_id UUID, -- ID dokumen referensi
    narration TEXT, -- Deskripsi jurnal
    created_by UUID REFERENCES Users(user_id),
    status VARCHAR(50) NOT NULL DEFAULT 'Draft', -- Status jurnal (e.g., 'Draft', 'Posted', 'Reversed')
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE JournalEntries IS 'Tabel header untuk setiap entri jurnal umum.';
CREATE INDEX idx_journal_entry_date ON JournalEntries(entry_date);
CREATE INDEX idx_journal_ref_doc ON JournalEntries(reference_document_type, reference_document_id);

CREATE TABLE BankTransactions (
    bank_transaction_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    bank_account_id UUID NOT NULL REFERENCES BankAccounts(bank_account_id) ON DELETE CASCADE, -- Foreign Key ke BankAccounts
    transaction_date DATE NOT NULL, -- Tanggal transaksi bank
    description TEXT, -- Deskripsi transaksi
    transaction_type VARCHAR(50) NOT NULL, -- Tipe transaksi (misalnya 'Deposit', 'Withdrawal', 'Fee')
    amount NUMERIC(19, 4) NOT NULL, -- Jumlah transaksi
    is_reconciled BOOLEAN DEFAULT FALSE, -- Indikator apakah sudah direkonsiliasi
    reconciled_at TIMESTAMP WITH TIME ZONE, -- Waktu rekonsiliasi
    bank_statement_line TEXT, -- Baris mentah dari laporan bank (opsional)
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE BankTransactions IS 'Mencatat transaksi yang berasal dari laporan bank.';
CREATE INDEX idx_bank_transactions_account_date ON BankTransactions(bank_account_id, transaction_date);

CREATE TABLE Expenses (
    expense_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    expense_number VARCHAR(50) UNIQUE NOT NULL, -- Nomor pengeluaran
    expense_date DATE NOT NULL DEFAULT CURRENT_DATE, -- Tanggal pengeluaran
    category_id UUID NOT NULL REFERENCES ExpenseCategories(category_id), -- Foreign Key ke ExpenseCategories
    amount NUMERIC(19, 4) NOT NULL CHECK (amount > 0), -- Jumlah pengeluaran
    currency_id UUID NOT NULL REFERENCES Currencies(currency_id), -- Mata uang pengeluaran
    exchange_rate NUMERIC(19, 6) NOT NULL DEFAULT 1, -- Kurs pada saat pengeluaran
    description TEXT,
    paid_from_bank_account_id UUID REFERENCES BankAccounts(bank_account_id), -- Dari rekening bank mana dibayar
    paid_by_employee_id UUID REFERENCES Users(user_id), -- Siapa karyawan yang mengeluarkan (jika ada)
    status VARCHAR(50) NOT NULL DEFAULT 'Draft', -- Status pengeluaran (e.g., 'Draft', 'Pending Approval', 'Approved', 'Paid')
    created_by UUID REFERENCES Users(user_id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE Expenses IS 'Tabel untuk mencatat pengeluaran operasional perusahaan.';
CREATE INDEX idx_expenses_date ON Expenses(expense_date);
CREATE INDEX idx_expenses_category ON Expenses(category_id);

CREATE TABLE Assets (
    asset_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    asset_code VARCHAR(50) UNIQUE NOT NULL, -- Kode aset unik
    asset_name VARCHAR(255) NOT NULL, -- Nama aset
    category_id UUID NOT NULL REFERENCES AssetCategories(category_id), -- Foreign Key ke AssetCategories
    purchase_date DATE NOT NULL, -- Tanggal pembelian
    purchase_price NUMERIC(19, 4) NOT NULL CHECK (purchase_price >= 0), -- Harga pembelian
    useful_life_years INT NOT NULL CHECK (useful_life_years > 0), -- Umur manfaat dalam tahun
    depreciation_method VARCHAR(50) NOT NULL DEFAULT 'Straight-Line', -- Metode depresiasi (misalnya 'Straight-Line', 'Declining Balance')
    current_book_value NUMERIC(19, 4) NOT NULL, -- Nilai buku saat ini
    accumulated_depreciation NUMERIC(19, 4) NOT NULL DEFAULT 0, -- Akumulasi depresiasi
    status VARCHAR(50) NOT NULL DEFAULT 'In Use', -- Status aset (e.g., 'In Use', 'Disposed', 'Scrapped')
    location TEXT, -- Lokasi fisik aset
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE Assets IS 'Tabel untuk mencatat aset tetap perusahaan.';
CREATE INDEX idx_assets_code ON Assets(asset_code);

CREATE TABLE StockReconciliations (
    recon_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    recon_number VARCHAR(50) UNIQUE NOT NULL, -- Nomor rekonsiliasi stok
    warehouse_id UUID NOT NULL REFERENCES Warehouses(warehouse_id), -- Foreign Key ke Warehouses
    recon_date DATE NOT NULL DEFAULT CURRENT_DATE, -- Tanggal rekonsiliasi
    status VARCHAR(50) NOT NULL DEFAULT 'Draft', -- Status (e.g., 'Draft', 'Pending Approval', 'Completed', 'Cancelled')
    counted_by UUID REFERENCES Users(user_id), -- Pengguna yang melakukan penghitungan
    approved_by UUID REFERENCES Users(user_id), -- Pengguna yang menyetujui
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE StockReconciliations IS 'Tabel header untuk perhitungan fisik atau siklus hitung stok.';
CREATE INDEX idx_stockrecon_number ON StockReconciliations(recon_number);
CREATE INDEX idx_stockrecon_warehouse_id ON StockReconciliations(warehouse_id);

CREATE TABLE ItemWarehouseConfig ( -- Untuk menyimpan konfigurasi reorder point per item per gudang
    item_id UUID NOT NULL REFERENCES Items(item_id),
    warehouse_id UUID NOT NULL REFERENCES Warehouses(warehouse_id),
    min_stock_level NUMERIC(19, 4) DEFAULT 0 CHECK (min_stock_level >= 0), -- Level stok minimum
    reorder_point NUMERIC(19, 4) DEFAULT 0 CHECK (reorder_point >= 0), -- Titik pemesanan ulang
    reorder_quantity NUMERIC(19, 4) DEFAULT 0 CHECK (reorder_quantity >= 0), -- Kuantitas pemesanan ulang yang direkomendasikan
    PRIMARY KEY (item_id, warehouse_id) -- Kombinasi unik item dan gudang
);
COMMENT ON TABLE ItemWarehouseConfig IS 'Konfigurasi level stok minimum dan reorder point per item per gudang.';

CREATE TABLE ReorderAlerts (
    alert_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    item_id UUID NOT NULL REFERENCES Items(item_id),
    warehouse_id UUID NOT NULL REFERENCES Warehouses(warehouse_id),
    alert_date DATE NOT NULL DEFAULT CURRENT_DATE, -- Tanggal peringatan
    current_stock NUMERIC(19, 4) NOT NULL, -- Stok saat ini ketika peringatan dibuat
    reorder_level NUMERIC(19, 4) NOT NULL, -- Reorder level yang terpicu
    recommended_purchase_quantity NUMERIC(19, 4), -- Kuantitas pembelian yang direkomendasikan
    status VARCHAR(50) NOT NULL DEFAULT 'New', -- Status peringatan (e.g., 'New', 'Acknowledged', 'PO Created')
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE ReorderAlerts IS 'Mencatat peringatan ketika stok mencapai level minimum atau reorder point.';
CREATE INDEX idx_reorder_alerts_item_wh ON ReorderAlerts(item_id, warehouse_id);

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

-- Tabel Level 3 (bergantung pada tabel Level 2)
CREATE TABLE RFQItems (
    rfq_item_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    rfq_id UUID NOT NULL REFERENCES RequestForQuotations(rfq_id) ON DELETE CASCADE, -- Foreign Key ke RequestForQuotations
    item_id UUID NOT NULL REFERENCES Items(item_id), -- Foreign Key ke Items
    quantity NUMERIC(19, 4) NOT NULL CHECK (quantity > 0), -- Kuantitas yang diminta
    requested_delivery_date DATE, -- Tanggal pengiriman yang diharapkan
    notes TEXT -- Catatan untuk item ini
);
COMMENT ON TABLE RFQItems IS 'Tabel detail untuk item dalam setiap RFQ.';
CREATE INDEX idx_rfqitems_rfq_id ON RFQItems(rfq_id);

CREATE TABLE SupplierQuotationItems (
    sq_item_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sq_id UUID NOT NULL REFERENCES SupplierQuotations(sq_id) ON DELETE CASCADE, -- Foreign Key ke SupplierQuotations
    item_id UUID NOT NULL REFERENCES Items(item_id), -- Foreign Key ke Items
    quantity NUMERIC(19, 4) NOT NULL CHECK (quantity > 0), -- Kuantitas yang ditawarkan
    unit_price NUMERIC(19, 4) NOT NULL CHECK (unit_price >= 0), -- Harga per unit
    lead_time_days INT, -- Waktu pengiriman dalam hari
    notes TEXT
);
COMMENT ON TABLE SupplierQuotationItems IS 'Tabel detail untuk item dalam setiap Penawaran Supplier.';
CREATE INDEX idx_sqitems_sq_id ON SupplierQuotationItems(sq_id);

CREATE TABLE PurchaseOrderItems (
    po_item_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    po_id UUID NOT NULL REFERENCES PurchaseOrders(po_id) ON DELETE CASCADE, -- Foreign Key ke PurchaseOrders
    item_id UUID NOT NULL REFERENCES Items(item_id), -- Foreign Key ke Items
    quantity NUMERIC(19, 4) NOT NULL CHECK (quantity > 0), -- Kuantitas yang dipesan
    unit_price NUMERIC(19, 4) NOT NULL CHECK (unit_price >= 0), -- Harga per unit
    received_quantity NUMERIC(19, 4) DEFAULT 0, -- Kuantitas yang sudah diterima
    remaining_quantity NUMERIC(19, 4) GENERATED ALWAYS AS (quantity - received_quantity) STORED, -- Kuantitas sisa yang belum diterima
    notes TEXT
);
COMMENT ON TABLE PurchaseOrderItems IS 'Tabel detail untuk item dalam setiap PO.';
CREATE INDEX idx_poitems_po_id ON PurchaseOrderItems(po_id);

CREATE TABLE GRNItems (
    grn_item_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    grn_id UUID NOT NULL REFERENCES GoodReceiptNotes(grn_id) ON DELETE CASCADE, -- Foreign Key ke GoodReceiptNotes
    po_item_id UUID REFERENCES PurchaseOrderItems(po_item_id), -- Foreign Key ke PO Item jika terkait PO
    item_id UUID NOT NULL REFERENCES Items(item_id), -- Foreign Key ke Items
    quantity NUMERIC(19, 4) NOT NULL CHECK (quantity > 0), -- Kuantitas yang diterima
    bin_id UUID REFERENCES Bins(bin_id), -- Lokasi spesifik dalam gudang tempat barang disimpan
    serial_number VARCHAR(100), -- Nomor seri barang (jika berlaku)
    batch_number VARCHAR(100), -- Nomor batch barang (jika berlaku)
    quality_status VARCHAR(50) -- Status kualitas (misalnya 'Good', 'Damaged')
);
COMMENT ON TABLE GRNItems IS 'Tabel detail untuk item dalam setiap GRN.';
CREATE INDEX idx_grnitems_grn_id ON GRNItems(grn_id);
CREATE INDEX idx_grnitems_item_id ON GRNItems(item_id);

CREATE TABLE PurchaseInvoiceItems (
    pi_item_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pi_id UUID NOT NULL REFERENCES PurchaseInvoices(pi_id) ON DELETE CASCADE, -- Foreign Key ke PurchaseInvoices
    item_id UUID NOT NULL REFERENCES Items(item_id), -- Foreign Key ke Items
    quantity NUMERIC(19, 4) NOT NULL CHECK (quantity > 0), -- Kuantitas di invoice
    unit_price NUMERIC(19, 4) NOT NULL CHECK (unit_price >= 0), -- Harga per unit di invoice
    line_total NUMERIC(19, 4) GENERATED ALWAYS AS (quantity * unit_price) STORED -- Total per baris
);
COMMENT ON TABLE PurchaseInvoiceItems IS 'Tabel detail untuk item dalam setiap PI.';
CREATE INDEX idx_piitems_pi_id ON PurchaseInvoiceItems(pi_id);

CREATE TABLE APPayments (
    ap_payment_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ap_id UUID NOT NULL REFERENCES AccountsPayables(ap_id) ON DELETE CASCADE, -- Foreign Key ke AccountsPayables
    payment_date DATE NOT NULL DEFAULT CURRENT_DATE, -- Tanggal pembayaran
    amount NUMERIC(19, 4) NOT NULL CHECK (amount > 0), -- Jumlah pembayaran
    currency_id UUID NOT NULL REFERENCES Currencies(currency_id), -- Mata uang pembayaran
    exchange_rate NUMERIC(19, 6) NOT NULL DEFAULT 1, -- Kurs pada saat pembayaran
    payment_method VARCHAR(50), -- Metode pembayaran (misalnya 'Bank Transfer', 'Cash')
    reference_number VARCHAR(100), -- Nomor referensi pembayaran (misalnya nomor transaksi bank)
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE APPayments IS 'Tabel untuk mencatat pembayaran ke supplier.';
CREATE INDEX idx_appayments_ap_id ON APPayments(ap_id);

CREATE TABLE LandedCostComponents (
    lc_component_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    lc_voucher_id UUID NOT NULL REFERENCES LandedCostVouchers(lc_voucher_id) ON DELETE CASCADE, -- Foreign Key ke LandedCostVouchers
    cost_type VARCHAR(100) NOT NULL, -- Tipe biaya (misalnya 'Freight', 'Insurance', 'Customs Duty')
    amount NUMERIC(19, 4) NOT NULL CHECK (amount >= 0), -- Jumlah biaya komponen
    currency_id UUID NOT NULL REFERENCES Currencies(currency_id), -- Mata uang biaya komponen
    exchange_rate NUMERIC(19, 6) NOT NULL DEFAULT 1, -- Kurs pada saat pencatatan biaya
    notes TEXT
);
COMMENT ON TABLE LandedCostComponents IS 'Tabel detail untuk komponen biaya dalam Landed Cost.';
CREATE INDEX idx_lc_components_lc_voucher_id ON LandedCostComponents(lc_voucher_id);

CREATE TABLE LandedCostItemAllocations (
    lc_allocation_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    lc_voucher_id UUID NOT NULL REFERENCES LandedCostVouchers(lc_voucher_id) ON DELETE CASCADE, -- Foreign Key ke LandedCostVouchers
    pi_item_id UUID NOT NULL REFERENCES PurchaseInvoiceItems(pi_item_id) ON DELETE CASCADE, -- Foreign Key ke PurchaseInvoiceItems
    allocated_amount NUMERIC(19, 4) NOT NULL CHECK (allocated_amount >= 0) -- Jumlah biaya yang dialokasikan ke item ini
);
COMMENT ON TABLE LandedCostItemAllocations IS 'Tabel untuk mengalokasikan biaya Landed Cost ke setiap item.';
CREATE INDEX idx_lc_allocations_lc_voucher_id ON LandedCostItemAllocations(lc_voucher_id);

CREATE TABLE SalesQuotationItems (
    sq_item_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sq_id UUID NOT NULL REFERENCES SalesQuotations(sq_id) ON DELETE CASCADE, -- Foreign Key ke SalesQuotations
    item_id UUID NOT NULL REFERENCES Items(item_id), -- Foreign Key ke Items
    quantity NUMERIC(19, 4) NOT NULL CHECK (quantity > 0), -- Kuantitas yang ditawarkan
    unit_price NUMERIC(19, 4) NOT NULL CHECK (unit_price >= 0), -- Harga per unit
    discount_percentage NUMERIC(5, 2) DEFAULT 0 CHECK (discount_percentage >= 0 AND discount_percentage <= 100), -- Persentase diskon
    line_total NUMERIC(19, 4) GENERATED ALWAYS AS (quantity * unit_price * (1 - discount_percentage / 100)) STORED, -- Total per baris setelah diskon
    notes TEXT
);
COMMENT ON TABLE SalesQuotationItems IS 'Tabel detail untuk item dalam setiap SQ.';
CREATE INDEX idx_sales_sqitems_sq_id ON SalesQuotationItems(sq_id);

CREATE TABLE SalesOrderItems (
    so_item_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    so_id UUID NOT NULL REFERENCES SalesOrders(so_id) ON DELETE CASCADE, -- Foreign Key ke SalesOrders
    item_id UUID NOT NULL REFERENCES Items(item_id), -- Foreign Key ke Items
    quantity NUMERIC(19, 4) NOT NULL CHECK (quantity > 0), -- Kuantitas yang dipesan
    unit_price NUMERIC(19, 4) NOT NULL CHECK (unit_price >= 0), -- Harga per unit
    delivered_quantity NUMERIC(19, 4) DEFAULT 0, -- Kuantitas yang sudah dikirim
    remaining_quantity NUMERIC(19, 4) GENERATED ALWAYS AS (quantity - delivered_quantity) STORED, -- Kuantitas sisa yang belum dikirim
    stock_allocated_quantity NUMERIC(19, 4) DEFAULT 0, -- Kuantitas yang sudah dialokasikan dari stok
    notes TEXT
);
COMMENT ON TABLE SalesOrderItems IS 'Tabel detail untuk item dalam setiap SO.';
CREATE INDEX idx_sales_soitems_so_id ON SalesOrderItems(so_id);

CREATE TABLE DeliveryNoteItems (
    dn_item_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    dn_id UUID NOT NULL REFERENCES DeliveryNotes(dn_id) ON DELETE CASCADE, -- Foreign Key ke DeliveryNotes
    so_item_id UUID REFERENCES SalesOrderItems(so_item_id), -- Foreign Key ke SO Item
    item_id UUID NOT NULL REFERENCES Items(item_id), -- Foreign Key ke Items
    quantity NUMERIC(19, 4) NOT NULL CHECK (quantity > 0), -- Kuantitas yang dikirim
    bin_id UUID REFERENCES Bins(bin_id), -- Lokasi spesifik dalam gudang asal
    serial_number VARCHAR(100), -- Nomor seri barang (jika berlaku)
    batch_number VARCHAR(100), -- Nomor batch barang (jika berlaku)
    notes TEXT
);
COMMENT ON TABLE DeliveryNoteItems IS 'Tabel detail untuk item dalam setiap DN.';
CREATE INDEX idx_dnitems_dn_id ON DeliveryNoteItems(dn_id);
CREATE INDEX idx_dnitems_item_id ON DeliveryNoteItems(item_id);

CREATE TABLE SalesInvoiceItems (
    si_item_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    si_id UUID NOT NULL REFERENCES SalesInvoices(si_id) ON DELETE CASCADE, -- Foreign Key ke SalesInvoices
    item_id UUID NOT NULL REFERENCES Items(item_id), -- Foreign Key ke Items
    quantity NUMERIC(19, 4) NOT NULL CHECK (quantity > 0), -- Kuantitas di invoice
    unit_price NUMERIC(19, 4) NOT NULL CHECK (unit_price >= 0), -- Harga per unit di invoice
    discount_amount NUMERIC(19, 4) DEFAULT 0, -- Jumlah diskon per baris
    line_total NUMERIC(19, 4) GENERATED ALWAYS AS ((quantity * unit_price) - discount_amount) STORED -- Total per baris setelah diskon
);
COMMENT ON TABLE SalesInvoiceItems IS 'Tabel detail untuk item dalam setiap SI.';
CREATE INDEX idx_siitems_si_id ON SalesInvoiceItems(si_id);

CREATE TABLE ARPayments (
    ar_payment_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ar_id UUID NOT NULL REFERENCES AccountsReceivables(ar_id) ON DELETE CASCADE, -- Foreign Key ke AccountsReceivables
    payment_date DATE NOT NULL DEFAULT CURRENT_DATE, -- Tanggal pembayaran
    amount NUMERIC(19, 4) NOT NULL CHECK (amount > 0), -- Jumlah pembayaran
    currency_id UUID NOT NULL REFERENCES Currencies(currency_id), -- Mata uang pembayaran
    exchange_rate NUMERIC(19, 6) NOT NULL DEFAULT 1, -- Kurs pada saat pembayaran
    payment_method VARCHAR(50), -- Metode pembayaran
    reference_number VARCHAR(100), -- Nomor referensi pembayaran
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE ARPayments IS 'Tabel untuk mencatat pembayaran dari pelanggan.';
CREATE INDEX idx_arpayments_ar_id ON ARPayments(ar_id);

CREATE TABLE SalesReturnItems (
    sr_item_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sr_id UUID NOT NULL REFERENCES SalesReturns(sr_id) ON DELETE CASCADE, -- Foreign Key ke SalesReturns
    item_id UUID NOT NULL REFERENCES Items(item_id), -- Foreign Key ke Items
    quantity NUMERIC(19, 4) NOT NULL CHECK (quantity > 0), -- Kuantitas yang dikembalikan
    returned_condition VARCHAR(50), -- Kondisi barang yang dikembalikan (misalnya 'Good', 'Damaged', 'Defective')
    bin_id UUID REFERENCES Bins(bin_id), -- Lokasi gudang tempat barang dikembalikan
    notes TEXT
);
COMMENT ON TABLE SalesReturnItems IS 'Tabel detail untuk item dalam setiap Sales Return.';
CREATE INDEX idx_sritems_sr_id ON SalesReturnItems(sr_id);
CREATE INDEX idx_sritems_item_id ON SalesReturnItems(item_id);

CREATE TABLE StockEntryItems (
    stock_entry_item_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    stock_entry_id UUID NOT NULL REFERENCES StockEntries(stock_entry_id) ON DELETE CASCADE, -- Foreign Key ke StockEntries
    item_id UUID NOT NULL REFERENCES Items(item_id), -- Foreign Key ke Items
    quantity NUMERIC(19, 4) NOT NULL, -- Kuantitas yang terpengaruh (bisa positif/negatif)
    from_bin_id UUID REFERENCES Bins(bin_id), -- Bin asal
    to_bin_id UUID REFERENCES Bins(bin_id), -- Bin tujuan
    serial_number VARCHAR(100), -- Nomor seri (jika berlaku)
    batch_number VARCHAR(100), -- Nomor batch (jika berlaku)
    notes TEXT
);
COMMENT ON TABLE StockEntryItems IS 'Tabel detail untuk item dalam setiap entry stok.';
CREATE INDEX idx_stockentryitems_entry_id ON StockEntryItems(stock_entry_id);
CREATE INDEX idx_stockentryitems_item_id ON StockEntryItems(item_id);

CREATE TABLE StockReconciliationItems (
    recon_item_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    recon_id UUID NOT NULL REFERENCES StockReconciliations(recon_id) ON DELETE CASCADE, -- Foreign Key ke StockReconciliations
    item_id UUID NOT NULL REFERENCES Items(item_id), -- Foreign Key ke Items
    bin_id UUID REFERENCES Bins(bin_id), -- Bin tempat item dihitung
    system_quantity NUMERIC(19, 4) NOT NULL, -- Kuantitas menurut sistem
    counted_quantity NUMERIC(19, 4) NOT NULL, -- Kuantitas hasil penghitungan fisik
    difference NUMERIC(19, 4) GENERATED ALWAYS AS (counted_quantity - system_quantity) STORED, -- Perbedaan antara sistem dan hitungan fisik
    notes TEXT
);
COMMENT ON TABLE StockReconciliationItems IS 'Tabel detail untuk item dalam setiap rekonsiliasi stok.';
CREATE INDEX idx_reconitems_recon_id ON StockReconciliationItems(recon_id);

CREATE TABLE JournalEntryAccounts (
    journal_account_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    journal_id UUID NOT NULL REFERENCES JournalEntries(journal_id) ON DELETE CASCADE, -- Foreign Key ke JournalEntries
    account_id UUID NOT NULL REFERENCES ChartOfAccounts(account_id), -- Foreign Key ke ChartOfAccounts
    debit NUMERIC(19, 4) DEFAULT 0 CHECK (debit >= 0), -- Jumlah debit
    credit NUMERIC(19, 4) DEFAULT 0 CHECK (credit >= 0), -- Jumlah kredit
    currency_id UUID NOT NULL REFERENCES Currencies(currency_id), -- Mata uang transaksi
    exchange_rate NUMERIC(19, 6) NOT NULL DEFAULT 1, -- Kurs pada saat transaksi
    notes TEXT,
    -- Memastikan salah satu debit atau credit harus diisi dan total debit = total credit (dikelola di aplikasi/trigger)
    CONSTRAINT chk_debit_credit CHECK (debit > 0 OR credit > 0)
);
COMMENT ON TABLE JournalEntryAccounts IS 'Tabel detail untuk akun-akun dalam setiap entri jurnal.';
CREATE INDEX idx_journalentry_accounts_journal_id ON JournalEntryAccounts(journal_id);
CREATE INDEX idx_journalentry_accounts_account_id ON JournalEntryAccounts(account_id);

CREATE TABLE BankReconciliationEntries (
    reconciliation_entry_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    bank_transaction_id UUID NOT NULL REFERENCES BankTransactions(bank_transaction_id) ON DELETE CASCADE, -- Foreign Key ke BankTransactions
    journal_entry_id UUID NOT NULL REFERENCES JournalEntries(journal_id) ON DELETE CASCADE, -- Foreign Key ke JournalEntries
    reconciliation_date DATE NOT NULL DEFAULT CURRENT_DATE, -- Tanggal rekonsiliasi
    amount_matched NUMERIC(19, 4) NOT NULL, -- Jumlah yang dicocokkan
    UNIQUE (bank_transaction_id, journal_entry_id) -- Mencegah duplikasi rekonsiliasi untuk pasangan yang sama
);
COMMENT ON TABLE BankReconciliationEntries IS 'Tabel untuk mencocokkan transaksi bank dengan entri jurnal.';
CREATE INDEX idx_bank_recon_journal_id ON BankReconciliationEntries(journal_entry_id);

CREATE TABLE AssetDepreciations (
    depreciation_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    asset_id UUID NOT NULL REFERENCES Assets(asset_id) ON DELETE CASCADE, -- Foreign Key ke Assets
    depreciation_date DATE NOT NULL, -- Tanggal depresiasi
    depreciation_amount NUMERIC(19, 4) NOT NULL CHECK (depreciation_amount >= 0), -- Jumlah depresiasi
    period VARCHAR(50), -- Periode depresiasi (misalnya 'Monthly', 'Annually')
    journal_id UUID REFERENCES JournalEntries(journal_id), -- Foreign Key ke JournalEntries (jika jurnal otomatis dibuat)
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE AssetDepreciations IS 'Mencatat perhitungan depresiasi untuk aset tetap.';
CREATE INDEX idx_asset_depreciation_asset_date ON AssetDepreciations(asset_id, depreciation_date);

CREATE TABLE TaxTransactions (
    tax_transaction_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tax_rate_id UUID NOT NULL REFERENCES TaxRates(tax_rate_id), -- Foreign Key ke TaxRates
    document_type VARCHAR(50) NOT NULL, -- Tipe dokumen terkait (misalnya 'PurchaseInvoice', 'SalesInvoice')
    document_id UUID NOT NULL, -- ID dokumen terkait
    amount NUMERIC(19, 4) NOT NULL, -- Jumlah pajak yang dikenakan
    transaction_date DATE NOT NULL DEFAULT CURRENT_DATE, -- Tanggal transaksi pajak
    journal_id UUID REFERENCES JournalEntries(journal_id), -- Foreign Key ke JournalEntries (jika jurnal otomatis dibuat)
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE TaxTransactions IS 'Mencatat transaksi pajak yang terkait dengan dokumen bisnis.';
CREATE INDEX idx_tax_transactions_doc ON TaxTransactions(document_type, document_id);

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

CREATE TABLE SerialNumbers (
    serial_number_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    serial_number VARCHAR(255) UNIQUE NOT NULL, -- Nomor seri unik
    item_id UUID NOT NULL REFERENCES Items(item_id), -- Foreign Key ke Items
    grn_item_id UUID REFERENCES GRNItems(grn_item_id), -- Dari GRN item mana nomor seri ini diterima
    current_warehouse_id UUID NOT NULL REFERENCES Warehouses(warehouse_id), -- Gudang saat ini
    current_bin_id UUID REFERENCES Bins(bin_id), -- Bin saat ini
    status VARCHAR(50) NOT NULL DEFAULT 'Available', -- Status (e.g., 'Available', 'Sold', 'In Transit', 'Defective')
    last_moved_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP, -- Waktu terakhir pergerakan
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE SerialNumbers IS 'Melacak setiap unit barang dengan nomor seri unik.';
CREATE INDEX idx_serialnumbers_serial_number ON SerialNumbers(serial_number);
CREATE INDEX idx_serialnumbers_item_id ON SerialNumbers(item_id);

CREATE TABLE Batches (
    batch_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    batch_number VARCHAR(255) UNIQUE NOT NULL, -- Nomor batch unik
    item_id UUID NOT NULL REFERENCES Items(item_id), -- Foreign Key ke Items
    grn_item_id UUID REFERENCES GRNItems(grn_item_id), -- Dari GRN item mana batch ini diterima
    manufacture_date DATE, -- Tanggal produksi
    expiry_date DATE, -- Tanggal kadaluarsa
    initial_quantity NUMERIC(19, 4) NOT NULL CHECK (initial_quantity > 0), -- Kuantitas awal batch
    current_quantity NUMERIC(19, 4) NOT NULL DEFAULT 0, -- Kuantitas batch saat ini
    current_warehouse_id UUID NOT NULL REFERENCES Warehouses(warehouse_id), -- Gudang saat ini
    current_bin_id UUID REFERENCES Bins(bin_id), -- Bin saat ini
    status VARCHAR(50) NOT NULL DEFAULT 'Available', -- Status (e.g., 'Available', 'Consumed', 'Expired')
    last_updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE Batches IS 'Melacak kelompok barang dengan nomor batch.';
CREATE INDEX idx_batches_batch_number ON Batches(batch_number);
CREATE INDEX idx_batches_item_id ON Batches(item_id);
