/*
================================================================================
KPI ROW - MONTHLY TOTALS FOR DASHBOARD HEADER
================================================================================
Purpose: Aggregated monthly KPIs without Channel/Campaign breakdown
         For the top KPI row in Dashboard 1

Note on Spend:
    - KPI Row shows ACTUAL SPEND (when money was spent) from gold.fact_spend
    - gold.roas shows ATTRIBUTED SPEND (spend linked to conversions) - different concept!

German decimal format for Tableau Public
================================================================================
*/

CREATE OR ALTER VIEW gold.kpi_row AS

-- =============================================================================
-- REVENUE
-- =============================================================================
SELECT 
    performance_month AS month_date,
    'Revenue' AS kpi_name,
    REPLACE(CAST(ROUND(current_revenue, 2) AS VARCHAR(50)), '.', ',') AS kpi_value,
    REPLACE(CAST(ROUND(mom_percentage, 2) AS VARCHAR(50)), '.', ',') AS mom_value,
    CASE 
        WHEN mom_percentage > 0 THEN '+'
        WHEN mom_percentage < 0 THEN '-'
        ELSE '='
    END AS mom_arrow
FROM gold.revenue

UNION ALL

-- =============================================================================
-- SPEND (Actual Spend from fact_spend, NOT from ROAS view)
-- =============================================================================
SELECT 
    performance_month AS month_date,
    'Spend' AS kpi_name,
    REPLACE(CAST(ROUND(current_spend, 2) AS VARCHAR(50)), '.', ',') AS kpi_value,
    REPLACE(CAST(ROUND(mom_percentage, 2) AS VARCHAR(50)), '.', ',') AS mom_value,
    CASE 
        WHEN mom_percentage > 0 THEN '+'
        WHEN mom_percentage < 0 THEN '-'
        ELSE '='
    END AS mom_arrow
FROM (
    SELECT 
        performance_month,
        current_spend,
        ROUND(
            CASE 
                WHEN LAG(current_spend) OVER(ORDER BY performance_month) = 0 THEN NULL 
                ELSE (current_spend - LAG(current_spend) OVER(ORDER BY performance_month))
                     / LAG(current_spend) OVER(ORDER BY performance_month) * 100 
            END
        , 2) AS mom_percentage
    FROM (
        SELECT 
            DATEFROMPARTS(YEAR(spend_date), MONTH(spend_date), 1) AS performance_month,
            SUM(spend) AS current_spend
        FROM gold.fact_spend
        GROUP BY DATEFROMPARTS(YEAR(spend_date), MONTH(spend_date), 1)
    ) monthly_spend
) spend_with_mom

UNION ALL

-- =============================================================================
-- ROAS (Attributed ROAS - keeps its original logic)
-- =============================================================================
SELECT 
    performance_month AS month_date,
    'ROAS' AS kpi_name,
    REPLACE(CAST(ROUND(current_roas, 2) AS VARCHAR(50)), '.', ',') AS kpi_value,
    REPLACE(CAST(ROUND(mom_percentage, 2) AS VARCHAR(50)), '.', ',') AS mom_value,
    CASE 
        WHEN mom_percentage > 0 THEN '+'
        WHEN mom_percentage < 0 THEN '-'
        ELSE '='
    END AS mom_arrow
FROM gold.roas

UNION ALL

-- =============================================================================
-- CAC (Already uses actual spend internally)
-- Note: Lower CAC = better, so arrows are inverted
-- =============================================================================
SELECT 
    performance_month AS month_date,
    'CAC' AS kpi_name,
    REPLACE(CAST(ROUND(current_cac, 2) AS VARCHAR(50)), '.', ',') AS kpi_value,
    REPLACE(CAST(ROUND(mom_percentage, 2) AS VARCHAR(50)), '.', ',') AS mom_value,
    -- Inverted: CAC down = good (+), CAC up = bad (-)
    CASE 
        WHEN mom_percentage > 0 THEN '-'
        WHEN mom_percentage < 0 THEN '+'
        ELSE '='
    END AS mom_arrow
FROM gold.cac

UNION ALL

-- =============================================================================
-- CVR (as percentage)
-- =============================================================================
SELECT 
    performance_month AS month_date,
    'CVR' AS kpi_name,
    REPLACE(CAST(ROUND(current_cvr * 100, 2) AS VARCHAR(50)), '.', ',') AS kpi_value,
    REPLACE(CAST(ROUND(mom_percentage, 2) AS VARCHAR(50)), '.', ',') AS mom_value,
    CASE 
        WHEN mom_percentage > 0 THEN '+'
        WHEN mom_percentage < 0 THEN '-'
        ELSE '='
    END AS mom_arrow
FROM gold.cvr

;
GO

--------------------------------------------------------------------------------
SELECT * FROM gold.kpi_row ORDER BY kpi_name, month_date;
