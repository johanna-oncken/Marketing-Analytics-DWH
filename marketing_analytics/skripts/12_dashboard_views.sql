/*
==================================================================================================
DASHBOARD VIEWS
==================================================================================================
Semantic views that restructure analysis results for Tableau dashboards. Includes decimal format 
conversion (dot → comma) as a workaround for Tableau Public's German locale handling.

---------------------------------------------------------------------------------------------------
================================================================================
DASHBOARD ONE SEMANTICS - SEMANTIC LAYER VIEW (Compact Version)
================================================================================
Purpose: Long-format unified view for Tableau Dashboard 1 (Budget Allocation)

KPI Structure:
    TOFU/MOFU/BOFU: Revenue, ROAS, Spend, CVR, MoM_Revenue
    ALL:            CAC, CPA, CPC, CTR

German decimal format: Comma as separator (for Tableau Public DE locale)
================================================================================
*/

CREATE OR ALTER VIEW gold.dashboard_one_semantics AS

-- =============================================================================
-- CHANNEL-LEVEL KPIS
-- =============================================================================

-- Revenue by Funnel Stage
SELECT 
    performance_month AS month_date,
    'Channel' AS entity_type,
    'NULL' AS entity_id,
    channel AS entity_name,
    channel AS parent_channel,
    'MOFU' AS funnel_stage,
    'Revenue' AS kpi_name,
    REPLACE(CAST(ROUND(current_revenue, 6) AS VARCHAR(50)), '.', ',') AS kpi_value,
    'ATOMIC_VALUE' AS kpi_semantics
FROM gold.funnel_channels_performance -- MOFU revenue
WHERE current_revenue IS NOT NULL

UNION ALL

SELECT 
    performance_month, 'Channel', 'NULL', channel, channel, 'MOFU', 'MoM_Revenue',
    REPLACE(CAST(ROUND(mom_percentage, 6) AS VARCHAR(50)), '.', ','), 'ATOMIC_VALUE'
FROM gold.funnel_channels_performance --MOFU revenue

UNION ALL

SELECT 
    performance_month, 'Channel', 'NULL', acquisition_channel, acquisition_channel, 'TOFU', 'Revenue',
    REPLACE(CAST(ROUND(current_revenue, 6) AS VARCHAR(50)), '.', ','), 'ATOMIC_VALUE'
FROM gold.acquisition_channels_performance -- TOFU revenue
WHERE current_revenue IS NOT NULL

UNION ALL

SELECT 
    performance_month, 'Channel', 'NULL', acquisition_channel, acquisition_channel, 'TOFU', 'MoM_Revenue',
    REPLACE(CAST(ROUND(mom_percentage, 6) AS VARCHAR(50)), '.', ','), 'ATOMIC_VALUE'
FROM gold.acquisition_channels_performance -- TOFU revenue

UNION ALL

SELECT 
    performance_month, 'Channel', 'NULL', last_touch_channel, last_touch_channel, 'BOFU', 'Revenue',
    REPLACE(CAST(ROUND(current_revenue, 6) AS VARCHAR(50)), '.', ','), 'ATOMIC_VALUE'
FROM gold.last_touch_channels_performance -- BOFU revenue
WHERE current_revenue IS NOT NULL

UNION ALL

SELECT 
    performance_month, 'Channel', 'NULL', last_touch_channel, last_touch_channel, 'BOFU', 'MoM_Revenue',
    REPLACE(CAST(ROUND(mom_percentage, 6) AS VARCHAR(50)), '.', ','), 'ATOMIC_VALUE'
FROM gold.last_touch_channels_performance -- BOFU revenue

-- ROAS by Funnel Stage
UNION ALL

SELECT 
    performance_month, 'Channel', 'NULL', channel, channel, 'MOFU', 'ROAS',
    REPLACE(CAST(ROUND(current_roas, 6) AS VARCHAR(50)), '.', ','), 'ATOMIC_RATIO'
FROM gold.funnel_channels_roas -- MOFU
WHERE current_roas IS NOT NULL

UNION ALL

SELECT 
    performance_month, 'Channel', 'NULL', acquisition_channel, acquisition_channel, 'TOFU', 'ROAS',
    REPLACE(CAST(ROUND(current_roas, 6) AS VARCHAR(50)), '.', ','), 'ATOMIC_RATIO'
FROM gold.acquisition_channels_roas -- TOFU
WHERE current_roas IS NOT NULL

UNION ALL

SELECT 
    performance_month, 'Channel', 'NULL', last_touch_channel, last_touch_channel, 'BOFU', 'ROAS',
    REPLACE(CAST(ROUND(current_roas, 6) AS VARCHAR(50)), '.', ','), 'ATOMIC_RATIO'
FROM gold.last_touch_channels_roas -- BOFU
WHERE current_roas IS NOT NULL

-- Spend by Funnel Stage (uses same spend data, attributed by funnel context)
UNION ALL

SELECT 
    performance_month, 'Channel', 'NULL', channel, channel, 'MOFU', 'Spend',
    REPLACE(CAST(ROUND(current_spend, 6) AS VARCHAR(50)), '.', ','), 'ATOMIC_VALUE'
FROM gold.funnel_channels_roas -- MOFU  -- Spend comes from ROAS view (has spend data)
WHERE current_spend IS NOT NULL

UNION ALL

SELECT 
    performance_month, 'Channel', 'NULL', acquisition_channel, acquisition_channel, 'TOFU', 'Spend',
    REPLACE(CAST(ROUND(current_spend, 6) AS VARCHAR(50)), '.', ','), 'ATOMIC_VALUE'
FROM gold.acquisition_channels_roas -- TOFU
WHERE current_spend IS NOT NULL

UNION ALL

SELECT 
    performance_month, 'Channel', 'NULL', last_touch_channel, last_touch_channel, 'BOFU', 'Spend',
    REPLACE(CAST(ROUND(current_spend, 6) AS VARCHAR(50)), '.', ','), 'ATOMIC_VALUE'
FROM gold.last_touch_channels_roas -- BOFU
WHERE current_spend IS NOT NULL

-- CVR by Funnel Stage
UNION ALL

SELECT 
    performance_month, 'Channel', 'NULL', channel, channel, 'MOFU', 'CVR',
    REPLACE(CAST(ROUND(current_cvr, 6) AS VARCHAR(50)), '.', ','), 'ATOMIC_RATIO'
FROM gold.channels_cvr
WHERE current_cvr IS NOT NULL

UNION ALL

SELECT 
    performance_month, 'Channel', 'NULL', channel, channel, 'TOFU', 'CVR',
    REPLACE(CAST(ROUND(current_cvr, 6) AS VARCHAR(50)), '.', ','), 'ATOMIC_RATIO'
FROM gold.channels_tofu_cvr
WHERE current_cvr IS NOT NULL

UNION ALL

SELECT 
    performance_month, 'Channel', 'NULL', channel, channel, 'BOFU', 'CVR',
    REPLACE(CAST(ROUND(current_cvr, 6) AS VARCHAR(50)), '.', ','), 'ATOMIC_RATIO'
FROM gold.channels_bofu_cvr
WHERE current_cvr IS NOT NULL

-- CAC (Always ALL - Acquisition-based)
UNION ALL

SELECT 
    performance_month, 'Channel', 'NULL', acquisition_channel AS channel, acquisition_channel AS channel, 'ALL', 'CAC',
    REPLACE(CAST(ROUND(current_cac, 6) AS VARCHAR(50)), '.', ','), 'ATOMIC_RATIO'
FROM gold.channels_cac
WHERE current_cac IS NOT NULL

-- CPC (Always ALL - Click-based)
UNION ALL

SELECT 
    performance_month, 'Channel', 'NULL', click_channel AS channel, click_channel AS channel, 'ALL', 'CPC',
    REPLACE(CAST(ROUND(current_cpc, 6) AS VARCHAR(50)), '.', ','), 'ATOMIC_RATIO'
FROM gold.channels_cpc
WHERE current_cpc IS NOT NULL

-- CTR (Always ALL - Click-based)
UNION ALL

SELECT 
    performance_month, 'Channel', 'NULL', channel, channel, 'ALL', 'CTR',
    REPLACE(CAST(ROUND(current_ctr, 6) AS VARCHAR(50)), '.', ','), 'ATOMIC_RATIO'
FROM gold.channels_ctr
WHERE current_ctr IS NOT NULL

-- CPA (Always ALL - Cost per Action)
UNION ALL

SELECT 
    performance_month, 'Channel', 'NULL', last_touch_channel, last_touch_channel, 'ALL', 'CPA',
    REPLACE(CAST(ROUND(current_cpa, 6) AS VARCHAR(50)), '.', ','), 'ATOMIC_RATIO'
FROM gold.channels_cpa
WHERE current_cpa IS NOT NULL

-- =============================================================================
-- CAMPAIGN-LEVEL KPIS
-- =============================================================================

-- Campaign Revenue by Funnel Stage
UNION ALL

SELECT 
    r.performance_month, 'Campaign', CAST(r.campaign_id AS VARCHAR(10)), r.campaign_name, c.channel, 'MOFU', 'Revenue',
    REPLACE(CAST(ROUND(r.current_revenue, 6) AS VARCHAR(50)), '.', ','), 'ATOMIC_VALUE'
FROM gold.funnel_campaigns_performance r-- MOFU
LEFT JOIN gold.dim_campaign c 
ON r.campaign_id = c.campaign_id
WHERE r.current_revenue IS NOT NULL

UNION ALL

SELECT 
    r.performance_month, 'Campaign', CAST(r.acquisition_campaign AS VARCHAR(10)), r.campaign_name, c.channel, 'TOFU', 'Revenue',
    REPLACE(CAST(ROUND(r.current_revenue, 6) AS VARCHAR(50)), '.', ','), 'ATOMIC_VALUE'
FROM gold.acquisition_campaigns_performance r -- TOFU
LEFT JOIN gold.dim_campaign c 
ON r.acquisition_campaign = c.campaign_id
WHERE current_revenue IS NOT NULL

UNION ALL

SELECT 
    r.performance_month, 'Campaign', CAST(r.last_touch_campaign AS VARCHAR(10)), r.campaign_name, c.channel, 'BOFU', 'Revenue',
    REPLACE(CAST(ROUND(current_revenue, 6) AS VARCHAR(50)), '.', ','), 'ATOMIC_VALUE'
FROM gold.last_touch_campaigns_performance r -- BOFU
LEFT JOIN gold.dim_campaign c 
ON r.last_touch_campaign = c.campaign_id
WHERE current_revenue IS NOT NULL

-- Campaign ROAS by Funnel Stage
UNION ALL

SELECT 
    r.performance_month, 'Campaign', CAST(r.campaign_id AS VARCHAR(10)), r.campaign_name, c.channel, 'MOFU', 'ROAS',
    REPLACE(CAST(ROUND(r.current_roas, 6) AS VARCHAR(50)), '.', ','), 'ATOMIC_RATIO'
FROM gold.funnel_campaigns_roas r -- MOFU
LEFT JOIN gold.dim_campaign c 
ON r.campaign_id = c.campaign_id
WHERE r.current_roas IS NOT NULL

UNION ALL

SELECT 
    r.performance_month, 'Campaign', CAST(r.acquisition_campaign AS VARCHAR(10)), r.campaign_name, c.channel, 'TOFU', 'ROAS',
    REPLACE(CAST(ROUND(current_roas, 6) AS VARCHAR(50)), '.', ','), 'ATOMIC_RATIO'
FROM gold.acquisition_campaigns_roas r -- TOFU
LEFT JOIN gold.dim_campaign c 
ON r.acquisition_campaign = c.campaign_id
WHERE r.current_roas IS NOT NULL

UNION ALL

SELECT 
    r.performance_month, 'Campaign', CAST(r.last_touch_campaign AS VARCHAR(10)), r.campaign_name, c.channel, 'BOFU', 'ROAS',
    REPLACE(CAST(ROUND(r.current_roas, 6) AS VARCHAR(50)), '.', ','), 'ATOMIC_RATIO'
FROM gold.last_touch_campaigns_roas r -- BOFU
LEFT JOIN gold.dim_campaign c 
ON r.last_touch_campaign = c.campaign_id
WHERE r.current_roas IS NOT NULL

-- Campaign Spend by Funnel Stage
UNION ALL

SELECT 
    r.performance_month, 'Campaign', CAST(r.campaign_id AS VARCHAR(10)), r.campaign_name, c.channel, 'MOFU', 'Spend',
    REPLACE(CAST(ROUND(r.current_spend, 6) AS VARCHAR(50)), '.', ','), 'ATOMIC_VALUE'
FROM gold.funnel_campaigns_roas r -- MOFU
LEFT JOIN gold.dim_campaign c 
ON r.campaign_id = c.campaign_id
WHERE r.current_spend IS NOT NULL

UNION ALL

SELECT 
    r.performance_month, 'Campaign', CAST(r.acquisition_campaign AS VARCHAR(10)), r.campaign_name, c.channel, 'TOFU', 'Spend',
    REPLACE(CAST(ROUND(r.current_spend, 6) AS VARCHAR(50)), '.', ','), 'ATOMIC_VALUE'
FROM gold.acquisition_campaigns_roas r -- TOFU
LEFT JOIN gold.dim_campaign c 
ON r.acquisition_campaign = c.campaign_id
WHERE r.current_spend IS NOT NULL

UNION ALL

SELECT 
    r.performance_month, 'Campaign', CAST(r.last_touch_campaign AS VARCHAR(10)), r.campaign_name, c.channel, 'BOFU', 'Spend',
    REPLACE(CAST(ROUND(r.current_spend, 6) AS VARCHAR(50)), '.', ','), 'ATOMIC_VALUE'
FROM gold.last_touch_campaigns_roas r -- BOFU
LEFT JOIN gold.dim_campaign c 
ON r.last_touch_campaign = c.campaign_id
WHERE r.current_spend IS NOT NULL

-- Campaign CVR by Funnel Stage
UNION ALL

SELECT 
    r.performance_month, 'Campaign', CAST(r.campaign_id AS VARCHAR(10)), r.campaign_name, c.channel, 'MOFU', 'CVR',
    REPLACE(CAST(ROUND(r.current_cvr, 6) AS VARCHAR(50)), '.', ','), 'ATOMIC_RATIO'
FROM gold.campaigns_cvr r
LEFT JOIN gold.dim_campaign c 
ON r.campaign_id = c.campaign_id
WHERE r.current_cvr IS NOT NULL

UNION ALL

SELECT 
    r.performance_month, 'Campaign', CAST(r.campaign_id AS VARCHAR(10)), r.campaign_name, c.channel, 'TOFU', 'CVR',
    REPLACE(CAST(ROUND(r.current_cvr, 6) AS VARCHAR(50)), '.', ','), 'ATOMIC_RATIO'
FROM gold.campaigns_tofu_cvr r
LEFT JOIN gold.dim_campaign c 
ON r.campaign_id = c.campaign_id
WHERE r.current_cvr IS NOT NULL

UNION ALL

SELECT 
    r.performance_month, 'Campaign', CAST(r.campaign_id AS VARCHAR(10)), r.campaign_name, c.channel, 'BOFU', 'CVR',
    REPLACE(CAST(ROUND(r.current_cvr, 6) AS VARCHAR(50)), '.', ','), 'ATOMIC_RATIO'
FROM gold.campaigns_bofu_cvr r
LEFT JOIN gold.dim_campaign c 
ON r.campaign_id = c.campaign_id
WHERE r.current_cvr IS NOT NULL

-- Campaign CAC (Always ALL)
UNION ALL

SELECT 
    r.performance_month, 'Campaign', CAST(r.acquisition_campaign AS VARCHAR(10)), r.campaign_name, c.channel, 'ALL', 'CAC',
    REPLACE(CAST(ROUND(r.current_cac, 6) AS VARCHAR(50)), '.', ','), 'ATOMIC_RATIO'
FROM gold.campaigns_cac r 
LEFT JOIN gold.dim_campaign c 
ON r.acquisition_campaign = c.campaign_id
WHERE r.current_cac IS NOT NULL

-- Campaign CPC (Always ALL)
UNION ALL

SELECT 
    r.performance_month, 'Campaign', CAST(r.campaign_id AS VARCHAR(10)), r.campaign_name, c.channel, 'ALL', 'CPC',
    REPLACE(CAST(ROUND(r.current_cpc, 6) AS VARCHAR(50)), '.', ','), 'ATOMIC_RATIO'
FROM gold.campaigns_cpc r
LEFT JOIN gold.dim_campaign c 
ON r.campaign_id = c.campaign_id
WHERE r.current_cpc IS NOT NULL

-- Campaign CTR (Always ALL)
UNION ALL

SELECT 
    r.performance_month, 'Campaign', CAST(r.campaign_id AS VARCHAR(10)), r.campaign_name, c.channel, 'ALL', 'CTR',
    REPLACE(CAST(ROUND(r.current_ctr, 6) AS VARCHAR(50)), '.', ','), 'ATOMIC_RATIO'
FROM gold.campaigns_ctr r
LEFT JOIN gold.dim_campaign c 
ON r.campaign_id = c.campaign_id
WHERE r.current_ctr IS NOT NULL

-- Campaign CPA (Always ALL)
UNION ALL

SELECT 
    r.performance_month, 'Campaign', CAST(r.last_touch_campaign AS VARCHAR(10)), r.campaign_name, c.channel, 'ALL', 'CPA',
    REPLACE(CAST(ROUND(r.current_cpa, 6) AS VARCHAR(50)), '.', ','), 'ATOMIC_RATIO'
FROM gold.campaigns_cpa r
LEFT JOIN gold.dim_campaign c 
ON r.last_touch_campaign = c.campaign_id
WHERE r.current_cpa IS NOT NULL

;
GO


SELECT * FROM gold.dashboard_one_semantics;

/*
================================================================================
KPI ROW - MONTHLY TOTALS FOR DASHBOARD ONE HEADER
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

/*
===============================================================================
2) Channel Summary: Efficiency Table
===============================================================================
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
3) Cohort Heatmap (based on gold.fact_ltv_cohort)
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

/*
===============================================================================
Dashboard 3: Customer Journey Analysis — CSV-Export Views (Corrected)
===============================================================================
Purpose:
    - Tableau-ready views for CSV export with German decimal formatting.

Dependencies:
    - gold.fact_conversion_paths (from Script 10)

===============================================================================
*/
USE marketing_dw;
GO

/*
===============================================================================
1) KPI Row
===============================================================================
*/
DROP VIEW IF EXISTS gold.dashboard_journey_kpi;
GO

CREATE VIEW gold.dashboard_journey_kpi AS
WITH base_metrics AS (
    SELECT
        COUNT(*) AS total_conversions,
        SUM(CASE WHEN purchase_type = 'First' THEN 1 ELSE 0 END) AS first_conversions,
        SUM(CASE WHEN purchase_type = 'Repeat' THEN 1 ELSE 0 END) AS repeat_conversions,
        SUM(CASE WHEN touchpoints_to_conversion <= 4 THEN 1 ELSE 0 END) AS quick_conversions,
        AVG(CASE WHEN purchase_type = 'First' 
            THEN touchpoints_to_conversion * 1.0 END) AS avg_path_first,
        AVG(CASE WHEN purchase_type = 'Repeat' 
            THEN touchpoints_to_conversion * 1.0 END) AS avg_path_repeat
    FROM gold.fact_conversion_paths
)
SELECT
    REPLACE(CAST(
        ROUND(first_conversions * 100.0 / NULLIF(total_conversions, 0), 0)
    AS VARCHAR(50)), '.', ',') AS first_buyer_pct,
    REPLACE(CAST(
        ROUND(quick_conversions * 100.0 / NULLIF(total_conversions, 0), 0)
    AS VARCHAR(50)), '.', ',') AS quick_conversion_pct,
    REPLACE(CAST(
        ROUND((avg_path_repeat - avg_path_first) / NULLIF(avg_path_first, 0) * 100, 0)
    AS VARCHAR(50)), '.', ',') AS repeat_efficiency_pct,
    REPLACE(CAST(ROUND(avg_path_first, 1) AS VARCHAR(50)), '.', ',') AS avg_path_first,
    REPLACE(CAST(ROUND(avg_path_repeat, 1) AS VARCHAR(50)), '.', ',') AS avg_path_repeat,
FROM base_metrics;
GO

SELECT * FROM gold.dashboard_journey_kpi;
GO


/*
===============================================================================
2) Path Length Trend: First vs Repeat by Month
===============================================================================
*/
DROP VIEW IF EXISTS gold.dashboard_path_trend;
GO

CREATE VIEW gold.dashboard_path_trend AS
SELECT
    performance_month,
    purchase_type,
    COUNT(*) AS purchase_count,
    REPLACE(CAST(
        ROUND(AVG(touchpoints_to_conversion * 1.0), 2)
    AS VARCHAR(50)), '.', ',') AS avg_path_length,
    AVG(touchpoints_to_conversion * 1.0) AS sort_path_length
FROM gold.fact_conversion_paths
GROUP BY performance_month, purchase_type;
GO

SELECT * 
FROM gold.dashboard_path_trend
ORDER BY performance_month, purchase_type;
GO


/*
===============================================================================
3) Closing Effectiveness (Last-Touch Channel)
===============================================================================
*/
DROP VIEW IF EXISTS gold.dashboard_closing_effectiveness;
GO

CREATE VIEW gold.dashboard_closing_effectiveness AS
SELECT
    last_touch_channel AS channel,
    COUNT(*) AS purchase_count,
    REPLACE(CAST(
        ROUND(AVG(touchpoints_to_conversion * 1.0), 2)
    AS VARCHAR(50)), '.', ',') AS avg_path_length,
    AVG(touchpoints_to_conversion * 1.0) AS sort_path_length
FROM gold.fact_conversion_paths
WHERE performance_month = '2024-01-01'
  AND purchase_type = 'First'
  AND last_touch_channel IS NOT NULL
GROUP BY last_touch_channel;
GO

SELECT * 
FROM gold.dashboard_closing_effectiveness
ORDER BY sort_path_length ASC;
GO


/*
===============================================================================
4) Lead Quality (Acquisition Channel)
===============================================================================
*/
DROP VIEW IF EXISTS gold.dashboard_lead_quality;
GO

CREATE VIEW gold.dashboard_lead_quality AS
SELECT
    acquisition_channel AS channel,
    COUNT(*) AS purchase_count,
    REPLACE(CAST(
        ROUND(AVG(touchpoints_to_conversion * 1.0), 2)
    AS VARCHAR(50)), '.', ',') AS avg_path_length,
    AVG(touchpoints_to_conversion * 1.0) AS sort_path_length
FROM gold.fact_conversion_paths
WHERE performance_month = '2024-01-01'
  AND purchase_type = 'First'
  AND acquisition_channel IS NOT NULL
GROUP BY acquisition_channel;
GO

SELECT * 
FROM gold.dashboard_lead_quality
ORDER BY sort_path_length ASC;
GO


/*
===============================================================================
5) Path Length Distribution (Histogram)
===============================================================================
*/
DROP VIEW IF EXISTS gold.dashboard_path_distribution;
GO

CREATE VIEW gold.dashboard_path_distribution AS
SELECT
    touchpoints_to_conversion,
    COUNT(*) AS conversion_count,
    REPLACE(CAST(
        ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 1)
    AS VARCHAR(50)), '.', ',') AS pct_of_total
FROM gold.fact_conversion_paths
GROUP BY touchpoints_to_conversion;
GO

SELECT * 
FROM gold.dashboard_path_distribution
ORDER BY touchpoints_to_conversion;
GO




