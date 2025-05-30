-- Sales Quotation (SQ)
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

-- Sales Order (SO)
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

-- Delivery Note (DN)
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

-- Sales Invoice (SI)
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

-- Accounts Receivable (AR)
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

-- Manajemen Diskon & Promosi
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

-- Manajemen Pengembalian Barang (Sales Return)
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