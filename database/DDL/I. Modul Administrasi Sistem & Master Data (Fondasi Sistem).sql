-- Skema: public (default)
-- Ekstensi yang mungkin dibutuhkan:
-- CREATE EXTENSION IF NOT EXISTS "uuid-ossp"; -- Jika Anda ingin menggunakan uuid_generate_v4()
-- CREATE EXTENSION IF NOT EXISTS "pgcrypto"; -- Untuk gen_random_uuid()

-- Tabel Pengguna & Hak Akses
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

-- Audit Trail
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

-- Master Data Barang
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

-- Master Data Pelanggan
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

-- Master Data Vendor
CREATE TABLE SupplierGroups (
    supplier_group_id UUID PRIMARY KEY DEFAULT gen_random_uuid(), -- ID unik grup supplier
    group_name VARCHAR(100) UNIQUE NOT NULL, -- Nama grup supplier
    description TEXT -- Deskripsi grup
);
COMMENT ON TABLE SupplierGroups IS 'Master data untuk kategori atau grup supplier.';

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

-- Master Data Gudang & Lokasi
CREATE TABLE Warehouses (
    warehouse_id UUID PRIMARY KEY DEFAULT gen_random_uuid(), -- ID unik gudang
    warehouse_name VARCHAR(100) UNIQUE NOT NULL, -- Nama gudang
    address TEXT, -- Alamat gudang
    is_active BOOLEAN DEFAULT TRUE
);
COMMENT ON TABLE Warehouses IS 'Master data untuk gudang.';

CREATE TABLE Bins (
    bin_id UUID PRIMARY KEY DEFAULT gen_random_uuid(), -- ID unik lokasi bin
    warehouse_id UUID NOT NULL REFERENCES Warehouses(warehouse_id) ON DELETE CASCADE, -- Foreign Key ke Warehouses
    bin_code VARCHAR(50) NOT NULL, -- Kode bin (misalnya 'A-01-01')
    description TEXT,
    UNIQUE (warehouse_id, bin_code) -- Memastikan kode bin unik dalam satu gudang
);
COMMENT ON TABLE Bins IS 'Master data untuk lokasi spesifik dalam gudang (rak, lorong, bin).';
CREATE INDEX idx_bins_warehouse_id ON Bins(warehouse_id);

-- Manajemen Mata Uang & Kurs
CREATE TABLE Currencies (
    currency_id UUID PRIMARY KEY DEFAULT gen_random_uuid(), -- ID unik mata uang
    currency_code VARCHAR(3) UNIQUE NOT NULL, -- Kode mata uang (misalnya 'USD', 'JPY', 'IDR')
    currency_name VARCHAR(50) NOT NULL, -- Nama mata uang
    symbol VARCHAR(10) -- Simbol mata uang (misalnya '$', '¥', 'Rp')
);
COMMENT ON TABLE Currencies IS 'Master data untuk mata uang yang didukung.';

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