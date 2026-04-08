-- ============================================
-- INIT DATABASE SCRIPT (runs first on container creation)
-- PT Optima Smartindo Industry
-- ============================================

-- Create schemas
CREATE SCHEMA IF NOT EXISTS scraping;
CREATE SCHEMA IF NOT EXISTS erp;

-- Grant permissions
GRANT ALL PRIVILEGES ON SCHEMA scraping TO optima_user;
GRANT ALL PRIVILEGES ON SCHEMA erp TO optima_user;

-- Set default search path
ALTER USER optima_user SET search_path TO public, scraping, erp;
