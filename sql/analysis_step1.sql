-- Create & select the database
CREATE DATABASE IF NOT EXISTS sponsorship_roi;
USE sponsorship_roi;

-- Drop tables in dependency-safe order (no CASCADE in MySQL)
DROP TABLE IF EXISTS fees;
DROP TABLE IF EXISTS periods;
DROP TABLE IF EXISTS scenarios;

-- Scenarios
CREATE TABLE scenarios (
  scenario_id VARCHAR(64) PRIMARY KEY,
  employer_size ENUM('small_or_medium','large') NOT NULL,      /* was TEXT in PG */
  rehire_cycle_months INT NOT NULL,                            /* e.g., 24 */
  base_value_add_year1_gbp DECIMAL(12,2) NOT NULL,
  growth_rate_yearly DECIMAL(10,6) NOT NULL,                   /* e.g., 0.10 */
  loyalty_saving_yearly_gbp DECIMAL(12,2) NOT NULL,
  recruitment_cost_per_hire_gbp DECIMAL(12,2) NOT NULL,
  training_cost_per_hire_gbp DECIMAL(12,2) NOT NULL
) ENGINE=InnoDB;

-- Fees
CREATE TABLE fees (
  employer_size ENUM('small_or_medium','large') NOT NULL,
  fee_type ENUM('licence_fee','immigration_skills_charge','visa_cost_employer_contrib') NOT NULL,
  amount_gbp DECIMAL(12,2) NOT NULL,
  periodicity ENUM('one_off','yearly') NOT NULL,
  PRIMARY KEY (employer_size, fee_type)
) ENGINE=InnoDB;

-- Periods (1..60 months)
CREATE TABLE IF NOT EXISTS periods (
  month_index INT NOT NULL,
  period_start_date DATE NOT NULL,
  PRIMARY KEY (month_index)
) ENGINE=InnoDB;
-- 1. Empty the tables first (safe reset)
TRUNCATE TABLE scenarios;
TRUNCATE TABLE fees;
TRUNCATE TABLE periods;

-- 2. Load scenarios.csv
LOAD DATA LOCAL INFILE 'C:/Users/nivas/OneDrive/Desktop/sponsorship-roi-project/data_sql/scenarios.csv'
INTO TABLE scenarios
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- 3. Load fees.csv
LOAD DATA LOCAL INFILE 'C:/Users/nivas/OneDrive/Desktop/sponsorship-roi-project/data_sql/fees.csv'
INTO TABLE fees
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- 4. Load periods.csv
LOAD DATA LOCAL INFILE 'C:/Users/nivas/OneDrive/Desktop/sponsorship-roi-project/data_sql/periods.csv'
INTO TABLE periods
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- 5. Verify row counts
SELECT COUNT(*) AS scenarios_rows FROM scenarios;
SELECT COUNT(*) AS fees_rows FROM fees;
SELECT COUNT(*) AS periods_rows FROM periods;

-- 6. Peek at the data
SELECT * FROM scenarios;
SELECT * FROM fees LIMIT 5;
SELECT * FROM periods LIMIT 5;

-- 7. Check where MySQL expects files if LOCAL is not enabled
SHOW VARIABLES LIKE 'secure_file_priv';

SELECT COUNT(*) AS scenarios_rows FROM scenarios;
SELECT COUNT(*) AS fees_rows FROM fees;
SELECT COUNT(*) AS periods_rows FROM periods;


-- ================================
-- STEP 1: BENEFITS ONLY (MySQL 8+)
-- Creates:
--   v_params_monthly
--   v_monthly_benefits_step1
-- ================================

-- Convert yearly assumptions to monthly per scenario
DROP VIEW IF EXISTS v_params_monthly;
CREATE VIEW v_params_monthly AS
SELECT
  scenario_id,
  employer_size,
  rehire_cycle_months,
  (base_value_add_year1_gbp / 12.0)      AS base_monthly_value,
  (growth_rate_yearly / 12.0)            AS growth_rate_monthly,
  (loyalty_saving_yearly_gbp / 12.0)     AS loyalty_saving_monthly
FROM scenarios;

-- Monthly benefits:
--  - Sponsorship = base_monthly * (1 + growth_monthly)^(m-1) + loyalty_monthly
--  - No Sponsorship = base_monthly (flat)
DROP VIEW IF EXISTS v_monthly_benefits_step1;
CREATE VIEW v_monthly_benefits_step1 AS
WITH months AS (
  SELECT month_index, period_start_date FROM periods
)
SELECT
  'sponsorship' AS scenario_id,
  m.month_index,
  m.period_start_date,
  ROUND(
    (SELECT base_monthly_value FROM v_params_monthly WHERE scenario_id = 'sponsorship')
    * POWER(1 + (SELECT growth_rate_monthly FROM v_params_monthly WHERE scenario_id = 'sponsorship'),
            m.month_index - 1)
    + (SELECT loyalty_saving_monthly FROM v_params_monthly WHERE scenario_id = 'sponsorship')
  , 2) AS benefit_gbp
FROM months m

UNION ALL

SELECT
  'no_sponsorship' AS scenario_id,
  m.month_index,
  m.period_start_date,
  ROUND(
    (SELECT base_monthly_value FROM v_params_monthly WHERE scenario_id = 'no_sponsorship')
  , 2) AS benefit_gbp
FROM months m;



-- First 6 months per scenario (should rise for sponsorship, be flat for no_sponsorship)
SELECT * FROM v_monthly_benefits_step1
WHERE month_index <= 6
ORDER BY scenario_id, month_index;

-- Spot-check month 1 and 60
SELECT * FROM v_monthly_benefits_step1 WHERE month_index IN (1, 60) ORDER BY scenario_id, month_index;
