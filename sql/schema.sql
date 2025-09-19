PRAGMA foreign_keys = ON;

/* === RAW TABLES (match your CSV columns exactly) === */

DROP TABLE IF EXISTS scenarios;
CREATE TABLE scenarios (
  scenario_id TEXT PRIMARY KEY,
  employer_size TEXT NOT NULL,              -- small_or_medium | large
  rehire_cycle_months INTEGER NOT NULL,     -- e.g., 24
  base_value_add_year1_gbp REAL NOT NULL,   -- e.g., 15000
  growth_rate_yearly REAL NOT NULL,         -- e.g., 0.10 (10%)
  loyalty_saving_yearly_gbp REAL NOT NULL,  -- e.g., 2000
  recruitment_cost_per_hire_gbp REAL NOT NULL,
  training_cost_per_hire_gbp REAL NOT NULL
);

DROP TABLE IF EXISTS fees;
CREATE TABLE fees (
  employer_size TEXT NOT NULL,
  fee_type TEXT NOT NULL,                   -- licence_fee | immigration_skills_charge | visa_cost_employer_contrib
  amount_gbp REAL NOT NULL,
  periodicity TEXT NOT NULL,                -- one_off | yearly
  PRIMARY KEY (employer_size, fee_type)
);

DROP TABLE IF EXISTS periods;
CREATE TABLE periods (
  month_index INTEGER PRIMARY KEY,          -- 1..60
  period_start_date TEXT NOT NULL           -- YYYY-MM-DD
);

/* === (Indexes optional at this size; add if needed) === */
