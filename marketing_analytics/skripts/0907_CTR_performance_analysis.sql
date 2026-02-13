/*
===============================================================================
CTR Click-Through Rate Performance Analysis (Month-over-Month)
===============================================================================
Purpose:
    - To measure the CTR performance of marketing components such as campaigns and channels over time.
    - For benchmarking and identifying high-performing entities.
    - To track monthly 2024 trends and growth.

SQL Functions Used:
    - LAG(): Accesses data from previous rows.
    - AVG() OVER(): Computes average values within partitions.
    - CASE: Defines conditional logic for trend analysis. 

Queries: 
    1) CTR overall 
    2) CTR Performance monthly
    3.1) Monthly CTR Performance and MOM Analysis by Channels 
    3.2) Top Ten Channels by Monthly CTR Improvements 
    3.3) Top Ten Channels by Monthly CTR Declines
    4.1) Monthly CTR Performance and MOM Analysis by Campaigns 
    4.2) Top Ten Campaigns by Monthly CTR Improvements 
    4.3) Top Ten Campaigns by Monthly CTR Declines 

💡 Disclaimer: 
    Due to synthetic data, there are a lot more clicks than there are impressions, resulting in a CTR > 100% .
    Therefore, we should see the CTR results more as click intensity than as "CTR"(click rate).

===============================================================================
*/
USE marketing_dw; 
GO

/*
===============================================================================
1) CTR overall
===============================================================================
*/
SELECT 
    (SELECT COUNT(click_id) FROM gold.fact_clicks) AS clicks,
    (SELECT COUNT(interaction_type) FROM gold.fact_touchpoints
    WHERE interaction_type = 'Impression') AS impressions,
    (SELECT COUNT(click_id) FROM gold.fact_clicks) * 1.0
    / 
    (SELECT COUNT(interaction_type) FROM gold.fact_touchpoints
    WHERE interaction_type = 'Impression') AS ctr;


/*
===============================================================================
2) CTR Performance monthly
===============================================================================
*/
DROP VIEW IF EXISTS gold.ctr;
GO

CREATE VIEW gold.ctr AS
WITH monthly_clicks AS (
SELECT
    DATEFROMPARTS(d.year, d.month, 1) AS performance_month, 
    COUNT(f.click_id) AS clicks
FROM gold.fact_clicks f
LEFT JOIN gold.dim_date d 
ON f.date_key = d.date_key
GROUP BY DATEFROMPARTS(d.year, d.month, 1)
), 
monthly_impressions AS ( 
SELECT 
    DATEFROMPARTS(YEAR(f.touchpoint_time), MONTH(f.touchpoint_time), 1) AS performance_month,
    COUNT(f.interaction_type) AS current_impressions
FROM gold.fact_touchpoints f 
WHERE f.interaction_type = 'Impression' --filter for impressions
GROUP BY DATEFROMPARTS(YEAR(f.touchpoint_time), MONTH(f.touchpoint_time), 1)
), 
ctr_metrics AS (
SELECT
    COALESCE(c.performance_month, i.performance_month) AS performance_month, 
    c.clicks AS current_clicks,
    i.current_impressions,
    c.clicks * 1.0 /NULLIF(i.current_impressions, 0) AS ctr
FROM monthly_clicks c
FULL JOIN monthly_impressions i 
ON c.performance_month = i.performance_month 
)

SELECT 
    performance_month,
    current_clicks,
    current_impressions,
    ctr AS current_ctr,
    AVG(ctr) OVER() AS avg_ctr,
    (ctr) - AVG(ctr) OVER() AS diff_avg,
    CASE 
        WHEN (ctr) - AVG(ctr) OVER() > 0 THEN 'Above Avg'
        WHEN (ctr) - AVG(ctr) OVER() < 0 THEN 'Below Avg' 
        ELSE 'Equals Average'
    END AS avg_change,
 -- Month-over_Month Analysis 
    LAG(ctr) OVER(ORDER BY performance_month) AS pm_ctr, 
    (ctr) - LAG(ctr) OVER(ORDER BY performance_month) AS diff_pm_ctr,
    CASE 
        WHEN (ctr) - LAG(ctr) OVER(ORDER BY performance_month) > 0 THEN 'Improved'
        WHEN (ctr) - LAG(ctr) OVER(ORDER BY performance_month) < 0 THEN 'Decreased'
        ELSE 'No Change'
    END AS pm_change,
    ROUND(
        CASE 
            WHEN LAG(ctr) OVER(ORDER BY performance_month) = 0 THEN NULL 
            ELSE ((ctr) - LAG(ctr) OVER(ORDER BY performance_month))/LAG(ctr) OVER(ORDER BY performance_month)*100 
        END
    ,2) AS mom_percentage
FROM ctr_metrics;
GO

SELECT *
FROM gold.ctr
ORDER BY performance_month;
GO


/*
===============================================================================
3) CHANNELS
===============================================================================
*/
-- 3.1) MoM by Monthly Clicks and Impressions
--      Analyze Month-over-Month CTR channel performance 
DROP VIEW IF EXISTS gold.channels_ctr;
GO

CREATE VIEW gold.channels_ctr AS
WITH monthly_clicks AS (
SELECT
    DATEFROMPARTS(d.year, d.month, 1) AS performance_month, 
    f.click_channel,
    COUNT(f.click_id) AS clicks
FROM gold.fact_clicks f
LEFT JOIN gold.dim_date d 
ON f.date_key = d.date_key
WHERE f.click_channel IS NOT NULL
GROUP BY DATEFROMPARTS(d.year, d.month, 1), f.click_channel
), 
monthly_impressions AS ( 
SELECT 
    DATEFROMPARTS(YEAR(f.touchpoint_time), MONTH(f.touchpoint_time), 1) AS performance_month,
    f.channel,
    COUNT(f.interaction_type) AS current_impressions
FROM gold.fact_touchpoints f 
WHERE f.interaction_type = 'Impression' AND f.channel IS NOT NULL --filter for impressions
GROUP BY DATEFROMPARTS(YEAR(f.touchpoint_time), MONTH(f.touchpoint_time), 1), f.channel
), 
ctr_metrics AS (
SELECT
    COALESCE(c.performance_month, i.performance_month) AS performance_month,
    COALESCE(i.channel, c.click_channel) AS channel,
    c.clicks AS current_clicks,
    i.current_impressions,
    c.clicks * 1.0 /NULLIF(i.current_impressions, 0) AS ctr
FROM monthly_clicks c
FULL JOIN monthly_impressions i 
ON c.performance_month = i.performance_month 
    AND c.click_channel = i.channel
)

SELECT 
    performance_month,
    channel,
    current_clicks,
    current_impressions,
    ctr AS current_ctr,
    AVG(ctr) OVER(PARTITION BY channel) AS avg_ctr,
    (ctr) - AVG(ctr) OVER(PARTITION BY channel) AS diff_avg,
    CASE 
        WHEN (ctr) - AVG(ctr) OVER(PARTITION BY channel) > 0 THEN 'Above Avg'
        WHEN (ctr) - AVG(ctr) OVER(PARTITION BY channel) < 0 THEN 'Below Avg' 
        ELSE 'Equals Average'
    END AS avg_change,
    -- Month-over_Month Analysis 
    LAG(ctr) OVER(PARTITION BY channel ORDER BY performance_month) AS pm_ctr, 
    (ctr) - LAG(ctr) OVER(PARTITION BY channel ORDER BY performance_month) AS diff_pm_ctr,
    CASE 
        WHEN (ctr) - LAG(ctr) OVER(PARTITION BY channel ORDER BY performance_month) > 0 THEN 'Improved'
        WHEN (ctr) - LAG(ctr) OVER(PARTITION BY channel ORDER BY performance_month) < 0 THEN 'Decreased'
        ELSE 'No Change'
    END AS pm_change,
    ROUND(
        CASE 
            WHEN LAG(ctr) OVER(PARTITION BY channel ORDER BY performance_month) = 0 THEN NULL 
            ELSE ((ctr) - LAG(ctr) OVER(PARTITION BY channel ORDER BY performance_month))/LAG(ctr) OVER(PARTITION BY channel ORDER BY performance_month)*100 
        END
    ,2) AS mom_percentage
FROM ctr_metrics
WHERE channel IS NOT NULL;
GO

SELECT *
FROM gold.channels_ctr
ORDER BY channel, performance_month;
GO

-- 3.2) Top 10 Improvements MoM CTR channels
SELECT TOP 10 *
FROM gold.channels_ctr
WHERE diff_pm_ctr IS NOT NULL
ORDER BY diff_pm_ctr DESC; 

SELECT TOP 10 *
FROM gold.channels_ctr
WHERE pm_ctr IS NOT NULL
ORDER BY mom_percentage DESC;

-- 3.3) Top 10 Declines MoM CTR channels
SELECT TOP 10 *
FROM gold.channels_ctr
WHERE diff_pm_ctr IS NOT NULL
ORDER BY diff_pm_ctr ASC; 

SELECT TOP 10 *
FROM gold.channels_ctr
WHERE pm_ctr IS NOT NULL
ORDER BY mom_percentage ASC;


/*
===============================================================================
4) CAMPAIGNS
===============================================================================
*/
-- 4.1) MoM by Monthly Clicks and Impressions
--    Analyze Month-over-Month CTR campaign performance 
DROP VIEW IF EXISTS gold.campaigns_ctr;
GO

CREATE VIEW gold.campaigns_ctr AS
WITH monthly_clicks AS (
SELECT
    DATEFROMPARTS(d.year, d.month, 1) AS performance_month, 
    f.campaign_id, 
    c.campaign_name,
    COUNT(f.click_id) AS clicks
FROM gold.fact_clicks f
LEFT JOIN gold.dim_campaign c 
ON f.campaign_id = c.campaign_id
LEFT JOIN gold.dim_date d 
ON f.date_key = d.date_key
WHERE f.campaign_id IS NOT NULL
GROUP BY DATEFROMPARTS(d.year, d.month, 1), f.campaign_id, c.campaign_name
), 
monthly_impressions AS ( 
SELECT 
    DATEFROMPARTS(YEAR(f.touchpoint_time), MONTH(f.touchpoint_time), 1) AS performance_month,
    f.campaign_id, 
    c.campaign_name,
    COUNT(f.interaction_type) AS current_impressions
FROM gold.fact_touchpoints f 
LEFT JOIN gold.dim_campaign c 
ON f.campaign_id = c.campaign_id
WHERE f.interaction_type = 'Impression' AND f.campaign_id IS NOT NULL --filter for impressions
GROUP BY DATEFROMPARTS(YEAR(f.touchpoint_time), MONTH(f.touchpoint_time), 1), f.campaign_id, c.campaign_name
), 
ctr_metrics AS (
SELECT
    COALESCE(c.performance_month, i.performance_month) AS performance_month,
    i.campaign_id, 
    COALESCE(c.campaign_name, i.campaign_name) AS campaign_name,
    c.clicks AS current_clicks,
    i.current_impressions,
    c.clicks * 1.0 /NULLIF(i.current_impressions, 0)AS ctr
FROM monthly_clicks c
FULL JOIN monthly_impressions i 
ON c.performance_month = i.performance_month 
    AND c.campaign_id = i.campaign_id
)

SELECT 
    performance_month,
    campaign_id, 
    campaign_name,
    current_clicks,
    current_impressions,
    ctr AS current_ctr,
    AVG(ctr) OVER(PARTITION BY campaign_id) AS avg_ctr,
    (ctr) - AVG(ctr) OVER(PARTITION BY campaign_id) AS diff_avg,
    CASE 
        WHEN (ctr) - AVG(ctr) OVER(PARTITION BY campaign_id) > 0 THEN 'Above Avg'
        WHEN (ctr) - AVG(ctr) OVER(PARTITION BY campaign_id) < 0 THEN 'Below Avg' 
        ELSE 'Equals Average'
    END AS avg_change,
    -- Month-over_Month Analysis 
    LAG(ctr) OVER(PARTITION BY campaign_id ORDER BY performance_month) AS pm_ctr, 
    (ctr) - LAG(ctr) OVER(PARTITION BY campaign_id ORDER BY performance_month) AS diff_pm_ctr,
    CASE 
        WHEN (ctr) - LAG(ctr) OVER(PARTITION BY campaign_id ORDER BY performance_month) > 0 THEN 'Improved'
        WHEN (ctr) - LAG(ctr) OVER(PARTITION BY campaign_id ORDER BY performance_month) < 0 THEN 'Decreased'
        ELSE 'No Change'
    END AS pm_change,
    ROUND(
        CASE 
            WHEN LAG(ctr) OVER(PARTITION BY campaign_id ORDER BY performance_month) = 0 THEN NULL 
            ELSE ((ctr) - LAG(ctr) OVER(PARTITION BY campaign_id ORDER BY performance_month))/LAG(ctr) OVER(PARTITION BY campaign_id ORDER BY performance_month)*100 
        END
    ,2) AS mom_percentage
FROM ctr_metrics
WHERE campaign_id IS NOT NULL;
GO

SELECT *
FROM gold.campaigns_ctr
ORDER BY campaign_id, performance_month;
GO

-- 4.2) Top 10 Improvements MoM CTR campaigns
SELECT TOP 10 *
FROM gold.campaigns_ctr
WHERE diff_pm_ctr IS NOT NULL
ORDER BY diff_pm_ctr DESC; 

SELECT TOP 10 *
FROM gold.campaigns_ctr
WHERE pm_ctr IS NOT NULL
ORDER BY mom_percentage DESC;

-- 4.3) Top 10 Declines MoM CTR campaigns
SELECT TOP 10 *
FROM gold.campaigns_ctr
WHERE diff_pm_ctr IS NOT NULL
ORDER BY diff_pm_ctr ASC; 

SELECT TOP 10 *
FROM gold.campaigns_ctr
WHERE pm_ctr IS NOT NULL
ORDER BY mom_percentage ASC;


