USE sponsorship_roi;
DROP VIEW IF EXISTS v_monthly_costs;

CREATE VIEW v_monthly_costs AS
/* ---------- Sponsorship: Month 1 (licence + visa) + monthly ISC ---------- */
SELECT
  'sponsorship' AS scenario_id,
  p.month_index,
  p.period_start_date,
  (
    /* monthly ISC */
    (SELECT f.amount_gbp / 12.0
       FROM fees f
      WHERE f.fee_type = 'immigration_skills_charge'
        AND f.employer_size = (SELECT s.employer_size
                                 FROM scenarios s
                                WHERE s.scenario_id = 'sponsorship'))
    +
    /* month 1 one-off fees: licence + visa */
    CASE WHEN p.month_index = 1 THEN
      (SELECT f.amount_gbp
         FROM fees f
        WHERE f.fee_type = 'licence_fee'
          AND f.employer_size = (SELECT s.employer_size
                                   FROM scenarios s
                                  WHERE s.scenario_id = 'sponsorship'))
      +
      (SELECT f.amount_gbp
         FROM fees f
        WHERE f.fee_type = 'visa_cost_employer_contrib'
          AND f.employer_size = (SELECT s.employer_size
                                   FROM scenarios s
                                  WHERE s.scenario_id = 'sponsorship'))
    ELSE 0 END
  ) AS cost_gbp
FROM periods p

UNION ALL

/* ---------- No sponsorship: Recruitment + training each rehire cycle ---------- */
SELECT
  'no_sponsorship' AS scenario_id,
  p.month_index,
  p.period_start_date,
  CASE
    WHEN ((p.month_index - 1) %
          (SELECT s.rehire_cycle_months
             FROM scenarios s
            WHERE s.scenario_id = 'no_sponsorship')) = 0
      THEN (
        SELECT s.recruitment_cost_per_hire_gbp + s.training_cost_per_hire_gbp
          FROM scenarios s
         WHERE s.scenario_id = 'no_sponsorship'
      )
    ELSE 0
  END AS cost_gbp
FROM periods p;


-- Sponsorship: big cost only in month 1, then small monthly ISC
SELECT * FROM v_monthly_costs
WHERE scenario_id='sponsorship' AND month_index <= 6
ORDER BY month_index;

-- No-sponsorship: spikes at months 1, 25, 49 (24-month cycle)
SELECT * FROM v_monthly_costs
WHERE scenario_id='no_sponsorship' AND month_index <= 30
ORDER BY month_index;

