/*
===============================================================================
CPM Cost per Mille Performance Analysis (Month-over-Month)
===============================================================================
Purpose:
    - To measure the CPM (reach efficiency) of marketing components such as campaigns and channels over time (CPM lower = better reach efficiency).
    - For benchmarking and identifying cost-efficient reach entities.
    - To track monthly 2024 trends and growth.

SQL Functions Used:
    - LAG(): Accesses data from previous rows.
    - AVG() OVER(): Computes average values within partitions.
    - CASE: Defines conditional logic for trend analysis.

Queries: 
    1) CPM overall 
    2) CPM Performance monthly
    3.1) Monthly CPM Performance and MOM Analysis by Campaigns 
    3.2) Top Ten Campaigns by Monthly CPM Improvements 
    3.3) Top Ten Campaigns by Monthly CPM Declines 
    4.1) Monthly CPM Performance and MOM Analysis by Channels 
    4.2) Top Ten Channels by Monthly CPM Improvements 
    4.3) Top Ten Channels by Monthly CPM Declines
    5) CPM-to-CVR Efficiency Ratio by Channel

Data Limitation:
    CPM values in this dataset are artificially high (avg ~2,500€ vs realistic 5-30€) 
    due to synthetic data generation where impression volume is disproportionately low 
    relative to spend (28,826 impressions vs 72,612€ spend). 
    
    The MoM trends and relative channel/campaign comparisons remain valid for demonstrating the analytical framework, but absolute CPM values should not be interpreted as realistic marketing benchmarks.

===============================================================================
*/
USE marketing_dw; 
GO


/*
===============================================================================
1) CPM overall
===============================================================================
*/ 
SELECT 
    (SELECT SUM(spend) FROM gold.fact_spend) AS spend, 
    (SELECT COUNT(*) FROM gold.fact_touchpoints WHERE interaction_type = 'Impression') AS impressions,
    (SELECT SUM(spend) FROM gold.fact_spend) 
    / 
    NULLIF((SELECT COUNT(*) FROM gold.fact_touchpoints WHERE interaction_type = 'Impression'), 0) * 1000 AS cpm;


/*
===============================================================================
2) CPM Performance monthly
===============================================================================
*/
DROP VIEW IF EXISTS gold.cpm;
GO

CREATE VIEW gold.cpm AS
WITH monthly_impressions AS (
SELECT
    DATEFROMPARTS(YEAR(touchpoint_time), MONTH(touchpoint_time), 1) AS performance_month, 
    COUNT(*) AS impressions
FROM gold.fact_touchpoints
WHERE interaction_type = 'Impression'
GROUP BY DATEFROMPARTS(YEAR(touchpoint_time), MONTH(touchpoint_time), 1)
), 
monthly_spend AS (
SELECT 
    DATEFROMPARTS(YEAR(spend_date), MONTH(spend_date), 1) AS performance_month,
    SUM(spend) AS current_spend 
FROM gold.fact_spend  
GROUP BY DATEFROMPARTS(YEAR(spend_date), MONTH(spend_date), 1)
), 
cpm_metrics AS (
SELECT
    COALESCE(i.performance_month, s.performance_month) AS performance_month,
    i.impressions AS current_impressions,
    s.current_spend,
    s.current_spend/NULLIF(i.impressions, 0) * 1000 AS cpm
FROM monthly_impressions i
FULL JOIN monthly_spend s 
ON i.performance_month = s.performance_month 
)


SELECT 
    performance_month,
    current_spend,
    current_impressions,
    cpm AS current_cpm,
    AVG(cpm) OVER() AS avg_cpm,
    (cpm) - AVG(cpm) OVER() AS diff_avg,
    CASE 
        WHEN (cpm) - AVG(cpm) OVER() > 0 THEN 'Worsened (Above Avg)'
        WHEN (cpm) - AVG(cpm) OVER() < 0 THEN 'Improved (Below Avg)' 
        ELSE 'Equals Average'
    END AS avg_change,
    -- Month-over_Month Analysis 
    LAG(cpm) OVER(ORDER BY performance_month) AS pm_cpm, 
    (cpm) - LAG(cpm) OVER(ORDER BY performance_month) AS diff_pm_cpm,
    CASE 
        WHEN (cpm) - LAG(cpm) OVER(ORDER BY performance_month) > 0 THEN 'Worsened (Higher)'
        WHEN (cpm) - LAG(cpm) OVER(ORDER BY performance_month) < 0 THEN 'Improved (Lower)'
        ELSE 'No Change'
    END AS pm_change,
    ROUND(
        CASE 
            WHEN LAG(cpm) OVER(ORDER BY performance_month) = 0 THEN NULL 
            ELSE ((cpm) - LAG(cpm) OVER(ORDER BY performance_month))/LAG(cpm) OVER(ORDER BY performance_month)*100 
        END
    ,2) AS mom_percentage
FROM cpm_metrics;
GO

SELECT *
FROM gold.cpm
ORDER BY performance_month;
GO


/*
===============================================================================
3) CAMPAIGNS
===============================================================================
*/
-- 3.1) MoM by Monthly Ad Spend and Impressions
--      Analyze Month-over-Month CPM campaign performance 
DROP VIEW IF EXISTS gold.campaigns_cpm;
GO

CREATE VIEW gold.campaigns_cpm AS
WITH monthly_impressions AS (
SELECT
    DATEFROMPARTS(YEAR(touchpoint_time), MONTH(touchpoint_time), 1) AS performance_month, 
    campaign_id, 
    COUNT(*) AS impressions
FROM gold.fact_touchpoints
WHERE interaction_type = 'Impression'
    AND campaign_id IS NOT NULL
GROUP BY DATEFROMPARTS(YEAR(touchpoint_time), MONTH(touchpoint_time), 1), campaign_id
), 
monthly_spend AS (
SELECT 
    DATEFROMPARTS(YEAR(spend_date), MONTH(spend_date), 1) AS performance_month,
    f.campaign_id,
    c.campaign_name,
    SUM(spend) AS current_spend 
FROM gold.fact_spend f
LEFT JOIN gold.dim_campaign c 
ON f.campaign_id = c.campaign_id
WHERE f.campaign_id IS NOT NULL 
GROUP BY DATEFROMPARTS(YEAR(spend_date), MONTH(spend_date), 1), f.campaign_id, c.campaign_name
), 
cpm_metrics AS (
SELECT
    COALESCE(i.performance_month, s.performance_month) AS performance_month,
    COALESCE(i.campaign_id, s.campaign_id) AS campaign_id, 
    s.campaign_name,
    i.impressions AS current_impressions,
    s.current_spend,
    s.current_spend/NULLIF(i.impressions, 0) * 1000 AS cpm
FROM monthly_impressions i
FULL JOIN monthly_spend s 
ON i.performance_month = s.performance_month 
    AND i.campaign_id = s.campaign_id
)

SELECT 
    performance_month,
    campaign_id, 
    campaign_name,
    current_spend,
    current_impressions,
    cpm AS current_cpm,
    AVG(cpm) OVER(PARTITION BY campaign_id) AS avg_cpm,
    (cpm) - AVG(cpm) OVER(PARTITION BY campaign_id) AS diff_avg,
    CASE 
        WHEN (cpm) - AVG(cpm) OVER(PARTITION BY campaign_id) > 0 THEN 'Worsened (Above Avg)'
        WHEN (cpm) - AVG(cpm) OVER(PARTITION BY campaign_id) < 0 THEN 'Improved (Below Avg)' 
        ELSE 'Equals Average'
    END AS avg_change,
    -- Month-over_Month Analysis 
    LAG(cpm) OVER(PARTITION BY campaign_id ORDER BY performance_month) AS pm_cpm, 
    (cpm) - LAG(cpm) OVER(PARTITION BY campaign_id ORDER BY performance_month) AS diff_pm_cpm,
    CASE 
        WHEN (cpm) - LAG(cpm) OVER(PARTITION BY campaign_id ORDER BY performance_month) > 0 THEN 'Worsened (Higher)'
        WHEN (cpm) - LAG(cpm) OVER(PARTITION BY campaign_id ORDER BY performance_month) < 0 THEN 'Improved (Lower)'
        ELSE 'No Change'
    END AS pm_change,
    ROUND(
        CASE 
            WHEN LAG(cpm) OVER(PARTITION BY campaign_id ORDER BY performance_month) = 0 THEN NULL 
            ELSE ((cpm) - LAG(cpm) OVER(PARTITION BY campaign_id ORDER BY performance_month))/LAG(cpm) OVER(PARTITION BY campaign_id ORDER BY performance_month)*100 
        END
    ,2) AS mom_percentage
FROM cpm_metrics
WHERE campaign_id IS NOT NULL;
GO

SELECT *
FROM gold.campaigns_cpm
ORDER BY campaign_id, performance_month;
GO

-- 3.2) Top 10 Improvements MoM CPM campaigns (lower CPM = better reach efficiency)
SELECT TOP 10 *
FROM gold.campaigns_cpm
WHERE diff_pm_cpm IS NOT NULL
ORDER BY diff_pm_cpm ASC; 

SELECT TOP 10 *
FROM gold.campaigns_cpm
WHERE pm_cpm IS NOT NULL
ORDER BY mom_percentage ASC;

-- 3.3) Top 10 Declines MoM CPM campaigns (higher CPM = worse reach efficiency)
SELECT TOP 10 *
FROM gold.campaigns_cpm
WHERE diff_pm_cpm IS NOT NULL
ORDER BY diff_pm_cpm DESC; 

SELECT TOP 10 *
FROM gold.campaigns_cpm
WHERE pm_cpm IS NOT NULL
ORDER BY mom_percentage DESC;


/*
===============================================================================
4) CHANNELS
===============================================================================
*/
-- 4.1) MoM by Monthly Ad Spend and Impressions
--      Analyze Month-over-Month CPM channel performance 
DROP VIEW IF EXISTS gold.channels_cpm;
GO

CREATE VIEW gold.channels_cpm AS
WITH monthly_impressions AS (
SELECT
    DATEFROMPARTS(YEAR(touchpoint_time), MONTH(touchpoint_time), 1) AS performance_month, 
    channel, 
    COUNT(*) AS impressions
FROM gold.fact_touchpoints
WHERE interaction_type = 'Impression'
    AND channel IS NOT NULL
GROUP BY DATEFROMPARTS(YEAR(touchpoint_time), MONTH(touchpoint_time), 1), channel
), 
monthly_spend AS (
SELECT 
    DATEFROMPARTS(YEAR(spend_date), MONTH(spend_date), 1) AS performance_month,
    channel, 
    SUM(spend) AS current_spend 
FROM gold.fact_spend 
WHERE channel IS NOT NULL 
GROUP BY DATEFROMPARTS(YEAR(spend_date), MONTH(spend_date), 1), channel
), 
cpm_metrics AS (
SELECT
    COALESCE(i.performance_month, s.performance_month) AS performance_month,
    COALESCE(i.channel, s.channel) AS channel, 
    i.impressions AS current_impressions,
    s.current_spend,
    s.current_spend/NULLIF(i.impressions, 0) * 1000 AS cpm
FROM monthly_impressions i
FULL JOIN monthly_spend s 
ON i.performance_month = s.performance_month 
    AND i.channel = s.channel
)

SELECT 
    performance_month,
    channel, 
    current_spend,
    current_impressions,
    cpm AS current_cpm,
    AVG(cpm) OVER(PARTITION BY channel) AS avg_cpm,
    (cpm) - AVG(cpm) OVER(PARTITION BY channel) AS diff_avg,
    CASE 
        WHEN (cpm) - AVG(cpm) OVER(PARTITION BY channel) > 0 THEN 'Worsened (Above Avg)'
        WHEN (cpm) - AVG(cpm) OVER(PARTITION BY channel) < 0 THEN 'Improved (Below Avg)' 
        ELSE 'Equals Average'
    END AS avg_change,
    -- Month-over_Month Analysis 
    LAG(cpm) OVER(PARTITION BY channel ORDER BY performance_month) AS pm_cpm, 
    (cpm) - LAG(cpm) OVER(PARTITION BY channel ORDER BY performance_month) AS diff_pm_cpm,
    CASE 
        WHEN (cpm) - LAG(cpm) OVER(PARTITION BY channel ORDER BY performance_month) > 0 THEN 'Worsened (Higher)'
        WHEN (cpm) - LAG(cpm) OVER(PARTITION BY channel ORDER BY performance_month) < 0 THEN 'Improved (Lower)'
        ELSE 'No Change'
    END AS pm_change,
    ROUND(
        CASE 
            WHEN LAG(cpm) OVER(PARTITION BY channel ORDER BY performance_month) = 0 THEN NULL 
            ELSE ((cpm) - LAG(cpm) OVER(PARTITION BY channel ORDER BY performance_month))/LAG(cpm) OVER(PARTITION BY channel ORDER BY performance_month)*100 
        END
    ,2) AS mom_percentage
FROM cpm_metrics
WHERE channel IS NOT NULL;
GO

SELECT *
FROM gold.channels_cpm
ORDER BY channel, performance_month;
GO

-- 4.2) Top 10 Improvements MoM CPM channels (lower CPM = better reach efficiency)
SELECT TOP 10 *
FROM gold.channels_cpm
WHERE diff_pm_cpm IS NOT NULL
ORDER BY diff_pm_cpm ASC; 

SELECT TOP 10 *
FROM gold.channels_cpm
WHERE pm_cpm IS NOT NULL
ORDER BY mom_percentage ASC;

-- 4.3) Top 10 Declines MoM CPM channels (higher CPM = worse reach efficiency)
SELECT TOP 10 *
FROM gold.channels_cpm
WHERE diff_pm_cpm IS NOT NULL
ORDER BY diff_pm_cpm DESC; 

SELECT TOP 10 *
FROM gold.channels_cpm
WHERE pm_cpm IS NOT NULL
ORDER BY mom_percentage DESC;


/*
===============================================================================
5) CPM-to-CVR Efficiency Ratio by Channel
===============================================================================
Purpose:
    Combines reach cost (CPM) with conversion quality (CVR) to identify
    channels that deliver both affordable reach AND high conversion rates.
    
    Efficiency Ratio = CPM / CVR 
    → Lower ratio = more cost-efficient conversions
    → A channel with low CPM but also low CVR may not be efficient
    → A channel with higher CPM but excellent CVR may still be worthwhile

Note: 
    Due to the synthetic data limitation (low impression volume), the absolute ratio values are inflated. However, the relative ranking between channels remains meaningful for comparison purposes.
===============================================================================
*/
WITH channel_cpm AS (
    SELECT 
        s.channel,
        SUM(s.spend) AS total_spend,
        i.total_impressions,
        SUM(s.spend) / NULLIF(i.total_impressions, 0) * 1000 AS cpm
    FROM gold.fact_spend s
    INNER JOIN (
        SELECT channel, COUNT(*) AS total_impressions
        FROM gold.fact_touchpoints 
        WHERE interaction_type = 'Impression' AND channel IS NOT NULL
        GROUP BY channel
    ) i ON s.channel = i.channel
    WHERE s.channel IS NOT NULL
    GROUP BY s.channel, i.total_impressions
),
channel_cvr AS (
    SELECT
        c.click_channel AS channel,
        COUNT(DISTINCT p.purchase_id) AS total_conversions,
        COUNT(c.click_id) AS total_clicks,
        CAST(COUNT(DISTINCT p.purchase_id) AS DECIMAL(10,4)) 
        / NULLIF(COUNT(c.click_id), 0) * 100 AS cvr
    FROM gold.fact_clicks c
    LEFT JOIN gold.fact_purchases p
        ON c.user_id = p.user_id
        AND c.click_channel = p.channel_last_touch
    WHERE c.click_channel IS NOT NULL
    GROUP BY c.click_channel
)

SELECT
    cpm.channel,
    cpm.total_spend,
    cpm.total_impressions,
    ROUND(cpm.cpm, 2) AS cpm,
    cvr.total_clicks,
    cvr.total_conversions,
    ROUND(cvr.cvr, 2) AS cvr,
    ROUND(cpm.cpm / NULLIF(cvr.cvr, 0), 2) AS cpm_cvr_ratio,
    RANK() OVER (ORDER BY cpm.cpm / NULLIF(cvr.cvr, 0)) AS efficiency_rank,
    CASE 
        WHEN RANK() OVER (ORDER BY cpm.cpm / NULLIF(cvr.cvr, 0)) <= 2 THEN 'High Efficiency'
        WHEN RANK() OVER (ORDER BY cpm.cpm / NULLIF(cvr.cvr, 0)) <= 4 THEN 'Medium Efficiency'
        ELSE 'Low Efficiency'
    END AS efficiency_tier
FROM channel_cpm cpm
INNER JOIN channel_cvr cvr
    ON cpm.channel = cvr.channel
ORDER BY cpm_cvr_ratio;
