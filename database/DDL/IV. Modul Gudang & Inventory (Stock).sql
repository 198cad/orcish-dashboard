-- Stok Real-time (Ini adalah tabel utama untuk stok saat ini)
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

-- Stock Adjustment & Transfer (menggunakan satu tabel StockEntries dengan tipe yang berbeda)
CREATE TABLE StockEntryTypes (
    entry_type_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    type_name VARCHAR(50) UNIQUE NOT NULL, -- Tipe entry stok (misalnya 'Adjustment', 'Transfer', 'Production', 'Consumption')
    description TEXT
);
COMMENT ON TABLE StockEntryTypes IS 'Master data untuk tipe-tipe entry stok.';

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

-- Batch/Lot & Serial Number Tracking
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

-- Stock Take / Cycle Count
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

-- Reorder Point & Minimum Stock Level Alerts
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