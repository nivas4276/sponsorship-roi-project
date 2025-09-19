-- STEP 1 ANALYSIS (Benefits only)
-- Goal: Compute monthly 'benefit' per scenario.
--  - Sponsorship: base value grows monthly using a recursive factor + monthly loyalty saving.
--  - No_sponsorship: flat monthly value (no growth yet).

/* Helper: monthly params for each scenario */
DROP VIEW IF EXISTS v_params_monthly;
CREATE VIEW v_params_monthly AS
SELECT
  scenario_id,
  employer_size,
  rehire_cycle_months,
  base_value_add_year1_gbp / 12.0 AS base_monthly_value,
  growth_rate_yearly / 12.0 AS growth_rate_monthly,
  loyalty_saving_yearly_gbp / 12.0 AS loyalty_saving_monthly
FROM scenarios;

/* Recursive growth factor for the sponsorship scenario */
DROP VIEW IF EXISTS v_growth_factor;
CREATE VIEW v_growth_factor AS
WITH RECURSIVE g(m, factor) AS (
  SELECT 1, 1.0
  UNION ALL
  SELECT m+1, factor * (1.0 + (SELECT growth_rate_monthly FROM v_params_monthly WHERE scenario_id='sponsorship'))
  FROM g
  WHERE m < (SELECT MAX(month_index) FROM periods)
)
SELECT m AS month_index, factor FROM g;

/* Monthly benefits */
DROP VIEW IF EXISTS v_monthly_benefits_step1;
CREATE VIEW v_monthly_benefits_step1 AS
-- Sponsorship (growth + loyalty saving)
SELECT
  'sponsorship' AS scenario_id,
  p.month_index,
  p.period_start_date,
  ROUND((SELECT base_monthly_value FROM v_params_monthly WHERE scenario_id='sponsorship')
        * (SELECT factor FROM v_growth_factor gf WHERE gf.month_index = p.month_index)
        + (SELECT loyalty_saving_monthly FROM v_params_monthly WHERE scenario_id='sponsorship'), 2) AS benefit_gbp
FROM periods p

UNION ALL

-- No sponsorship (flat monthly base; we'll add variation later)
SELECT
  'no_sponsorship' AS scenario_id,
  p.month_index,
  p.period_start_date,
  ROUND((SELECT base_monthly_value FROM v_params_monthly WHERE scenario_id='no_sponsorship'), 2) AS benefit_gbp
FROM periods p;

/* Quick sanity queries to run after loading:
SELECT * FROM v_monthly_benefits_step1 WHERE month_index <= 6 ORDER BY scenario_id, month_index;
*/
