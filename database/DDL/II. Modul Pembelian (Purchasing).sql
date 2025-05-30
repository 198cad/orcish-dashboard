-- Request for Quotation (RFQ)
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

-- Vendor Quotation (VQ)
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

-- Purchase Order (PO)
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

-- Good Receipt Note (GRN)
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

-- Purchase Invoice (PI)
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

-- Accounts Payable (AP)
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

-- Landed Cost Calculation
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