-- Laporan Kustom / Ad-hoc Reporting
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

-- Dashboard Management (Tabel ini opsional, tergantung bagaimana Anda mengimplementasikan dashboard)
-- Agregasi KPI biasanya dihitung secara dinamis dari tabel transaksional,
-- tetapi bisa juga disimpan di tabel terpisah jika komputasinya berat atau perlu historis.
CREATE TABLE KPIAggregations (
    kpi_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    kpi_name VARCHAR(100) UNIQUE NOT NULL, -- Nama KPI (misalnya 'Total Penjualan', 'Nilai Stok')
    aggregation_interval VARCHAR(50), -- Interval agregasi (misalnya 'Daily', 'Weekly', 'Monthly')
    last_computed_at TIMESTAMP WITH TIME ZONE, -- Waktu terakhir KPI dihitung
    definition JSONB -- Bagaimana KPI ini dihitung (misalnya, SQL query atau formula)
);
COMMENT ON TABLE KPIAggregations IS 'Master data untuk definisi Key Performance Indicators (KPIs).';

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