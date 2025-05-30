-- General Ledger (GL)
CREATE TABLE AccountTypes (
    account_type_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    type_name VARCHAR(50) UNIQUE NOT NULL, -- Tipe akun (misalnya 'Asset', 'Liability', 'Equity', 'Revenue', 'Expense')
    classification VARCHAR(50) NOT NULL CHECK (classification IN ('Balance Sheet', 'Profit and Loss')) -- Klasifikasi laporan keuangan
);
COMMENT ON TABLE AccountTypes IS 'Master data untuk tipe akun GL.';

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

-- Bank Reconciliation
CREATE TABLE BankAccounts (
    bank_account_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    bank_name VARCHAR(100) NOT NULL, -- Nama bank
    account_number VARCHAR(100) UNIQUE NOT NULL, -- Nomor rekening bank
    account_name VARCHAR(100), -- Nama pemilik rekening
    currency_id UUID NOT NULL REFERENCES Currencies(currency_id), -- Mata uang rekening
    initial_balance NUMERIC(19, 4) DEFAULT 0 -- Saldo awal rekening
);
COMMENT ON TABLE BankAccounts IS 'Master data untuk rekening bank perusahaan.';

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

-- Manajemen Biaya Operasional (Expense)
CREATE TABLE ExpenseCategories (
    category_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    category_name VARCHAR(100) UNIQUE NOT NULL, -- Nama kategori pengeluaran
    description TEXT,
    default_gl_account_id UUID REFERENCES ChartOfAccounts(account_id) -- Akun GL default untuk kategori ini
);
COMMENT ON TABLE ExpenseCategories IS 'Master data untuk kategori pengeluaran.';

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

-- Manajemen Aset Tetap (Asset)
CREATE TABLE AssetCategories (
    category_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    category_name VARCHAR(100) UNIQUE NOT NULL, -- Nama kategori aset
    description TEXT,
    default_depreciation_account_id UUID REFERENCES ChartOfAccounts(account_id) -- Akun GL default untuk depresiasi
);
COMMENT ON TABLE AssetCategories IS 'Master data untuk kategori aset tetap.';

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

-- Pajak & Bea Cukai
CREATE TABLE TaxAuthorities (
    authority_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    authority_name VARCHAR(100) UNIQUE NOT NULL -- Nama otoritas pajak (misalnya 'Ditjen Pajak')
);
COMMENT ON TABLE TaxAuthorities IS 'Master data untuk otoritas pajak.';

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