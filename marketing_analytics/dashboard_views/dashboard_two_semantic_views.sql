/*
===============================================================================
Dashboard 2: LTV & Cohort Analysis — Semantic Views
===============================================================================
Purpose:
    - To provide Tableau-ready data sources for Dashboard 2.
    - Two new views that aggregate existing cohort data for dashboard visuals.

Dependencies:
    - gold.fact_user_acquisition (from 0911 script, Query 1)
    - gold.fact_ltv_cohort_channel (from 0911 script, Query 4)
    - gold.fact_purchases
    - gold.fact_spend

Views Created:
    1) gold.dashboard_ltv_kpi — KPI row: North Star LTV:CAC, Avg LTV, Avg CAC, Users Acquired
    2) gold.dashboard_ltv_channel_summary — Channel-level summary for Scatter Plot & Efficiency Table

===============================================================================
*/
USE marketing_dw;
GO


/*
===============================================================================
1) KPI View: Overall LTV, CAC, LTV:CAC Ratio, Users Acquired
===============================================================================
Provides the four KPI cards and the North Star metric for Dashboard 2.
- LTV uses all users (conservative, consistent with Query 2 in 0911 script).
- CAC uses total spend / acquired users (users with tracked touchpoints).
- LTV:CAC = LTV / CAC.
- Users Acquired = distinct users from fact_user_acquisition.

Note: This is a single-row view. Tableau connects to it for the KPI cards.
      The MoM comparison ("+8.2% MoM" shown in wireframe) can be computed
      as a Tableau calculated field using the monthly cohort view.
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


/*
===============================================================================
2) Channel Summary: LTV, CAC, LTV:CAC Ratio, Ratio Band, Users per Channel
===============================================================================
Provides one row per acquisition channel for:
    - Scatter Plot (X=CAC, Y=LTV, Color=Ratio Band, Size=Users)
    - Efficiency Table (Channel, CAC, LTV, LTV:CAC, Users)

Methodology:
    - LTV per channel = total revenue from channel's acquired users / channel's cohort size.
      This uses the FULL 120-day window (all available months of revenue).
    - CAC per channel = total acquisition spend on that channel / channel's cohort size.
    - Only paid channels have CAC; organic channels show NULL for CAC/LTV:CAC/ROI.
    - Ratio Band classifies channels for the scatter plot color encoding.

Design Decision:
    - Revenue is attributed to the user's acquisition channel (first-touch attribution),
      regardless of which channel the user interacted with later.
    - This matches the attribution model used in fact_ltv_cohort_channel.
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
)

SELECT
    cu.acquisition_channel,
    cu.cohort_size AS users_acquired,
    cr.total_revenue,
    cs.total_spend,
    -- LTV: total revenue from channel users / cohort size
    ROUND(cr.total_revenue * 1.0 / NULLIF(cu.cohort_size, 0), 2) AS ltv_120d,
    -- CAC: total acquisition spend / cohort size (NULL for organic)
    ROUND(cs.total_spend * 1.0 / NULLIF(cu.cohort_size, 0), 2) AS cac,
    -- LTV:CAC Ratio
    ROUND(
        (cr.total_revenue * 1.0 / NULLIF(cu.cohort_size, 0))
        /
        NULLIF(cs.total_spend * 1.0 / NULLIF(cu.cohort_size, 0), 0)
    , 2) AS ltv_cac_ratio,
    -- Ratio Band for scatter plot color encoding
    CASE
        WHEN (cr.total_revenue * 1.0 / NULLIF(cu.cohort_size, 0))
             / NULLIF(cs.total_spend * 1.0 / NULLIF(cu.cohort_size, 0), 0) >= 3 THEN 'Excellent (>3x)'
        WHEN (cr.total_revenue * 1.0 / NULLIF(cu.cohort_size, 0))
             / NULLIF(cs.total_spend * 1.0 / NULLIF(cu.cohort_size, 0), 0) >= 2 THEN 'Good (2-3x)'
        WHEN (cr.total_revenue * 1.0 / NULLIF(cu.cohort_size, 0))
             / NULLIF(cs.total_spend * 1.0 / NULLIF(cu.cohort_size, 0), 0) > 0 THEN 'Review (<2x)'
        ELSE NULL  -- Organic channels without spend
    END AS ratio_band,
    -- ROI for additional context
    ROUND(
        (cr.total_revenue * 1.0 / NULLIF(cu.cohort_size, 0) - cs.total_spend * 1.0 / NULLIF(cu.cohort_size, 0))
        /
        NULLIF(cs.total_spend * 1.0 / NULLIF(cu.cohort_size, 0), 0)
    , 2) AS roi
FROM channel_users cu
LEFT JOIN channel_revenue cr
    ON cu.acquisition_channel = cr.acquisition_channel
LEFT JOIN channel_spend cs
    ON cu.acquisition_channel = cs.channel;
GO

SELECT *
FROM gold.dashboard_ltv_channel_summary
ORDER BY ltv_cac_ratio DESC;
GO
