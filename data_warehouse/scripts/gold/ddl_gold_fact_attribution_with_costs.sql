/*
===============================================================================
DDL Script: Create Gold Attribution Tables WITH Cost Attribution
===============================================================================
Script Purpose:
    This script creates IMPROVED attribution fact tables that include 
    proportional cost attribution alongside revenue attribution.
    
    This addresses a critical limitation in the original attribution model:
    - Original: Revenue was distributed across touchpoints, but costs remained 
      at campaign/day level, leading to distorted ROI/ROAS calculations.
    - Improved: Both revenue AND costs are proportionally attributed to 
      touchpoints, enabling accurate efficiency metrics.

Key Improvements:
    1. Cost Attribution: Daily campaign costs are distributed proportionally 
       across all touchpoints for that campaign on that day.
    2. Accurate KPIs: ROI and ROAS can now be calculated correctly at the 
       touchpoint level.
    3. Backward Compatible: Original tables remain unchanged; these are 
       enhanced versions.

This attribution model focuses on PAID MARKETING channels only.
    Excluded Channels (Free/Organic):
    - Direct (user types URL directly)
    - Email (owned channel, no media cost)
    - Organic Search (SEO, no media cost)
    - Referral (earned traffic, no media cost)
    Rationale:
    - ROAS/ROI calculations require media costs
    - Including free channels would distort efficiency metrics
    - Standard practice in paid marketing attribution
    For full customer journey analysis including organic channels,
    use fact_attribution_linear (original table without costs).

Tables Created:
    - gold.fact_attribution_linear_with_costs
    
Dependencies:
    - gold.fact_spend (campaign daily costs)
    - gold.fact_touchpath (touchpoint journey data)
    - gold.fact_attribution_linear (original revenue attribution)
    
Usage Example:
    -- Correct ROI calculation with attributed costs:
    SELECT 
        channel,
        SUM(revenue_share) AS attributed_revenue,
        SUM(cost_share) AS attributed_costs,
        (SUM(revenue_share) - SUM(cost_share)) / NULLIF(SUM(cost_share), 0) AS roi
    FROM gold.fact_attribution_linear_with_costs
    GROUP BY channel;

Limitations:
  Touchpoints with NULL campaign_id receive cost_share = 0 because 
  NULL = NULL evaluates to FALSE in SQL joins. A channel-level fallback 
  for unattributed spend could improve cost coverage but was not 
  implemented to maintain attribution precision.

===============================================================================
*/

USE marketing_dw;
GO

/*
===============================================================================
Create Table: gold.fact_attribution_linear_with_costs
===============================================================================
Purpose: 
    Enhanced version of fact_attribution_linear that includes proportional
    cost attribution alongside revenue attribution.

Granularity: 
    One row per touchpoint in a converting journey (same as original)

New Columns:
    - cost_share: Proportionally attributed cost for this touchpoint
    - roi_attributed: (revenue_share - cost_share) / cost_share
    - roas_attributed: revenue_share / cost_share
===============================================================================
*/

IF OBJECT_ID('gold.fact_attribution_linear_with_costs', 'U') IS NOT NULL
    DROP TABLE gold.fact_attribution_linear_with_costs;
GO

CREATE TABLE gold.fact_attribution_linear_with_costs (
    attribution_key        INT IDENTITY(1,1) PRIMARY KEY,
    user_id                INT           NOT NULL,
    purchase_id            INT           NOT NULL,
    touchpoint_number      INT           NOT NULL,
    channel                NVARCHAR(50)  NOT NULL,
    campaign_id            INT           NULL,
    interaction_type       NVARCHAR(50)  NOT NULL,
    touchpoint_time        DATETIME2     NOT NULL,
    
    -- Revenue Attribution (from original table)
    revenue_share          DECIMAL(12,2) NOT NULL,
    total_revenue          DECIMAL(12,2) NOT NULL,
    touchpoints_in_path    INT           NOT NULL,
    purchase_date          DATE          NOT NULL,
    
    -- Cost Attribution (NEW! - The only new column)
    cost_share             DECIMAL(12,2) NULL  -- Can be NULL if no campaign_id or no spend data
);
GO

/*
===============================================================================
Load Logic: Populate fact_attribution_linear_with_costs
===============================================================================
Strategy:
    1. Start with original attribution data (revenue already distributed)
    2. Calculate cost per touchpoint:
       - For each campaign+day: total spend ÷ number of touchpoints
       - Assign this cost_share to each touchpoint
    3. Calculate derived KPIs (ROI, ROAS)

Cost Attribution Formula:
    cost_share = (campaign_daily_spend) / (touchpoints_for_that_campaign_on_that_day)

Example:
    Campaign 5 on 2024-01-15:
    - Total spend: €100
    - Touchpoints on that day: 20
    - Each touchpoint gets: €100 / 20 = €5 cost_share
===============================================================================
*/

-- Step 1: Calculate touchpoint counts per campaign per day
IF OBJECT_ID('tempdb..#touchpoint_counts', 'U') IS NOT NULL
    DROP TABLE #touchpoint_counts;

WITH touchpoint_daily AS (
    SELECT
        campaign_id,
        CAST(touchpoint_time AS DATE) AS touchpoint_date,
        COUNT(*) AS touchpoint_count
    FROM gold.fact_attribution_linear
    WHERE campaign_id IS NOT NULL
        AND channel NOT IN ('Direct','Email','Organic Search','Referral')  
    GROUP BY campaign_id, CAST(touchpoint_time AS DATE)
)
SELECT * 
INTO #touchpoint_counts
FROM touchpoint_daily;

-- Step 2: Calculate cost per touchpoint
IF OBJECT_ID('tempdb..#cost_per_touchpoint', 'U') IS NOT NULL
    DROP TABLE #cost_per_touchpoint;

WITH spend_aggregated AS (
    SELECT
        campaign_id,
        spend_date,
        SUM(spend) AS daily_spend
    FROM gold.fact_spend
    WHERE campaign_id IS NOT NULL
        AND channel NOT IN ('Direct','Email','Organic Search','Referral') 
    GROUP BY campaign_id, spend_date
)
SELECT
    s.campaign_id,
    s.spend_date,
    s.daily_spend,
    tc.touchpoint_count,
    s.daily_spend / NULLIF(tc.touchpoint_count, 0) AS cost_per_touchpoint
INTO #cost_per_touchpoint
FROM spend_aggregated s
LEFT JOIN #touchpoint_counts tc
    ON s.campaign_id = tc.campaign_id
    AND s.spend_date = tc.touchpoint_date;

-- Step 3: Insert into final table with cost attribution
-- Step 3: Insert into final table with cost attribution
INSERT INTO gold.fact_attribution_linear_with_costs (
    user_id,
    purchase_id,
    touchpoint_number,
    channel,
    campaign_id,
    interaction_type,
    touchpoint_time,
    revenue_share,
    total_revenue,
    touchpoints_in_path,
    purchase_date,
    cost_share
)
SELECT
    a.user_id,
    a.purchase_id,
    a.touchpoint_number,
    a.channel,
    a.campaign_id,
    a.interaction_type,
    a.touchpoint_time,
    a.revenue_share,
    a.total_revenue,
    a.touchpoints_in_path,
    a.purchase_date,
    COALESCE(c.cost_per_touchpoint, 0) AS cost_share
FROM gold.fact_attribution_linear a
LEFT JOIN #cost_per_touchpoint c
    ON a.campaign_id = c.campaign_id
    AND CAST(a.touchpoint_time AS DATE) = c.spend_date
WHERE a.channel NOT IN ('Direct','Email','Organic Search','Referral');  

-- Cleanup temp tables
DROP TABLE #touchpoint_counts;
DROP TABLE #cost_per_touchpoint;

GO

/*
===============================================================================
Quality Checks
===============================================================================
*/

-- 1) Row count comparison
PRINT '========================================';
PRINT 'Quality Check 1: Row Count Comparison';
PRINT '========================================';
SELECT 
    'Original' AS table_name,
    COUNT(*) AS row_count
FROM gold.fact_attribution_linear
UNION ALL
SELECT 
    'With Costs' AS table_name,
    COUNT(*) AS row_count
FROM gold.fact_attribution_linear_with_costs;

-- 2) Cost attribution coverage
PRINT '';
PRINT '========================================';
PRINT 'Quality Check 2: Cost Attribution Coverage';
PRINT '========================================';
SELECT
    COUNT(*) AS total_rows,
    SUM(CASE WHEN cost_share > 0 THEN 1 ELSE 0 END) AS rows_with_costs,
    SUM(CASE WHEN cost_share IS NULL OR cost_share = 0 THEN 1 ELSE 0 END) AS rows_without_costs,
    CAST(SUM(CASE WHEN cost_share > 0 THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS pct_with_costs
FROM gold.fact_attribution_linear_with_costs;

-- 3) Revenue vs Cost totals
PRINT '';
PRINT '========================================';
PRINT 'Quality Check 3: Total Revenue vs Total Costs';
PRINT '========================================';
SELECT
    SUM(revenue_share) AS total_attributed_revenue,
    SUM(cost_share) AS total_attributed_costs,
    SUM(revenue_share) - SUM(cost_share) AS total_profit,
    (SUM(revenue_share) - SUM(cost_share)) / NULLIF(SUM(cost_share), 0) AS overall_roi
FROM gold.fact_attribution_linear_with_costs;

-- 4) Cost attribution by channel
PRINT '';
PRINT '========================================';
PRINT 'Quality Check 4: Cost Attribution by Channel';
PRINT '========================================';
SELECT
    channel,
    COUNT(*) AS touchpoints,
    SUM(revenue_share) AS attributed_revenue,
    SUM(cost_share) AS attributed_costs,
    SUM(revenue_share) / NULLIF(SUM(cost_share), 0) AS roas,
    (SUM(revenue_share) - SUM(cost_share)) / NULLIF(SUM(cost_share), 0) AS roi
FROM gold.fact_attribution_linear_with_costs
GROUP BY channel
ORDER BY attributed_revenue DESC;


PRINT '';
PRINT '========================================';
PRINT 'Table Created and Loaded Successfully!';
PRINT '========================================';
GO
