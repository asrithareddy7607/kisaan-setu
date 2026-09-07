-- ============================================================================
-- KisanSetu Production Supabase Database Schema
-- Architecture: Row Level Security (RLS), Realtime replication, Audit logging
-- ============================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. USERS & PROFILES
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    phone VARCHAR(15) UNIQUE NOT NULL,
    role VARCHAR(20) NOT NULL CHECK (role IN ('farmer', 'officer', 'admin')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. FARMERS
CREATE TABLE IF NOT EXISTS farmers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    full_name VARCHAR(100) NOT NULL,
    phone VARCHAR(15) NOT NULL,
    aadhaar_mask VARCHAR(14) NOT NULL, -- e.g. "XXXX-XXXX-8921"
    state VARCHAR(50) NOT NULL,
    district VARCHAR(50) NOT NULL,
    mandal VARCHAR(50) NOT NULL,
    village VARCHAR(50) NOT NULL,
    bank_account_mask VARCHAR(20) NOT NULL, -- e.g. "XXXXXX4512"
    ifsc_code VARCHAR(15) NOT NULL,
    bank_name VARCHAR(100),
    preferred_language VARCHAR(10) DEFAULT 'en' CHECK (preferred_language IN ('en', 'te', 'hi')),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. LAND RECORDS (Passbook & Surveys)
CREATE TABLE IF NOT EXISTS land_records (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    farmer_id UUID REFERENCES farmers(id) ON DELETE CASCADE,
    passbook_number VARCHAR(50) NOT NULL, -- e.g. "T192837465"
    khata_number VARCHAR(50) NOT NULL,
    survey_number VARCHAR(50) NOT NULL, -- e.g. "142/A"
    extent_acres NUMERIC(6, 2) NOT NULL,
    state VARCHAR(50) NOT NULL,
    district VARCHAR(50) NOT NULL,
    mandal VARCHAR(50) NOT NULL,
    village VARCHAR(50) NOT NULL,
    passbook_doc_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. LAND VERIFICATIONS (Govt API Integration Layer)
CREATE TABLE IF NOT EXISTS land_verifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    land_record_id UUID REFERENCES land_records(id) ON DELETE CASCADE,
    farmer_id UUID REFERENCES farmers(id) ON DELETE CASCADE,
    verification_status VARCHAR(20) NOT NULL DEFAULT 'Pending' 
        CHECK (verification_status IN ('Pending', 'Verified', 'Rejected', 'Unavailable')),
    verification_source VARCHAR(50) NOT NULL, -- 'Dharani', 'Meebhoomi', 'Bhulekh', 'Agristack', 'ConfiguredGovtRoR'
    api_response_code VARCHAR(50),
    remarks TEXT,
    verified_at TIMESTAMPTZ,
    verified_by VARCHAR(50) DEFAULT 'Govt-API-Gateway',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. CROPS & MSP MASTER
CREATE TABLE IF NOT EXISTS crops (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    crop_code VARCHAR(30) UNIQUE NOT NULL,
    crop_name VARCHAR(100) NOT NULL,
    crop_name_te VARCHAR(100),
    crop_name_hi VARCHAR(100),
    category VARCHAR(50) NOT NULL, -- Cereals, Pulses, Commercial, Oilseeds
    msp_rate_per_quintal NUMERIC(10, 2) NOT NULL,
    max_moisture_percentage NUMERIC(4, 2) DEFAULT 17.0,
    active_season VARCHAR(20) DEFAULT 'Kharif 2025-26',
    is_active BOOLEAN DEFAULT TRUE
);

-- 6. CROP REGISTRATIONS
CREATE TABLE IF NOT EXISTS crop_registrations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    farmer_id UUID REFERENCES farmers(id) ON DELETE CASCADE,
    land_record_id UUID REFERENCES land_records(id),
    crop_id UUID REFERENCES crops(id),
    season VARCHAR(30) NOT NULL,
    estimated_quintals NUMERIC(8, 2) NOT NULL,
    bags_count INTEGER,
    preferred_centre_type VARCHAR(20) DEFAULT 'Any',
    status VARCHAR(30) DEFAULT 'Active' CHECK (status IN ('Active', 'Scheduled', 'Procured', 'Cancelled')),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 7. PROCUREMENT CENTRES (FCI, Markfed, PACS, and Local IKP Centres)
CREATE TABLE IF NOT EXISTS procurement_centres (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    centre_code VARCHAR(30) UNIQUE NOT NULL,
    name VARCHAR(150) NOT NULL,
    name_te VARCHAR(150),
    name_hi VARCHAR(150),
    centre_type VARCHAR(20) NOT NULL CHECK (centre_type IN ('IKP', 'FCI', 'Markfed', 'PACS')),
    district VARCHAR(50) NOT NULL,
    mandal VARCHAR(50) NOT NULL,
    address TEXT NOT NULL,
    contact_number VARCHAR(15),
    latitude NUMERIC(10, 6) NOT NULL,
    longitude NUMERIC(10, 6) NOT NULL,
    daily_capacity_quintals NUMERIC(10, 2) DEFAULT 2000.0,
    current_load_quintals NUMERIC(10, 2) DEFAULT 0.0,
    current_queue_count INTEGER DEFAULT 0,
    avg_processing_mins INTEGER DEFAULT 20,
    operating_status VARCHAR(20) DEFAULT 'Open' CHECK (operating_status IN ('Open', 'Paused', 'Full', 'Closed')),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 8. SCHEDULES & SLOTS
CREATE TABLE IF NOT EXISTS schedules (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    centre_id UUID REFERENCES procurement_centres(id) ON DELETE CASCADE,
    schedule_date DATE NOT NULL,
    status VARCHAR(20) DEFAULT 'Active',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(centre_id, schedule_date)
);

CREATE TABLE IF NOT EXISTS slots (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    schedule_id UUID REFERENCES schedules(id) ON DELETE CASCADE,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    max_tokens INTEGER DEFAULT 25,
    booked_tokens INTEGER DEFAULT 0,
    status VARCHAR(20) DEFAULT 'Available' CHECK (status IN ('Available', 'FastFilling', 'Full', 'Blocked'))
);

-- 9. DIGITAL TOKENS & QUEUES
CREATE TABLE IF NOT EXISTS tokens (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    token_number VARCHAR(50) UNIQUE NOT NULL, -- e.g. "KS-2026-IKP-0482"
    farmer_id UUID REFERENCES farmers(id) ON DELETE CASCADE,
    crop_registration_id UUID REFERENCES crop_registrations(id),
    centre_id UUID REFERENCES procurement_centres(id),
    slot_id UUID REFERENCES slots(id),
    token_date DATE NOT NULL,
    vehicle_type VARCHAR(50) DEFAULT 'Tractor', -- Tractor, Mini Truck, Bullock Cart, Auto
    vehicle_number VARCHAR(20),
    status VARCHAR(30) DEFAULT 'Generated' 
        CHECK (status IN ('Generated', 'Arrived', 'Called', 'QualityCheck', 'Weighing', 'Procured', 'Completed', 'Cancelled', 'NoShow')),
    position_in_queue INTEGER,
    estimated_wait_mins INTEGER DEFAULT 30,
    qr_code_hash TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS queues (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    centre_id UUID REFERENCES procurement_centres(id) ON DELETE CASCADE UNIQUE,
    current_token_id UUID REFERENCES tokens(id),
    current_token_number VARCHAR(50),
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'paused', 'stopped')),
    total_served_today INTEGER DEFAULT 0,
    last_called_at TIMESTAMPTZ
);

-- 10. PROCUREMENT RECORDS, QUALITY & WEIGHING
CREATE TABLE IF NOT EXISTS procurement_records (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    token_id UUID REFERENCES tokens(id) UNIQUE,
    farmer_id UUID REFERENCES farmers(id),
    centre_id UUID REFERENCES procurement_centres(id),
    crop_id UUID REFERENCES crops(id),
    officer_id UUID REFERENCES users(id),
    status VARCHAR(30) DEFAULT 'Registered' 
        CHECK (status IN ('Registered', 'Verified', 'Scheduled', 'Token', 'Arrived', 'QualityCheck', 'Weighing', 'Procured', 'PaymentProcessing', 'Paid')),
    receipt_number VARCHAR(50) UNIQUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS quality_checks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    procurement_record_id UUID REFERENCES procurement_records(id) ON DELETE CASCADE,
    moisture_percentage NUMERIC(4, 2) NOT NULL,
    foreign_matter_percentage NUMERIC(4, 2) DEFAULT 1.0,
    broken_grains_percentage NUMERIC(4, 2) DEFAULT 2.0,
    faq_grade VARCHAR(20) NOT NULL CHECK (faq_grade IN ('Grade A', 'Common', 'Below FAQ')),
    is_accepted BOOLEAN DEFAULT TRUE,
    remarks TEXT,
    inspected_by VARCHAR(100),
    inspected_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS weighing_records (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    procurement_record_id UUID REFERENCES procurement_records(id) ON DELETE CASCADE,
    gross_weight_qtl NUMERIC(8, 2) NOT NULL,
    tare_weight_qtl NUMERIC(8, 2) NOT NULL,
    net_weight_qtl NUMERIC(8, 2) NOT NULL,
    bags_count INTEGER NOT NULL,
    weight_slip_number VARCHAR(50) UNIQUE NOT NULL,
    weighed_at TIMESTAMPTZ DEFAULT NOW()
);

-- 11. PAYMENTS & DIRECT BENEFIT TRANSFER (DBT)
CREATE TABLE IF NOT EXISTS payments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    procurement_record_id UUID REFERENCES procurement_records(id) ON DELETE CASCADE,
    farmer_id UUID REFERENCES farmers(id),
    gross_amount NUMERIC(12, 2) NOT NULL,
    deductions_amount NUMERIC(10, 2) DEFAULT 0.0,
    net_payable_amount NUMERIC(12, 2) NOT NULL,
    payment_status VARCHAR(20) DEFAULT 'Pending' CHECK (payment_status IN ('Pending', 'Processing', 'Paid', 'Failed')),
    dbt_utr_number VARCHAR(50), -- Bank transaction UTR reference
    beneficiary_account_mask VARCHAR(20),
    ifsc_code VARCHAR(15),
    disbursed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 12. NOTIFICATIONS & SMS LOGS
CREATE TABLE IF NOT EXISTS notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id),
    phone VARCHAR(15) NOT NULL,
    title VARCHAR(150) NOT NULL,
    message TEXT NOT NULL,
    sms_status VARCHAR(20) DEFAULT 'Delivered' CHECK (sms_status IN ('Queued', 'Sent', 'Delivered', 'Failed')),
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 13. ANNOUNCEMENTS
CREATE TABLE IF NOT EXISTS announcements (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    centre_id UUID REFERENCES procurement_centres(id) ON DELETE CASCADE,
    title VARCHAR(150) NOT NULL,
    message TEXT NOT NULL,
    severity VARCHAR(20) DEFAULT 'Info' CHECK (severity IN ('Info', 'Warning', 'Emergency')),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 14. AUDIT LOGS
CREATE TABLE IF NOT EXISTS audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    entity_name VARCHAR(50) NOT NULL,
    entity_id UUID NOT NULL,
    action VARCHAR(50) NOT NULL,
    changed_by VARCHAR(100),
    old_state JSONB,
    new_state JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================================================

ALTER TABLE farmers ENABLE ROW LEVEL SECURITY;
ALTER TABLE land_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE land_verifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE crop_registrations ENABLE ROW LEVEL SECURITY;
ALTER TABLE tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Farmer can read own profile & records
CREATE POLICY "Farmers can read their own profile"
    ON farmers FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Farmers can read their own land records"
    ON land_records FOR SELECT
    USING (farmer_id IN (SELECT id FROM farmers WHERE user_id = auth.uid()));

CREATE POLICY "Farmers can read their own tokens"
    ON tokens FOR SELECT
    USING (farmer_id IN (SELECT id FROM farmers WHERE user_id = auth.uid()));

CREATE POLICY "Farmers can read their own payments"
    ON payments FOR SELECT
    USING (farmer_id IN (SELECT id FROM farmers WHERE user_id = auth.uid()));

-- Centres, Schedules, and Crops are readable by all authenticated users
ALTER TABLE procurement_centres ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Procurement centres readable by all"
    ON procurement_centres FOR SELECT
    TO authenticated, anon
    USING (true);

ALTER TABLE crops ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Crops catalog readable by all"
    ON crops FOR SELECT
    TO authenticated, anon
    USING (true);

-- Enable Supabase Realtime for live queues, tokens, and announcements
ALTER PUBLICATION supabase_realtime ADD TABLE queues, tokens, procurement_centres, announcements, notifications;

-- ============================================================================
-- SEED DATA: OFFICIAL CROPS (MSP 2025-26)
-- ============================================================================

INSERT INTO crops (crop_code, crop_name, crop_name_te, crop_name_hi, category, msp_rate_per_quintal, max_moisture_percentage)
VALUES 
('PADDY_GRA', 'Paddy (Grade A)', 'వరి (గ్రేడ్-ఎ)', 'धान (ग्रेड-ए)', 'Cereals', 2320.00, 17.0),
('PADDY_COM', 'Paddy (Common)', 'వరి (సాధారణ)', 'धान (सामान्य)', 'Cereals', 2300.00, 17.0),
('COTTON_MED', 'Cotton (Medium Staple)', 'పత్తి (మధ్యస్థ పింజ)', 'कपास (मध्यम रेशा)', 'Commercial', 7121.00, 12.0),
('COTTON_LNG', 'Cotton (Long Staple)', 'పత్తి (పొడవు పింజ)', 'कपास (लंबा रेशा)', 'Commercial', 7521.00, 12.0),
('MAIZE', 'Maize (Corn)', 'మొక్కజొన్న', 'मक्का', 'Cereals', 2225.00, 14.0),
('WHEAT', 'Wheat', 'గోధుమలు', 'गेहूं', 'Cereals', 2425.00, 12.0),
('BENGAL_GRAM', 'Bengal Gram (Chana)', 'శనగలు', 'चना', 'Pulses', 5650.00, 12.0),
('RED_GRAM', 'Red Gram (Tur/Arhar)', 'కందులు', 'अरहर / तूर', 'Pulses', 7550.00, 12.0),
('SOYBEAN', 'Soybean (Yellow)', 'సోయాబీన్', 'सोयाबीन', 'Oilseeds', 4892.00, 12.0),
('BAJRA', 'Bajra (Pearl Millet)', 'సజ్జలు', 'बाजरा', 'Millets', 2625.00, 14.0)
ON CONFLICT (crop_code) DO NOTHING;
