/*
===============================================================================
ROAS Performance Analysis (Month-over-Month)
===============================================================================
Purpose:
    - To measure the performance of marketing components such as campagins and channels over time.
    - For benchmarking and identifying high-performing entities.
    - To track monthly 2024 trends and growth.

SQL Functions Used:
    - LAG(): Accesses data from previous rows.
    - AVG() OVER(): Computes average values within partitions.
    - CASE: Defines conditional logic for trend analysis. 

Queries: 
    1) ROAS overall 
    2) ROAS Performance monthly
    3.1) Mid of Funnel (MOFU) Monthly ROAS Performance and MOM-Analysis by Channels
    3.2) Top of Funnel (TOFU) Monthly ROAS Performance and MOM-Analysis by Channels
    3.3) Bottom of Funnel (BOFU) Monthly ROAS Performance and MOM-Analysis by Channels
    3.4) Top Ten MOM Channels by TOFU/MOFU/BOFU 
    4.1) Mid of Funnel (MOFU) Monthly ROAS Performance and MOM-Analysis by Campaigns
    4.2) Top of Funnel (TOFU) Monthly ROAS Performance and MOM-Analysis by Campaigns
    4.3) Bottom of Funnel (BOFU) Monthly ROAS Performance and MOM-Analysis by Campaigns
    4.4) Top Ten MOM Campaigns by TOFU/MOFU/BOFU 

===============================================================================
*/
USE marketing_dw; 
GO

/*
===============================================================================
1) ROAS overall (120 days)
===============================================================================
*/ 

-- OVERALL MOFU ROAS
SELECT 
  SUM(current_revenue) AS total_revenue,
  SUM(current_spend) AS total_spend,
  SUM(current_revenue) / NULLIF(SUM(current_spend), 0) AS overall_mofu_roas
FROM gold.funnel_channels_roas; -- View is created at 4.1 MOFU ROAS by Channel 

-- OVERALL BOFU ROAS
SELECT 
  SUM(current_revenue) AS total_revenue,
  SUM(current_spend) AS total_spend,
  SUM(current_revenue) / NULLIF(SUM(current_spend), 0) AS overall_bofu_roas
FROM gold.last_touch_channels_roas;

/*
===============================================================================
2) ROAS Performance monthly
===============================================================================
*/ 
DROP VIEW IF EXISTS gold.roas;
GO

CREATE VIEW gold.roas AS
WITH monthly_revenue AS (
    SELECT 
        DATEFROMPARTS(YEAR(purchase_date), MONTH(purchase_date), 1) AS performance_month,
        -- NUR Revenue von Touchpoints MIT Kosten
        SUM(CASE WHEN cost_share > 0 THEN revenue_share ELSE 0 END) AS current_revenue 
    FROM gold.fact_attribution_linear_with_costs  -- ← CHANGED!
    WHERE channel NOT IN ('Direct','Email','Organic Search','Referral')
    GROUP BY DATEFROMPARTS(YEAR(purchase_date), MONTH(purchase_date), 1)
),
monthly_spend AS (
    SELECT 
        DATEFROMPARTS(YEAR(purchase_date), MONTH(purchase_date), 1) AS performance_month,  -- ← CHANGED from spend_date!
        SUM(cost_share) AS current_spend  -- ← CHANGED from spend!
    FROM gold.fact_attribution_linear_with_costs  -- ← CHANGED!
    WHERE channel NOT IN ('Direct','Email','Organic Search','Referral')
        AND cost_share > 0
    GROUP BY DATEFROMPARTS(YEAR(purchase_date), MONTH(purchase_date), 1)
),
roas_metrics AS (
    SELECT
        COALESCE(r.performance_month, s.performance_month) AS performance_month,
        r.current_revenue,
        s.current_spend,
        r.current_revenue/NULLIF(s.current_spend, 0) AS roas
    FROM monthly_revenue r
    FULL JOIN monthly_spend s 
        ON r.performance_month = s.performance_month
)
SELECT 
    performance_month,
    current_revenue,
    current_spend,
    roas AS current_roas,
    AVG(roas) OVER() AS avg_roas,
    (roas) - AVG(roas) OVER() AS diff_avg,
    CASE 
        WHEN (roas) - AVG(roas) OVER() > 0 THEN 'Above Avg'
        WHEN (roas) - AVG(roas) OVER() < 0 THEN 'Below Avg' 
        ELSE 'Equals Average'
    END AS avg_change,
    -- Month-over_Month Analysis 
    LAG(roas) OVER(ORDER BY performance_month) AS pm_roas, 
    (roas) - LAG(roas) OVER(ORDER BY performance_month) AS diff_pm_roas,
    CASE 
        WHEN (roas) - LAG(roas) OVER(ORDER BY performance_month) > 0 THEN 'Increase'
        WHEN (roas) - LAG(roas) OVER(ORDER BY performance_month) < 0 THEN 'Decrease'
        ELSE 'No Change'
    END AS pm_change,
    ROUND(
        CASE 
            WHEN LAG(roas) OVER(ORDER BY performance_month) = 0 THEN NULL 
            ELSE ((roas) - LAG(roas) OVER(ORDER BY performance_month))/LAG(roas) OVER(ORDER BY performance_month)*100 
        END
    ,2) AS mom_percentage
FROM roas_metrics;
GO

SELECT *
FROM gold.roas
ORDER BY performance_month;
GO


/*
===============================================================================
3) CHANNELS
===============================================================================
*/
--===================================
-- 3.1) MOFU Full-Funnel Contributers
--=================================== 
-- MoM by Multi-Touch Revenue Shares and Monthly Ad Spend
-- Analyze Month-over-Month ROAS performance of channels by comparing their ROAS to both the average ROAS performance of the channel and the previous month ROAS 
DROP VIEW IF EXISTS gold.funnel_channels_roas;
GO

CREATE VIEW gold.funnel_channels_roas AS
WITH monthly_revenue AS (
SELECT
    DATEFROMPARTS(YEAR(purchase_date), MONTH(purchase_date), 1) AS performance_month, 
    channel, 
    -- Only touchpoints WITH costs
    SUM(CASE WHEN cost_share > 0 THEN revenue_share ELSE 0 END) AS current_revenue 
FROM gold.fact_attribution_linear_with_costs
WHERE channel NOT IN ('Direct','Email','Organic Search','Referral')
GROUP BY DATEFROMPARTS(YEAR(purchase_date), MONTH(purchase_date), 1), channel
),
monthly_spend AS (
SELECT 
    DATEFROMPARTS(YEAR(purchase_date), MONTH(purchase_date), 1) AS performance_month,
    channel, 
    SUM(cost_share) AS current_spend 
FROM gold.fact_attribution_linear_with_costs 
WHERE channel NOT IN ('Direct','Email','Organic Search','Referral')
    AND cost_share > 0  -- Only touchpoints WITH costs
GROUP BY DATEFROMPARTS(YEAR(purchase_date), MONTH(purchase_date), 1), channel
),
roas_metrics AS (
SELECT
    COALESCE(r.performance_month, s.performance_month) AS performance_month, 
    COALESCE(r.channel, s.channel) AS channel,
    r.current_revenue,
    s.current_spend,
    r.current_revenue/NULLIF(s.current_spend, 0) AS roas
FROM monthly_revenue r
FULL JOIN monthly_spend s 
ON r.performance_month = s.performance_month 
    AND r.channel = s.channel
) 

SELECT 
    performance_month,
    channel,
    current_revenue,
    current_spend,
    roas AS current_roas,
    AVG(roas) OVER(PARTITION BY channel) AS avg_roas,
    roas - AVG(roas) OVER(PARTITION BY channel) AS diff_avg,
    CASE 
        WHEN roas - AVG(roas) OVER(PARTITION BY channel) > 0 THEN 'Above Avg'
        WHEN roas - AVG(roas) OVER(PARTITION BY channel) < 0 THEN 'Below Avg' 
        ELSE 'Equals Average'
    END AS avg_change,
    -- Month-over_Month Analysis 
    LAG(roas) OVER(PARTITION BY channel ORDER BY performance_month) AS pm_roas, 
    roas - LAG(roas) OVER(PARTITION BY channel ORDER BY performance_month) AS diff_pm_roas,
    CASE 
        WHEN roas - LAG(roas) OVER(PARTITION BY channel ORDER BY performance_month) > 0 THEN 'Increase'
        WHEN roas - LAG(roas) OVER(PARTITION BY channel ORDER BY performance_month) < 0 THEN 'Decrease'
        ELSE 'No Change'
    END AS pm_change,
    ROUND(
        CASE 
            WHEN LAG(roas) OVER(PARTITION BY channel ORDER BY performance_month) = 0 THEN NULL 
            ELSE (roas - LAG(roas) OVER(PARTITION BY   channel ORDER BY performance_month))/LAG(roas) OVER(PARTITION BY channel ORDER BY performance_month)*100 
        END
    ,2) AS mom_percentage
FROM roas_metrics;
GO

SELECT *
FROM gold.funnel_channels_roas
ORDER BY channel, performance_month;
GO

--=====================================
-- 3.2) TOFU Top of Funnel Contributers
--=====================================
-- MoM by Full Purchase Revenues And Monthly Ad Spend
-- Analyze Month-over-Month ROAS performance by acquisition channel to see which channels are bringing users in
DROP VIEW IF EXISTS gold.acquisition_channels_roas;
GO

CREATE VIEW gold.acquisition_channels_roas AS
WITH first_touch_data AS (
    SELECT 
        f.*,
        ROW_NUMBER() OVER (
            PARTITION BY f.user_id, f.purchase_id 
            ORDER BY f.touchpoint_time ASC  -- prepare to filter for first touchpoint
        ) AS rn
    FROM gold.fact_attribution_linear_with_costs f
    WHERE f.channel IS NOT NULL 
        AND f.channel NOT IN ('Direct','Email','Organic Search','Referral')
),
monthly_revenue AS (
    SELECT
        DATEFROMPARTS(YEAR(f.purchase_date), MONTH(f.purchase_date), 1) AS performance_month, 
        f.channel AS acquisition_channel, 
        SUM(f.revenue_share) AS current_revenue 
    FROM first_touch_data f
    WHERE f.rn = 1  -- only first touch
        AND f.cost_share > 0
    GROUP BY DATEFROMPARTS(YEAR(f.purchase_date), MONTH(f.purchase_date), 1), f.channel
),
monthly_spend AS (
    SELECT 
        DATEFROMPARTS(YEAR(purchase_date), MONTH(purchase_date), 1) AS performance_month,
        channel AS acquisition_channel, 
        SUM(cost_share) AS current_spend 
    FROM first_touch_data 
    WHERE rn = 1  -- only first touch
        AND cost_share > 0
    GROUP BY DATEFROMPARTS(YEAR(purchase_date), MONTH(purchase_date), 1), channel
),
roas_metrics AS (
SELECT
    COALESCE(r.performance_month, s.performance_month) AS performance_month, 
    r.acquisition_channel,
    r.current_revenue,
    s.current_spend,
    r.current_revenue/NULLIF(s.current_spend, 0) AS roas
FROM monthly_revenue r
FULL JOIN monthly_spend s 
ON r.performance_month = s.performance_month 
    AND r.acquisition_channel = s.acquisition_channel
) 

SELECT 
    performance_month,
    acquisition_channel,
    current_revenue,
    current_spend,
    roas AS current_roas,
    AVG(roas) OVER(PARTITION BY acquisition_channel) AS avg_roas,
    roas - AVG(roas) OVER(PARTITION BY acquisition_channel) AS diff_avg,
    CASE 
        WHEN roas - AVG(roas) OVER(PARTITION BY acquisition_channel) > 0 THEN 'Above Avg'
        WHEN roas - AVG(roas) OVER(PARTITION BY acquisition_channel) < 0 THEN 'Below Avg' 
        ELSE 'Equals Average'
    END AS avg_change,
    -- Month-over_Month Analysis 
    LAG(roas) OVER(PARTITION BY acquisition_channel ORDER BY performance_month) AS pm_roas, 
    roas - LAG(roas) OVER(PARTITION BY acquisition_channel ORDER BY performance_month) AS diff_pm_roas,
    CASE 
        WHEN roas - LAG(roas) OVER(PARTITION BY acquisition_channel ORDER BY performance_month) > 0 THEN 'Increase'
        WHEN roas - LAG(roas) OVER(PARTITION BY acquisition_channel ORDER BY performance_month) < 0 THEN 'Decrease'
        ELSE 'No Change'
    END AS pm_change,
    ROUND(
        CASE 
            WHEN LAG(roas) OVER(PARTITION BY acquisition_channel ORDER BY performance_month) = 0 THEN NULL 
            ELSE (roas - LAG(roas) OVER(PARTITION BY   acquisition_channel ORDER BY performance_month))/LAG(roas) OVER(PARTITION BY acquisition_channel ORDER BY performance_month)*100 
        END
    ,2) AS mom_percentage
FROM roas_metrics;
GO 

SELECT * 
FROM gold.acquisition_channels_roas
ORDER BY acquisition_channel, performance_month;
GO


--==============================================
-- 3.3) BOFU Bottom of Funnel Conversion Drivers
--==============================================
-- MoM by Full Purchase Revenues and Monthly Ad Spend
-- Analyze Month-over-Month ROAS performance by last-touch channel to see which channels are driving conversion
DROP VIEW IF EXISTS gold.last_touch_channels_roas;
GO

CREATE VIEW gold.last_touch_channels_roas AS
WITH last_touch_data AS (
    SELECT 
        f.*,
        ROW_NUMBER() OVER (
            PARTITION BY f.user_id, f.purchase_id 
            ORDER BY f.touchpoint_time DESC
        ) AS rn
    FROM gold.fact_attribution_linear_with_costs f
    WHERE f.channel IS NOT NULL 
        AND f.channel NOT IN ('Direct','Email','Organic Search','Referral') 
),
monthly_revenue AS (
    SELECT
        DATEFROMPARTS(YEAR(f.purchase_date), MONTH(f.purchase_date), 1) AS performance_month, 
        f.last_touch_channel, 
        SUM(f.revenue) AS current_revenue           -- ! full revenue 
    FROM gold.fact_attribution_last_touch f
    INNER JOIN last_touch_data ltd 
        ON f.purchase_id = ltd.purchase_id           -- same purchase
        AND f.last_touch_channel = ltd.channel  -- same campaign was last touch
        AND ltd.rn = 1                               -- ensuring to be last touch
        AND ltd.cost_share > 0                       -- with costs
    WHERE f.last_touch_channel IS NOT NULL
    GROUP BY DATEFROMPARTS(YEAR(f.purchase_date), MONTH(f.purchase_date), 1), f.last_touch_channel
),
monthly_spend AS (
    SELECT 
        DATEFROMPARTS(YEAR(purchase_date), MONTH(purchase_date), 1) AS performance_month,
        channel AS last_touch_channel, 
        SUM(cost_share) AS current_spend  -- cost-share at last Touch
    FROM last_touch_data
    WHERE rn = 1
        AND cost_share > 0
    GROUP BY DATEFROMPARTS(YEAR(purchase_date), MONTH(purchase_date), 1), channel
),
roas_metrics AS (
SELECT
    COALESCE(r.performance_month, s.performance_month) AS performance_month, 
    r.last_touch_channel,
    r.current_revenue,
    s.current_spend,
    r.current_revenue/NULLIF(s.current_spend, 0) AS roas
FROM monthly_revenue r
FULL JOIN monthly_spend s 
ON r.performance_month = s.performance_month 
    AND r.last_touch_channel = s.last_touch_channel
) 

SELECT 
    performance_month,
    last_touch_channel, 
    current_revenue,
    current_spend,
    roas AS current_roas,
    AVG(roas) OVER(PARTITION BY last_touch_channel) AS avg_roas,
    roas - AVG(roas) OVER(PARTITION BY last_touch_channel) AS diff_avg,
    CASE 
        WHEN roas - AVG(roas) OVER(PARTITION BY last_touch_channel) > 0 THEN 'Above Avg'
        WHEN roas - AVG(roas) OVER(PARTITION BY last_touch_channel) < 0 THEN 'Below Avg' 
        ELSE 'Equals Average'
    END AS avg_change,
    -- Month-over_Month Analysis 
    LAG(roas) OVER(PARTITION BY last_touch_channel ORDER BY performance_month) AS pm_roas, 
    roas - LAG(roas) OVER(PARTITION BY last_touch_channel ORDER BY performance_month) AS diff_pm_roas,
    CASE 
        WHEN roas - LAG(roas) OVER(PARTITION BY last_touch_channel ORDER BY performance_month) > 0 THEN 'Increase'
        WHEN roas - LAG(roas) OVER(PARTITION BY last_touch_channel ORDER BY performance_month) < 0 THEN 'Decrease'
        ELSE 'No Change'
    END AS pm_change,
    ROUND(
        CASE 
            WHEN LAG(roas) OVER(PARTITION BY last_touch_channel ORDER BY performance_month) = 0 THEN NULL 
            ELSE (roas - LAG(roas) OVER(PARTITION BY last_touch_channel ORDER BY performance_month))/LAG(roas) OVER(PARTITION BY last_touch_channel ORDER BY performance_month)*100 
        END
    ,2) AS mom_percentage
FROM roas_metrics;
GO 

SELECT * 
FROM gold.last_touch_channels_roas
ORDER BY last_touch_channel, performance_month;


--==================================
-- 3.4) TOP 10 MoM TOFU/Multi/BOFU 
--==================================
-- Top 10 MoM channels within funnel
SELECT TOP 10 *
FROM gold.funnel_channels_roas
ORDER BY diff_pm_roas DESC;

SELECT TOP 10 *
FROM gold.funnel_channels_roas
WHERE pm_roas > 0
ORDER BY mom_percentage DESC;

-- Top 10 MoM acquisition channels
SELECT TOP 10 *
FROM gold.acquisition_channels_roas
ORDER BY diff_pm_roas DESC;

SELECT TOP 10 *
FROM gold.acquisition_channels_roas
WHERE pm_roas > 0
ORDER BY mom_percentage DESC;

-- Top 10 MoM last-touch campaigns
SELECT TOP 10 *
FROM gold.last_touch_channels_roas
ORDER BY diff_pm_roas DESC;

SELECT TOP 10 *
FROM gold.last_touch_channels_roas
WHERE pm_roas > 0
ORDER BY mom_percentage DESC;



/*
===============================================================================
4) CAMPAIGNS
===============================================================================
*/
--===================================
-- 4.1) MOFU Full-Funnel Contributers
--=================================== 
-- MoM by Multi-Touch Revenue Shares and Monthly Ad Spend
-- Analyze Month-over-Month ROAS performance of campaigns by comparing their ROAS to both the average ROAS performance of the campaign and the previous month ROAS 
DROP VIEW IF EXISTS gold.funnel_campaigns_roas;
GO

CREATE VIEW gold.funnel_campaigns_roas AS
WITH monthly_revenue AS (
SELECT
    DATEFROMPARTS(YEAR(f.purchase_date), MONTH(f.purchase_date), 1) AS performance_month, 
    f.campaign_id, 
    c.campaign_name,
    -- Only touchpoints WITH costs
    SUM(CASE WHEN f.cost_share > 0 THEN f.revenue_share ELSE 0 END) AS current_revenue 
FROM gold.fact_attribution_linear_with_costs f
LEFT JOIN gold.dim_campaign c 
ON f.campaign_id = c.campaign_id
WHERE f.campaign_id IS NOT NULL AND f.channel NOT IN ('Direct','Email','Organic Search','Referral')
GROUP BY DATEFROMPARTS(YEAR(f.purchase_date), MONTH(f.purchase_date), 1), f.campaign_id, c.campaign_name
), 
monthly_spend AS (
SELECT 
    DATEFROMPARTS(YEAR(purchase_date), MONTH(purchase_date), 1) AS performance_month,
    campaign_id, 
    SUM(cost_share) AS current_spend 
FROM gold.fact_attribution_linear_with_costs 
WHERE campaign_id IS NOT NULL 
    AND channel NOT IN ('Direct','Email','Organic Search','Referral')
    AND cost_share > 0  -- Only touchpoints WITH costs
GROUP BY DATEFROMPARTS(YEAR(purchase_date), MONTH(purchase_date), 1), campaign_id
), 
roas_metrics AS (
SELECT
    COALESCE(r.performance_month, s.performance_month) AS performance_month,
    r.campaign_id, 
    r.campaign_name,
    r.current_revenue,
    s.current_spend,
    r.current_revenue/NULLIF(s.current_spend, 0) AS roas
FROM monthly_revenue r
FULL JOIN monthly_spend s 
ON r.performance_month = s.performance_month 
    AND r.campaign_id = s.campaign_id

)

SELECT 
    performance_month,
    campaign_id, 
    campaign_name,
    current_revenue,
    current_spend,
    roas AS current_roas,
    AVG(roas) OVER(PARTITION BY campaign_id) AS avg_roas,
    (roas) - AVG(roas) OVER(PARTITION BY campaign_id) AS diff_avg,
    CASE 
        WHEN (roas) - AVG(roas) OVER(PARTITION BY campaign_id) > 0 THEN 'Above Avg'
        WHEN (roas) - AVG(roas) OVER(PARTITION BY campaign_id) < 0 THEN 'Below Avg' 
        ELSE 'Equals Average'
    END AS avg_change,
    -- Month-over_Month Analysis 
    LAG(roas) OVER(PARTITION BY campaign_id ORDER BY performance_month) AS pm_roas, 
    (roas) - LAG(roas) OVER(PARTITION BY campaign_id ORDER BY performance_month) AS diff_pm_roas,
    CASE 
        WHEN (roas) - LAG(roas) OVER(PARTITION BY campaign_id ORDER BY performance_month) > 0 THEN 'Increase'
        WHEN (roas) - LAG(roas) OVER(PARTITION BY campaign_id ORDER BY performance_month) < 0 THEN 'Decrease'
        ELSE 'No Change'
    END AS pm_change,
    ROUND(
        CASE 
            WHEN LAG(roas) OVER(PARTITION BY campaign_id ORDER BY performance_month) = 0 THEN NULL 
            ELSE ((roas) - LAG(roas) OVER(PARTITION BY campaign_id ORDER BY performance_month))/LAG(roas) OVER(PARTITION BY campaign_id ORDER BY performance_month)*100 
        END
    ,2) AS mom_percentage
FROM roas_metrics;
GO

SELECT *
FROM gold.funnel_campaigns_roas
ORDER BY campaign_id, performance_month;
GO

--=====================================
-- 4.2) TOFU Top of Funnel Contributers
--=====================================
-- MoM by Full Purchase Revenues and Monthly Ad Spend
-- Analyze Month-over-Month ROAS performance by acquisition campaign to see which campaigns are bringing users in
DROP VIEW IF EXISTS gold.acquisition_campaigns_roas;
GO

CREATE VIEW gold.acquisition_campaigns_roas AS
WITH first_touch_data AS (
    SELECT 
        f.*,
        ROW_NUMBER() OVER (
            PARTITION BY f.user_id, f.purchase_id 
            ORDER BY f.touchpoint_time ASC  -- prepare to filter for first touchpoint
        ) AS rn
    FROM gold.fact_attribution_linear_with_costs f
    WHERE f.campaign_id IS NOT NULL 
        AND f.channel NOT IN ('Direct','Email','Organic Search','Referral')
),
monthly_revenue AS (
    SELECT
        DATEFROMPARTS(YEAR(f.purchase_date), MONTH(f.purchase_date), 1) AS performance_month, 
        f.campaign_id AS acquisition_campaign, 
        c.campaign_name,
        SUM(f.revenue_share) AS current_revenue 
    FROM first_touch_data f
    LEFT JOIN gold.dim_campaign c 
        ON f.campaign_id = c.campaign_id
    WHERE f.rn = 1  -- only first touch
        AND f.cost_share > 0
    GROUP BY DATEFROMPARTS(YEAR(f.purchase_date), MONTH(f.purchase_date), 1), f.campaign_id, c.campaign_name
),
monthly_spend AS (
    SELECT 
        DATEFROMPARTS(YEAR(purchase_date), MONTH(purchase_date), 1) AS performance_month,
        campaign_id AS acquisition_campaign, 
        SUM(cost_share) AS current_spend 
    FROM first_touch_data 
    WHERE rn = 1  -- only first touch
        AND cost_share > 0
    GROUP BY DATEFROMPARTS(YEAR(purchase_date), MONTH(purchase_date), 1), campaign_id
),
roas_metrics AS (
SELECT
    COALESCE(r.performance_month, s.performance_month) AS performance_month,
    r.acquisition_campaign, 
    r.campaign_name,
    r.current_revenue,
    s.current_spend,
    r.current_revenue/NULLIF(s.current_spend, 0) AS roas
FROM monthly_revenue r
FULL JOIN monthly_spend s 
ON r.performance_month = s.performance_month 
    AND r.acquisition_campaign = s.acquisition_campaign

) 
SELECT 
    performance_month,
    acquisition_campaign, 
    campaign_name,
    current_revenue,
    current_spend, 
    roas AS current_roas,
    AVG(roas) OVER(PARTITION BY acquisition_campaign) AS avg_roas,
    roas - AVG(roas) OVER(PARTITION BY acquisition_campaign) AS diff_avg,
    CASE 
        WHEN roas - AVG(roas) OVER(PARTITION BY acquisition_campaign) > 0 THEN 'Above Avg'
        WHEN roas - AVG(roas) OVER(PARTITION BY acquisition_campaign) < 0 THEN 'Below Avg' 
        ELSE 'Equals Average'
    END AS avg_change,
    -- Month-over_Month Analysis 
    LAG(roas) OVER(PARTITION BY acquisition_campaign ORDER BY performance_month) AS pm_roas, 
    roas - LAG(roas) OVER(PARTITION BY acquisition_campaign ORDER BY performance_month) AS diff_pm_roas,
    CASE 
        WHEN roas - LAG(roas) OVER(PARTITION BY acquisition_campaign ORDER BY performance_month) > 0 THEN 'Increase'
        WHEN roas - LAG(roas) OVER(PARTITION BY acquisition_campaign ORDER BY performance_month) < 0 THEN 'Decrease'
        ELSE 'No Change'
    END AS pm_change,
    ROUND(
        CASE 
            WHEN LAG(roas) OVER(PARTITION BY acquisition_campaign ORDER BY performance_month) = 0 THEN NULL 
            ELSE (roas - LAG(roas) OVER(PARTITION BY   acquisition_campaign ORDER BY performance_month))/LAG(roas) OVER(PARTITION BY acquisition_campaign ORDER BY performance_month)*100 
        END
    ,2) AS mom_percentage
FROM roas_metrics;
GO 

SELECT * 
FROM gold.acquisition_campaigns_roas
ORDER BY acquisition_campaign, performance_month;
GO

--==============================================
-- 4.3) BOFU Bottom of Funnel Conversion Drivers
--==============================================
-- MoM by Full Purchase Revenues and Monthly Ad Spend
-- Analyze Month-over-Month ROAS performance by last-touch campaign to see which campaigns are driving conversion
DROP VIEW IF EXISTS gold.last_touch_campaigns_roas;
GO

CREATE VIEW gold.last_touch_campaigns_roas AS
WITH last_touch_data AS (
    SELECT 
        f.*,
        ROW_NUMBER() OVER (
            PARTITION BY f.user_id, f.purchase_id 
            ORDER BY f.touchpoint_time DESC
        ) AS rn
    FROM gold.fact_attribution_linear_with_costs f
    WHERE f.campaign_id IS NOT NULL 
        AND f.channel NOT IN ('Direct','Email','Organic Search','Referral')
),
monthly_revenue AS (
    SELECT
        DATEFROMPARTS(YEAR(f.purchase_date), MONTH(f.purchase_date), 1) AS performance_month, 
        f.last_touch_campaign, 
        c.campaign_name,
        SUM(f.revenue) AS current_revenue
    FROM gold.fact_attribution_last_touch f          -- ! full revenue
    INNER JOIN last_touch_data ltd 
        ON f.purchase_id = ltd.purchase_id           -- same purchase
        AND f.last_touch_campaign = ltd.campaign_id  -- same campaign was last touch
        AND ltd.rn = 1                               -- ensuring to be last touch
        AND ltd.cost_share > 0                       -- with costs
    LEFT JOIN gold.dim_campaign c 
        ON f.last_touch_campaign = c.campaign_id
    WHERE f.last_touch_campaign IS NOT NULL
    GROUP BY DATEFROMPARTS(YEAR(f.purchase_date), MONTH(f.purchase_date), 1), f.last_touch_campaign, c.campaign_name
),
monthly_spend AS (
    SELECT 
        DATEFROMPARTS(YEAR(purchase_date), MONTH(purchase_date), 1) AS performance_month,
        campaign_id, 
        SUM(cost_share) AS current_spend  -- cost-Share von Last Touch
    FROM last_touch_data
    WHERE rn = 1
        AND cost_share > 0
    GROUP BY DATEFROMPARTS(YEAR(purchase_date), MONTH(purchase_date), 1), campaign_id
),
roas_metrics AS (
SELECT
    COALESCE(r.performance_month, s.performance_month) AS performance_month,
    r.last_touch_campaign, 
    r.campaign_name,
    r.current_revenue,
    s.current_spend,
    r.current_revenue/NULLIF(s.current_spend, 0) AS roas
FROM monthly_revenue r
FULL JOIN monthly_spend s 
ON r.performance_month = s.performance_month 
    AND r.last_touch_campaign = s.campaign_id
)  

SELECT 
    performance_month,
    last_touch_campaign, 
    campaign_name,
    current_revenue,
    current_spend,
    roas AS current_roas,
    AVG(roas) OVER(PARTITION BY last_touch_campaign) AS avg_roas,
    roas - AVG(roas) OVER(PARTITION BY last_touch_campaign) AS diff_avg,
    CASE 
        WHEN roas - AVG(roas) OVER(PARTITION BY last_touch_campaign) > 0 THEN 'Above Avg'
        WHEN roas - AVG(roas) OVER(PARTITION BY last_touch_campaign) < 0 THEN 'Below Avg' 
        ELSE 'Equals Average'
    END AS avg_change,
    -- Month-over_Month Analysis 
    LAG(roas) OVER(PARTITION BY last_touch_campaign ORDER BY performance_month) AS pm_roas, 
    roas - LAG(roas) OVER(PARTITION BY last_touch_campaign ORDER BY performance_month) AS diff_pm_roas,
    CASE 
        WHEN roas - LAG(roas) OVER(PARTITION BY last_touch_campaign ORDER BY performance_month) > 0 THEN 'Increase'
        WHEN roas - LAG(roas) OVER(PARTITION BY last_touch_campaign ORDER BY performance_month) < 0 THEN 'Decrease'
        ELSE 'No Change'
    END AS pm_change,
    ROUND(
        CASE 
            WHEN LAG(roas) OVER(PARTITION BY last_touch_campaign ORDER BY performance_month) = 0 THEN NULL 
            ELSE (roas - LAG(roas) OVER(PARTITION BY last_touch_campaign ORDER BY performance_month))/LAG(roas) OVER(PARTITION BY last_touch_campaign ORDER BY performance_month)*100 
        END
    ,2) AS mom_percentage
FROM roas_metrics
WHERE last_touch_campaign IS NOT NULL;
GO 

SELECT * 
FROM gold.last_touch_campaigns_roas
ORDER BY last_touch_campaign, performance_month;


--==================================
-- 4.4) TOP 10 MoM TOFU/Multi/BOFU 
--==================================
-- Top 10 MoM ROAS campaigns within funnel
SELECT TOP 10 *
FROM gold.funnel_campaigns_roas
ORDER BY diff_pm_roas DESC; 

SELECT TOP 10 *
FROM gold.funnel_campaigns_roas
WHERE pm_roas > 0 
ORDER BY mom_percentage DESC;

-- Top 10 MoM ROAS acquisition campaigns
SELECT TOP 10 *
FROM gold.acquisition_campaigns_roas
ORDER BY diff_pm_roas DESC; 

SELECT TOP 10 *
FROM gold.acquisition_campaigns_roas
WHERE pm_roas > 0
ORDER BY mom_percentage DESC;

-- Top 10 MoM  ROAS last-touch campaigns
SELECT TOP 10 *
FROM gold.last_touch_campaigns_roas
ORDER BY diff_pm_roas DESC; 

SELECT TOP 10 *
FROM gold.last_touch_campaigns_roas
WHERE pm_roas > 0
ORDER BY mom_percentage DESC;



