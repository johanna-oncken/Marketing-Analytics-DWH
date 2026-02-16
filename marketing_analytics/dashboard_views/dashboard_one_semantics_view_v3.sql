/*
================================================================================
DASHBOARD ONE SEMANTICS - SEMANTIC LAYER VIEW (Compact Version)
================================================================================
Purpose: Long-format unified view for Tableau Dashboard 1 (Budget Allocation)

KPI Structure:
    TOFU/MOFU/BOFU: Revenue, ROAS, Spend, CVR, MoM_Revenue
    ALL:            CAC, CPC, CTR

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


/*
================================================================================
CSV EXPORT INSTRUCTIONS
================================================================================
Option 1: SSMS Export
    1. Run: SELECT * FROM gold.dashboard_one_semantics
    2. Right-click results grid → "Save Results As..."
    3. Save as CSV
    4. Open in text editor, replace commas with semicolons if needed

Option 2: BCP Export (Command Line)
    bcp "SELECT * FROM gold.dashboard_one_semantics" queryout "dashboard_one_semantics.csv" -c -t";" -S YOUR_SERVER -d YOUR_DATABASE -T

Option 3: SQLCMD Export
    sqlcmd -S YOUR_SERVER -d YOUR_DATABASE -Q "SET NOCOUNT ON; SELECT * FROM gold.dashboard_one_semantics" -o "dashboard_one_semantics.csv" -s";" -W
================================================================================
*/

-- Quick test query:
/*
SELECT TOP 100 * FROM gold.dashboard_one_semantics ORDER BY kpi_name, funnel_stage, entity_type, month_date;*/


SELECT * FROM gold.dashboard_one_semantics;


