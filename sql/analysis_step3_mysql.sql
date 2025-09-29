-- ================================
-- STEP 3: NET + ANNUAL (MySQL 8+)
-- Creates:
--   v_monthly_net
--   v_annual_summary
--   v_cumulative_net   (bonus)
--   v_break_even_hint  (bonus)
-- ================================

/* Monthly net = benefits - costs */
USE sponsorship_roi;
DROP VIEW IF EXISTS v_monthly_net;
CREATE VIEW v_monthly_net AS
SELECT
  b.scenario_id,
  b.month_index,
  b.period_start_date,
  ROUND(b.benefit_gbp - c.cost_gbp, 2) AS net_gbp
FROM v_monthly_benefits_step1 b
JOIN v_monthly_costs         c
  ON b.scenario_id = c.scenario_id
 AND b.month_index  = c.month_index;

/* Annual summary: sum of monthly net by scenario & year number */
DROP VIEW IF EXISTS v_annual_summary;
CREATE VIEW v_annual_summary AS
SELECT
  scenario_id,
  /* year_num: 1..5 from month_index */
  (FLOOR((month_index - 1) / 12) + 1) AS year_num,
  MIN(DATE_FORMAT(period_start_date, '%Y-01-01')) AS year_start,
  ROUND(SUM(net_gbp), 2) AS net_gbp_year
FROM v_monthly_net
GROUP BY scenario_id, (FLOOR((month_index - 1) / 12) + 1)
ORDER BY scenario_id, year_num;

/* Bonus: cumulative net over time */
DROP VIEW IF EXISTS v_cumulative_net;
CREATE VIEW v_cumulative_net AS
SELECT
  scenario_id,
  month_index,
  period_start_date,
  net_gbp,
  ROUND(
    SUM(net_gbp) OVER (PARTITION BY scenario_id ORDER BY month_index
                       ROWS UNBOUNDED PRECEDING), 2
  ) AS cum_net_gbp
FROM v_monthly_net;

/* Bonus: quick helper showing the monthly cumulative advantage of sponsorship over no_sponsorship */
DROP VIEW IF EXISTS v_break_even_hint;
CREATE VIEW v_break_even_hint AS
SELECT
  s.month_index,
  s.period_start_date,
  s.cum_net_gbp AS sponsorship_cum_net,
  n.cum_net_gbp AS no_sponsorship_cum_net,
  ROUND(s.cum_net_gbp - n.cum_net_gbp, 2) AS sponsorship_minus_no
FROM v_cumulative_net s
JOIN v_cumulative_net n
  ON s.month_index = n.month_index
WHERE s.scenario_id = 'sponsorship'
  AND n.scenario_id = 'no_sponsorship'
ORDER BY s.month_index;

-- A) First 6 months of NET for both scenarios
SELECT * FROM v_monthly_net
WHERE month_index <= 6
ORDER BY scenario_id, month_index;

-- Expect approx:
-- sponsorship m1: 1416.67 - 1566.33 ≈ -149.66 (negative first month)
-- sponsorship m2: ~1427.08 - 30.33 ≈ 1396.75 (then strongly positive)
-- no_sponsorship m1: 1250 - 8000 = -6750; m2..: 1250 - 0 = 1250

-- B) Annual totals
SELECT * FROM v_annual_summary;

-- C) Cumulative NET (spot-check start and end)
SELECT * FROM v_cumulative_net WHERE month_index IN (1, 12, 24, 36, 48, 60) AND scenario_id='sponsorship';
SELECT * FROM v_cumulative_net WHERE month_index IN (1, 12, 24, 36, 48, 60) AND scenario_id='no_sponsorship';

-- D) Break-even hint: first month sponsorship cumulative exceeds no_sponsorship
SELECT *
FROM v_break_even_hint
WHERE sponsorship_minus_no > 0
ORDER BY month_index
LIMIT 1;
