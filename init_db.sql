-- ============================================
-- INIT DATABASE SCRIPT
-- PT Optima Smartindo Industry
-- ============================================

-- Create schemas
CREATE SCHEMA IF NOT EXISTS scraping;
CREATE SCHEMA IF NOT EXISTS erp;

-- Grant permissions
GRANT ALL PRIVILEGES ON SCHEMA scraping TO optima_user;
GRANT ALL PRIVILEGES ON SCHEMA erp TO optima_user;

-- Note: Tables will be created via schema.sql after initial setup
