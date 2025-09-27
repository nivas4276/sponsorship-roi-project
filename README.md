# 📊 Sponsorship ROI Project
**5-Year ROI Case Study: Why Sponsoring a Data Analyst is a High-Value Investment**

---

## 🧭 Executive Summary (for Hiring Managers & HR)

### Problem  
UK employers often see visa sponsorship as a **cost burden** (licence fee, visa contribution, Immigration Skills Charge). This perception discourages sponsorship of international talent.

### Solution  
A **SQL-first, transparent 5-year model** comparing:
- **Sponsorship** → upfront fees, but **compounding value** and **retention**.
- **No Sponsorship** → avoids visa fees, but suffers **recurring recruitment/training costs** and **lost knowledge**.

### Results (will be filled as the project progresses)  
- **Break-even:** within **[X months]** (after Net & Cumulative steps).  
- **5-year outcome:** Sponsorship shows **higher cumulative net value** under conservative assumptions.  
- All assumptions live in editable CSVs so employers can **plug in their own numbers**.

### Why This Matters  
Sponsorship isn’t just a compliance expense; it’s a **strategic investment** in capability, speed, and decision quality. This project **quantifies** that investment.

### Why Me  
I designed and built this project from scratch to answer a real employer question—**“Why should we sponsor this candidate?”**  
It demonstrates my strengths in:
- **SQL & analytics modelling**
- **Decision-ready dashboards**
- **Business storytelling & stakeholder communication**

---

## 📌 What is this project?
A **portfolio case study** that models two scenarios over 60 months (5 years):
1. **Sponsorship** — fees + compounding analyst value + loyalty/retention benefits  
2. **No Sponsorship** — no visa fees but periodic re-hire + training costs and no compounding value

All assumptions are **plain CSV inputs**, and all calculations are **SQL** (auditable, portable).

---

## 🗂️ Repository Structure


---

## 🧱 Raw Inputs (what each file contains)

**`data_sql/scenarios.csv`**
- `scenario_id` → `sponsorship` / `no_sponsorship`  
- `employer_size` → `small_or_medium` (test `large` later)  
- `rehire_cycle_months` → e.g., 24 (every 2 years)  
- `base_value_add_year1_gbp` → conservative Year-1 value created by the analyst  
- `growth_rate_yearly` → sponsorship learning/compounding (0 for no_sponsorship in Step 1)  
- `loyalty_saving_yearly_gbp` → retention/continuity proxy (0 for no_sponsorship in Step 1)  
- `recruitment_cost_per_hire_gbp`, `training_cost_per_hire_gbp` → used in costs step  

**`data_sql/fees.csv`**
- `employer_size` → `small_or_medium` / `large`  
- `fee_type` → `licence_fee` / `immigration_skills_charge` / `visa_cost_employer_contrib`  
- `amount_gbp`, `periodicity` → `one_off` or `yearly`  

**`data_sql/periods.csv`**
- `month_index` → 1..60  
- `period_start_date` → ISO date for clarity  

---

## 🧪 SQL Modelling (Step-by-Step & Easy to Explain)

### ✅ Step 1 — Benefits Only (done)
**Goal:** compute monthly **benefits** per scenario *before* costs.

**Logic:**
- Convert yearly → monthly parameters.
- **Sponsorship:**  
  `benefit[m] = base_monthly * (1 + growth_monthly)^(m-1) + loyalty_monthly`
- **No Sponsorship:**  
  `benefit[m] = base_monthly` (flat in Step 1)

**Run locally (from repo root):**
```bash
# 1) Create DB and tables
sqlite3 sponsorship_roi.db ".read sql/schema.sql"

# 2) Import raw CSVs
sqlite3 sponsorship_roi.db ".mode csv" ".import data_sql/scenarios.csv scenarios"
sqlite3 sponsorship_roi.db ".mode csv" ".import data_sql/fees.csv      fees"
sqlite3 sponsorship_roi.db ".mode csv" ".import data_sql/periods.csv   periods"

# 3) Create Step 1 benefits view
sqlite3 sponsorship_roi.db ".read sql/analysis_step1.sql"

# 4) Sanity check: first 6 months
sqlite3 sponsorship_roi.db "SELECT * FROM v_monthly_benefits_step1 WHERE month_index <= 6 ORDER BY scenario_id, month_index;"
