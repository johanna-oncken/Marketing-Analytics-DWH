/*
===============================================================================
Dashboard 2: LTV & Cohort Analysis — CSV-Export Views (German Locale)
===============================================================================
Purpose:
    - Tableau-ready views for CSV export with German decimal formatting (, instead of .)
    - All numeric output columns use REPLACE to convert '.' to ','

Dependencies:
    - gold.fact_user_acquisition (from 0911 script)
    - gold.fact_ltv_cohort (from 0911 script, Query 3)
    - gold.fact_purchases
    - gold.fact_spend

Views Created:
    1) gold.dashboard_ltv_channel_summary — Efficiency Table
    2) gold.dashboard_ltv_cohort_heatmap — Cohort Heatmap (based on fact_ltv_cohort)
===============================================================================
*/
USE marketing_dw;
GO


/*
===============================================================================
1) Channel Summary: Efficiency Table
===============================================================================
One row per acquisition channel.
- Scatter Plot: X=CAC, Y=LTV, Color=Ratio Band, Size=Users
- Efficiency Table: Channel, CAC, LTV, LTV:CAC, Users
*/
DROP VIEW IF EXISTS gold.dashboard_ltv_channel_summary;
GO

CREATE VIEW gold.dashboard_ltv_channel_summary AS
WITH channel_users AS (
    SELECT
        acquisition_channel,
        COUNT(DISTINCT user_id) AS cohort_size
    FROM gold.fact_user_acquisition
    GROUP BY acquisition_channel
),
channel_revenue AS (
    SELECT
        a.acquisition_channel,
        SUM(p.revenue) AS total_revenue
    FROM gold.fact_user_acquisition a
    INNER JOIN gold.fact_purchases p
        ON a.user_id = p.user_id
    GROUP BY a.acquisition_channel
),
channel_spend AS (
    SELECT
        s.channel,
        SUM(s.spend) AS total_spend
    FROM gold.fact_spend s
    WHERE s.campaign_id IN (
        SELECT DISTINCT acquisition_campaign
        FROM gold.fact_user_acquisition
        WHERE acquisition_campaign IS NOT NULL
    )
    GROUP BY s.channel
),
base AS (
    SELECT
        cu.acquisition_channel,
        cu.cohort_size AS users_acquired,
        cr.total_revenue,
        cs.total_spend,
        cr.total_revenue * 1.0 / NULLIF(cu.cohort_size, 0) AS ltv_120d,
        cs.total_spend * 1.0 / NULLIF(cu.cohort_size, 0) AS cac,
        (cr.total_revenue * 1.0 / NULLIF(cu.cohort_size, 0))
            / NULLIF(cs.total_spend * 1.0 / NULLIF(cu.cohort_size, 0), 0) AS ltv_cac_ratio,
        (cr.total_revenue * 1.0 / NULLIF(cu.cohort_size, 0) - cs.total_spend * 1.0 / NULLIF(cu.cohort_size, 0))
            / NULLIF(cs.total_spend * 1.0 / NULLIF(cu.cohort_size, 0), 0) AS roi
    FROM channel_users cu
    LEFT JOIN channel_revenue cr
        ON cu.acquisition_channel = cr.acquisition_channel
    LEFT JOIN channel_spend cs
        ON cu.acquisition_channel = cs.channel
)

SELECT
    acquisition_channel,
    users_acquired,
    REPLACE(CAST(total_revenue AS VARCHAR(50)), '.', ',') AS total_revenue,
    REPLACE(CAST(total_spend AS VARCHAR(50)), '.', ',') AS total_spend,
    REPLACE(CAST(ltv_120d AS VARCHAR(50)), '.', ',') AS ltv_120d,
    REPLACE(CAST(cac AS VARCHAR(50)), '.', ',') AS cac,
    REPLACE(CAST(ltv_cac_ratio AS VARCHAR(50)), '.', ',') AS ltv_cac_ratio,
    CASE
        WHEN ltv_cac_ratio >= 5 THEN 'To Be Examined (>5x)'
        WHEN ltv_cac_ratio >= 3 THEN 'Healthy (3-5x)'
        WHEN ltv_cac_ratio >= 2 THEN 'Monitor (2-3x)'
        WHEN ltv_cac_ratio > 0 THEN 'At Risk (<2x)'
        ELSE NULL
    END AS ratio_band,
    REPLACE(CAST(roi AS VARCHAR(50)), '.', ',') AS roi
FROM base;
GO

SELECT *
FROM gold.dashboard_ltv_channel_summary
ORDER BY acquisition_channel;
GO


/*
===============================================================================
2) Cohort Heatmap (based on gold.fact_ltv_cohort)
===============================================================================
*/
DROP VIEW IF EXISTS gold.dashboard_ltv_cohort_heatmap;
GO

CREATE VIEW gold.dashboard_ltv_cohort_heatmap AS
SELECT
    acquisition_month,
    purchase_month,
    month_number,
    REPLACE(CAST(monthly_revenue AS VARCHAR(50)), '.', ',') AS monthly_revenue,
    cohort_size,
    active_users,
    REPLACE(CAST(purchase_rate_pct AS VARCHAR(50)), '.', ',') AS purchase_rate_pct,
    REPLACE(CAST(monthly_ltv AS VARCHAR(50)), '.', ',') AS monthly_ltv,
    REPLACE(CAST(cumulative_ltv AS VARCHAR(50)), '.', ',') AS cumulative_ltv,
    REPLACE(CAST(cac AS VARCHAR(50)), '.', ',') AS cac,
    REPLACE(CAST(ltv_cac_ratio AS VARCHAR(50)), '.', ',') AS ltv_cac_ratio,
    REPLACE(CAST(roi AS VARCHAR(50)), '.', ',') AS roi
FROM gold.fact_ltv_cohort;
GO

SELECT *
FROM gold.dashboard_ltv_cohort_heatmap
ORDER BY acquisition_month, month_number;
GO
