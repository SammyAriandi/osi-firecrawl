-- ============================================
-- COMPLETE DATABASE SCHEMA
-- PT Optima Smartindo Industry - Web Scraping System
-- ============================================

-- ============================================
-- SCHEMA: scraping
-- PURPOSE: Metadata job dan logs scraping
-- ============================================

CREATE SCHEMA IF NOT EXISTS scraping;

-- Table: Job History
CREATE TABLE IF NOT EXISTS scraping.job_history (
    job_id SERIAL PRIMARY KEY,
    job_name VARCHAR(255) NOT NULL,
    job_type VARCHAR(50) NOT NULL, -- 'price_monitoring' or 'lead_generation'
    status VARCHAR(50) DEFAULT 'pending', -- pending, processing, completed, failed
    target_url VARCHAR(2048) NOT NULL,
    target_domain VARCHAR(255),
    firecrawl_job_id VARCHAR(255),
    started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP,
    error_message TEXT,
    record_count INT DEFAULT 0,
    processing_duration_seconds INT,
    api_response JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Table: Scraping Logs
CREATE TABLE IF NOT EXISTS scraping.logs (
    log_id SERIAL PRIMARY KEY,
    job_id INT REFERENCES scraping.job_history(job_id) ON DELETE CASCADE,
    log_level VARCHAR(20), -- INFO, WARN, ERROR, DEBUG
    message TEXT,
    context JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Table: Configuration - Target URLs untuk Price Monitoring
CREATE TABLE IF NOT EXISTS scraping.price_monitoring_targets (
    target_id SERIAL PRIMARY KEY,
    website_name VARCHAR(255) NOT NULL,
    url_target VARCHAR(2048) NOT NULL,
    domain_name VARCHAR(255),
    category VARCHAR(100), -- e.commerce, marketplace, distributor
    priority INT DEFAULT 5, -- 1=highest, 10=lowest
    is_active BOOLEAN DEFAULT TRUE,
    last_scraped TIMESTAMP,
    next_scheduled TIMESTAMP,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(url_target)
);

-- Table: Configuration - Lead Source URLs
CREATE TABLE IF NOT EXISTS scraping.lead_generation_targets (
    target_id SERIAL PRIMARY KEY,
    source_name VARCHAR(255) NOT NULL,
    url_target VARCHAR(2048) NOT NULL,
    domain_name VARCHAR(255),
    category VARCHAR(100), -- directory, association, tender_portal
    crawl_depth INT DEFAULT 2,
    is_active BOOLEAN DEFAULT TRUE,
    last_crawled TIMESTAMP,
    next_scheduled TIMESTAMP,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(url_target)
);

-- Indexes untuk scraping schema
CREATE INDEX idx_job_status ON scraping.job_history(status);
CREATE INDEX idx_job_type ON scraping.job_history(job_type);
CREATE INDEX idx_job_domain ON scraping.job_history(target_domain);
CREATE INDEX idx_job_created ON scraping.job_history(created_at DESC);
CREATE INDEX idx_log_job_id ON scraping.logs(job_id);
CREATE INDEX idx_log_level ON scraping.logs(log_level);
CREATE INDEX idx_price_monitoring_active ON scraping.price_monitoring_targets(is_active);
CREATE INDEX idx_lead_generation_active ON scraping.lead_generation_targets(is_active);

-- ============================================
-- SCHEMA: erp
-- PURPOSE: Data produk dan leads untuk sistem ERP
-- ============================================

CREATE SCHEMA IF NOT EXISTS erp;

-- Table 1: Competitor Product Pricing
CREATE TABLE IF NOT EXISTS erp.competitor_products (
    product_id SERIAL PRIMARY KEY,
    source_website VARCHAR(255) NOT NULL, -- competitor domain
    source_url VARCHAR(2048),
    product_name VARCHAR(500) NOT NULL,
    brand VARCHAR(255),
    price_idr DECIMAL(12, 2),
    currency VARCHAR(10) DEFAULT 'IDR',
    product_category VARCHAR(255),
    specification JSONB, -- {"wattage": "10W", "color": "warmwhite", ...}
    availability_status VARCHAR(100), -- in_stock, out_of_stock, discontinued
    sku VARCHAR(100),
    product_url VARCHAR(2048),
    last_seen TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_price_change TIMESTAMP,
    previous_price_idr DECIMAL(12, 2),
    price_change_percent DECIMAL(5, 2),
    competitor_name VARCHAR(255),
    data_quality_score DECIMAL(3, 1) DEFAULT 5, -- 1-10
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    job_id INT REFERENCES scraping.job_history(job_id) ON DELETE SET NULL
);

-- Table 2: B2B Leads
CREATE TABLE IF NOT EXISTS erp.b2b_leads (
    lead_id SERIAL PRIMARY KEY,
    source_website VARCHAR(255) NOT NULL, -- lead aggregator domain
    company_name VARCHAR(500) NOT NULL,
    pic_name VARCHAR(255), -- Person in Charge
    pic_title VARCHAR(255), -- e.g., "Direktur", "Project Manager", "Manajer Proyek"
    phone_number VARCHAR(50),
    phone_alternative VARCHAR(50),
    email VARCHAR(255),
    email_alternative VARCHAR(255),
    company_address TEXT,
    city VARCHAR(100),
    province VARCHAR(100),
    postal_code VARCHAR(20),
    country VARCHAR(100) DEFAULT 'Indonesia',
    
    -- Company Details
    specialization JSONB, -- {"categories": ["Mekanikal", "Elektrikal"], "industries": [...]}
    company_website VARCHAR(255),
    business_registration_number VARCHAR(50), -- e.g., SIUP/TDP
    tax_number VARCHAR(50), -- NPWP
    estimated_company_size VARCHAR(50), -- SME, Enterprise, Corporation
    years_established INT,
    employee_count INT,
    annual_revenue_estimate DECIMAL(15, 0),
    
    -- Lead Management
    lead_quality_score DECIMAL(3, 1) DEFAULT 5, -- 1-10 score
    lead_status VARCHAR(50) DEFAULT 'new', -- new, contacted, qualified, negotiating, won, lost, archived
    assigned_to VARCHAR(255), -- Sales person name
    last_contacted TIMESTAMP,
    contact_attempts INT DEFAULT 0,
    next_followup TIMESTAMP,
    
    -- Additional Info
    notes TEXT,
    tags VARCHAR(255)[], -- Array of tags for filtering
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    job_id INT REFERENCES scraping.job_history(job_id) ON DELETE SET NULL
);

-- Table 3: Deduplication tracking (untuk prevent duplicate leads)
CREATE TABLE IF NOT EXISTS erp.lead_deduplication (
    dedup_id SERIAL PRIMARY KEY,
    lead_id INT REFERENCES erp.b2b_leads(lead_id) ON DELETE CASCADE,
    company_hash VARCHAR(100), -- hash of company name + city
    phone_hash VARCHAR(100), -- hash of phone number
    email_hash VARCHAR(100), -- hash of email
    source_references JSONB, -- {"original_id": "...", "similar_leads": [...]}
    is_primary BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Table 4: Data Sync Log
CREATE TABLE IF NOT EXISTS erp.data_sync_log (
    sync_id SERIAL PRIMARY KEY,
    data_type VARCHAR(50), -- 'competitor_products' or 'b2b_leads'
    total_records INT,
    inserted_records INT DEFAULT 0,
    updated_records INT DEFAULT 0,
    skipped_records INT DEFAULT 0,
    failed_records INT DEFAULT 0,
    sync_status VARCHAR(50), -- success, partial, failed
    error_details TEXT,
    sync_started_at TIMESTAMP,
    sync_ended_at TIMESTAMP,
    duration_seconds INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Table 5: Lead Contact History
CREATE TABLE IF NOT EXISTS erp.lead_contact_history (
    contact_id SERIAL PRIMARY KEY,
    lead_id INT REFERENCES erp.b2b_leads(lead_id) ON DELETE CASCADE,
    contact_method VARCHAR(50), -- phone, email, whatsapp, in_person
    contact_status VARCHAR(50), -- success, no_answer, busy, declined, interested
    notes TEXT,
    contacted_by VARCHAR(255),
    follow_up_required BOOLEAN DEFAULT FALSE,
    follow_up_date TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Indexes untuk erp schema - Performance optimization
CREATE INDEX idx_competitor_source ON erp.competitor_products(source_website);
CREATE INDEX idx_competitor_brand ON erp.competitor_products(brand);
CREATE INDEX idx_competitor_category ON erp.competitor_products(product_category);
CREATE INDEX idx_competitor_price ON erp.competitor_products(price_idr);
CREATE INDEX idx_competitor_created ON erp.competitor_products(created_at DESC);
CREATE INDEX idx_competitor_last_seen ON erp.competitor_products(last_seen DESC);

CREATE INDEX idx_lead_source ON erp.b2b_leads(source_website);
CREATE INDEX idx_lead_status ON erp.b2b_leads(lead_status);
CREATE INDEX idx_lead_city ON erp.b2b_leads(city);
CREATE INDEX idx_lead_province ON erp.b2b_leads(province);
CREATE INDEX idx_lead_created ON erp.b2b_leads(created_at DESC);
CREATE INDEX idx_lead_company_name ON erp.b2b_leads(company_name);
CREATE INDEX idx_lead_email ON erp.b2b_leads(email);
CREATE INDEX idx_lead_phone ON erp.b2b_leads(phone_number);
CREATE INDEX idx_lead_assigned_to ON erp.b2b_leads(assigned_to);

CREATE INDEX idx_dedup_company_hash ON erp.lead_deduplication(company_hash);
CREATE INDEX idx_dedup_phone_hash ON erp.lead_deduplication(phone_hash);
CREATE INDEX idx_dedup_email_hash ON erp.lead_deduplication(email_hash);

CREATE INDEX idx_contact_history_lead ON erp.lead_contact_history(lead_id);
CREATE INDEX idx_contact_history_date ON erp.lead_contact_history(created_at DESC);

-- ============================================
-- VIEWS FOR BUSINESS INTELLIGENCE
-- ============================================

-- View 1: Price Comparison Dashboard
CREATE OR REPLACE VIEW erp.v_price_comparison AS
SELECT 
    product_name,
    brand,
    source_website,
    price_idr,
    availability_status,
    last_seen,
    price_change_percent,
    RANK() OVER (PARTITION BY product_name ORDER BY price_idr ASC) as price_rank,
    (SELECT AVG(price_idr) FROM erp.competitor_products WHERE competitor_products.product_name = cp.product_name) as avg_market_price
FROM erp.competitor_products cp
WHERE last_seen >= NOW() - INTERVAL '30 days'
ORDER BY product_name, price_idr;

-- View 2: Active Leads by City
CREATE OR REPLACE VIEW erp.v_active_leads_by_city AS
SELECT 
    city,
    COUNT(*) as total_leads,
    SUM(CASE WHEN lead_status = 'new' THEN 1 ELSE 0 END) as new_leads,
    SUM(CASE WHEN lead_status = 'contacted' THEN 1 ELSE 0 END) as contacted_leads,
    SUM(CASE WHEN lead_status = 'qualified' THEN 1 ELSE 0 END) as qualified_leads,
    SUM(CASE WHEN lead_status = 'won' THEN 1 ELSE 0 END) as won_leads,
    AVG(lead_quality_score) as avg_quality_score
FROM erp.b2b_leads
WHERE lead_status IN ('new', 'contacted', 'qualified', 'won')
GROUP BY city
ORDER BY total_leads DESC;

-- View 3: Lead Status Summary
CREATE OR REPLACE VIEW erp.v_lead_status_summary AS
SELECT 
    lead_status,
    COUNT(*) as count,
    ROUND(AVG(lead_quality_score)::numeric, 2) as avg_quality,
    COUNT(CASE WHEN assigned_to IS NOT NULL THEN 1 END) as assigned_to_sales,
    COUNT(CASE WHEN next_followup IS NOT NULL AND next_followup <= NOW() THEN 1 END) as overdue_followup
FROM erp.b2b_leads
GROUP BY lead_status
ORDER BY count DESC;

-- View 4: Top Competitors by Product Count
CREATE OR REPLACE VIEW erp.v_top_competitors AS
SELECT 
    source_website,
    COUNT(DISTINCT product_id) as product_count,
    COUNT(DISTINCT product_name) as unique_products,
    ROUND(AVG(price_idr)::numeric, 2) as avg_price,
    MIN(price_idr) as min_price,
    MAX(price_idr) as max_price,
    MAX(last_seen) as last_updated
FROM erp.competitor_products
GROUP BY source_website
ORDER BY product_count DESC;

-- View 5: Job Execution History (for monitoring)
CREATE OR REPLACE VIEW erp.v_job_execution_history AS
SELECT 
    job_id,
    job_name,
    job_type,
    status,
    target_domain,
    record_count,
    processing_duration_seconds,
    CASE 
        WHEN processing_duration_seconds > 300 THEN 'SLOW'
        WHEN processing_duration_seconds > 60 THEN 'NORMAL'
        ELSE 'FAST'
    END as performance_rating,
    created_at,
    completed_at
FROM scraping.job_history
ORDER BY created_at DESC
LIMIT 100;

-- ============================================
-- GRANT PERMISSIONS
-- ============================================

GRANT ALL PRIVILEGES ON SCHEMA scraping TO optima_user;
GRANT ALL PRIVILEGES ON SCHEMA erp TO optima_user;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA scraping TO optima_user;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA erp TO optima_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA scraping TO optima_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA erp TO optima_user;
GRANT ALL PRIVILEGES ON ALL VIEWS IN SCHEMA erp TO optima_user;

-- ============================================
-- SAMPLE DATA (Optional - untuk testing)
-- ============================================

-- Insert sample price monitoring targets
INSERT INTO scraping.price_monitoring_targets (website_name, url_target, domain_name, category, priority)
VALUES 
    ('Toko Lampu A', 'https://www.tokolampu-a.com/products', 'tokolampu-a.com', 'e-commerce', 1),
    ('Marketplace LED', 'https://www.marketplace-led.id/katalog', 'marketplace-led.id', 'marketplace', 2),
    ('Distributor Resmi', 'https://www.distributor-resmi.co.id/produk', 'distributor-resmi.co.id', 'distributor', 1)
ON CONFLICT (url_target) DO NOTHING;

-- Insert sample lead generation targets
INSERT INTO scraping.lead_generation_targets (source_name, url_target, domain_name, category, crawl_depth)
VALUES 
    ('Direktori Kontraktor Indonesia', 'https://www.direktori-kontraktor.com', 'direktori-kontraktor.com', 'directory', 2),
    ('Asosiasi MEP Indonesia', 'https://www.asosiasi-mep.or.id/anggota', 'asosiasi-mep.or.id', 'association', 2),
    ('Portal Tender Nasional', 'https://www.portal-tender.go.id', 'portal-tender.go.id', 'tender_portal', 3)
ON CONFLICT (url_target) DO NOTHING;

-- ============================================
-- CREATE FUNCTIONS FOR COMMON OPERATIONS
-- ============================================

-- Function: Get product price statistics
CREATE OR REPLACE FUNCTION erp.fn_get_product_stats(p_product_name VARCHAR)
RETURNS TABLE (
    product_name VARCHAR,
    min_price DECIMAL,
    max_price DECIMAL,
    avg_price DECIMAL,
    supplier_count BIGINT,
    in_stock_count BIGINT,
    last_updated TIMESTAMP
) AS $$
SELECT 
    product_name,
    MIN(price_idr)::DECIMAL,
    MAX(price_idr)::DECIMAL,
    ROUND(AVG(price_idr), 2)::DECIMAL,
    COUNT(DISTINCT source_website),
    COUNT(CASE WHEN availability_status = 'in_stock' THEN 1 END),
    MAX(last_seen)
FROM erp.competitor_products
WHERE product_name ILIKE p_product_name
GROUP BY product_name;
$$ LANGUAGE SQL;

-- Function: Get leads by specialization
CREATE OR REPLACE FUNCTION erp.fn_get_leads_by_specialization(p_specialization VARCHAR)
RETURNS TABLE (
    lead_id INT,
    company_name VARCHAR,
    city VARCHAR,
    phone_number VARCHAR,
    email VARCHAR,
    lead_status VARCHAR,
    lead_quality_score DECIMAL
) AS $$
SELECT 
    lead_id,
    company_name,
    city,
    phone_number,
    email,
    lead_status,
    lead_quality_score
FROM erp.b2b_leads
WHERE specialization->>'categories' LIKE '%' || p_specialization || '%'
ORDER BY lead_quality_score DESC;
$$ LANGUAGE SQL;

-- ============================================
-- VERIFY INSTALLATION
-- ============================================

-- Run this query to verify all tables were created:
-- SELECT 
--     table_schema,
--     table_name,
--     (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = t.table_schema AND table_name = t.table_name) as column_count
-- FROM information_schema.tables t
-- WHERE table_schema IN ('scraping', 'erp')
-- ORDER BY table_schema, table_name;
