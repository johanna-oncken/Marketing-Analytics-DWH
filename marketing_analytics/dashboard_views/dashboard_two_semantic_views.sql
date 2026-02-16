/*
===============================================================================
Dashboard 2: LTV & Cohort Analysis — Semantic Views
===============================================================================
Purpose:
    - To provide Tableau-ready data sources for Dashboard 2.

Dependencies:
    - gold.fact_user_acquisition (from 0911 script, Query 1)
    - gold.fact_ltv_cohort_channel (from 0911 script, Query 4)
    - gold.fact_purchases
    - gold.fact_spend

===============================================================================
*/
USE marketing_dw;
GO


/*
===============================================================================
1) KPI View: Overall LTV, CAC, LTV:CAC Ratio, Users Acquired
===============================================================================
*/
DROP VIEW IF EXISTS gold.dashboard_ltv_kpi;
GO

CREATE VIEW gold.dashboard_ltv_kpi AS
WITH user_stats AS (
    SELECT COUNT(DISTINCT user_id) AS total_users
    FROM gold.dim_user
),
acquisition_stats AS (
    SELECT COUNT(DISTINCT user_id) AS acquired_users
    FROM gold.fact_user_acquisition
),
revenue_stats AS (
    SELECT SUM(revenue) AS total_revenue
    FROM gold.fact_purchases
),
spend_stats AS (
    SELECT SUM(spend) AS total_spend
    FROM gold.fact_spend
)
SELECT
    r.total_revenue,
    s.total_spend,
    u.total_users,
    a.acquired_users,
    -- Avg LTV (120d): revenue per user (all users, conservative)
    ROUND(r.total_revenue * 1.0 / NULLIF(u.total_users, 0), 2) AS avg_ltv_120d,
    -- Avg CAC: spend per acquired user
    ROUND(s.total_spend * 1.0 / NULLIF(a.acquired_users, 0), 2) AS avg_cac,
    -- North Star: LTV:CAC Ratio
    ROUND(
        (r.total_revenue * 1.0 / NULLIF(u.total_users, 0))
        /
        NULLIF(s.total_spend * 1.0 / NULLIF(a.acquired_users, 0), 0)
    , 2) AS ltv_cac_ratio,
    -- Health status for conditional formatting
    CASE
        WHEN (r.total_revenue * 1.0 / NULLIF(u.total_users, 0))
             / NULLIF(s.total_spend * 1.0 / NULLIF(a.acquired_users, 0), 0) >= 3 THEN 'Healthy'
        WHEN (r.total_revenue * 1.0 / NULLIF(u.total_users, 0))
             / NULLIF(s.total_spend * 1.0 / NULLIF(a.acquired_users, 0), 0) >= 2 THEN 'Monitor'
        ELSE 'At Risk'
    END AS ltv_cac_status
FROM revenue_stats r
CROSS JOIN spend_stats s
CROSS JOIN user_stats u
CROSS JOIN acquisition_stats a;
GO

SELECT * FROM gold.dashboard_ltv_kpi;
GO


