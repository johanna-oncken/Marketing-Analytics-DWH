/*
===============================================================================
CAC Customer Acquisition Cost Performance Analysis (Month-over-Month)
===============================================================================
Purpose:
    - To measure the CAC performance of marketing components such as campaigns and channels over time (CAC lower = better).
    - For benchmarking and identifying high-performing entities.
    - To track monthly 2024 trends and growth.

SQL Functions Used:
    - LAG(): Accesses data from previous rows.
    - AVG() OVER(): Computes average values within partitions.
    - CASE: Defines conditional logic for trend analysis.

Queries: 
    1) CAC overall 
    2) CAC Performance monthly
    3.1) Monthly CAC Performance and MOM-Analysis by Channels
    3.2) Top Ten Channels by CAC Monthly Improvements 
    3.3) Top Ten Channels by CAC Monthly Declinse
    4.1) Monthly CAC Performance and MOM-Analysis by Campaigns
    4.2) Top Ten Campaigns by CAC Monthly Improvements 
    4.3) Top Ten Campaigns by CAC Monthly Declines 

===============================================================================
*/
USE marketing_dw; 
GO


/*
===============================================================================
1) CAC overall
===============================================================================
*/
SELECT
    (SELECT COUNT(DISTINCT user_id) FROM gold.fact_purchases) AS new_customers,
    (SELECT SUM(spend) FROm gold.fact_spend) AS current_spend,
    (SELECT SUM(spend) FROm gold.fact_spend)
    /
    (SELECT COUNT(DISTINCT user_id) FROM gold.fact_purchases) AS cac;


/*
===============================================================================
2) CAC Performance monthly
===============================================================================
*/
DROP VIEW IF EXISTS gold.cac;
GO

CREATE VIEW gold.cac AS
WITH monthly_customers AS (
SELECT
    DATEFROMPARTS(YEAR(purchase_date), MONTH(purchase_date), 1) AS performance_month, 
    COUNT(DISTINCT user_id) AS new_customers
FROM gold.fact_purchases 
GROUP BY DATEFROMPARTS(YEAR(purchase_date), MONTH(purchase_date), 1)
), 
monthly_spend AS (
SELECT 
    DATEFROMPARTS(YEAR(spend_date), MONTH(spend_date), 1) AS performance_month,
    SUM(spend) AS current_spend 
FROM gold.fact_spend 
GROUP BY DATEFROMPARTS(YEAR(spend_date), MONTH(spend_date), 1)
), 
cac_metrics AS (
SELECT
    COALESCE(c.performance_month, s.performance_month) AS performance_month,
    c.new_customers AS current_new_customers,
    s.current_spend,
    s.current_spend/NULLIF(c.new_customers, 0) AS cac
FROM monthly_customers c
FULL JOIN monthly_spend s 
ON c.performance_month = s.performance_month 
)

SELECT 
    performance_month,
    current_spend,
    current_new_customers,
    cac AS current_cac,
    AVG(cac) OVER() AS avg_cac,
    (cac) - AVG(cac) OVER() AS diff_avg,
    CASE 
        WHEN (cac) - AVG(cac) OVER() > 0 THEN 'Worsened (Above Avg)'
        WHEN (cac) - AVG(cac) OVER() < 0 THEN 'Improved (Below Avg)' 
        ELSE 'Equals Average'
    END AS avg_change, 
    -- Month-over_Month Analysis 
    LAG(cac) OVER(ORDER BY performance_month) AS pm_cac, 
    (cac) - LAG(cac) OVER(ORDER BY performance_month) AS diff_pm_cac,
    CASE 
        WHEN (cac) - LAG(cac) OVER(ORDER BY performance_month) > 0 THEN 'Worsened (Higher)'
        WHEN (cac) - LAG(cac) OVER(ORDER BY performance_month) < 0 THEN 'Improved (Lower)'
        ELSE 'No Change'
    END AS pm_change,
    ROUND(
        CASE 
            WHEN LAG(cac) OVER(ORDER BY performance_month) = 0 THEN NULL 
            ELSE ((cac) - LAG(cac) OVER(ORDER BY performance_month))/LAG(cac) OVER(ORDER BY performance_month)*100 
        END
    ,2) AS mom_percentage
FROM cac_metrics;
GO

SELECT *
FROM gold.cac
ORDER BY performance_month;
GO



/*
===============================================================================
3) CHANNELS
===============================================================================
*/
-- 3.1) MoM by Monthly Ad Spend and Newly Acquired Customers
--      Analyze Month-over-Month TOFU CAC channel performance 
DROP VIEW IF EXISTS gold.channels_cac;
GO

CREATE VIEW gold.channels_cac AS
WITH monthly_customers AS (
SELECT
    DATEFROMPARTS(YEAR(f.purchase_date), MONTH(f.purchase_date), 1) AS performance_month, 
    acquisition_channel,
    COUNT(DISTINCT user_id) AS new_customers
FROM gold.fact_purchases f
WHERE acquisition_channel IS NOT NULL
GROUP BY DATEFROMPARTS(YEAR(f.purchase_date), MONTH(f.purchase_date), 1), acquisition_channel
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
cac_metrics AS (
SELECT
    COALESCE(c.performance_month, s.performance_month) AS performance_month,
    c.acquisition_channel, 
    c.new_customers AS current_new_customers,
    s.current_spend,
    s.current_spend/NULLIF(c.new_customers, 0) AS cac
FROM monthly_customers c
FULL JOIN monthly_spend s 
ON c.performance_month = s.performance_month 
    AND c.acquisition_channel = s.channel
)

SELECT 
    performance_month,
    acquisition_channel, 
    current_spend,
    current_new_customers,
    cac AS current_cac,
    AVG(cac) OVER(PARTITION BY acquisition_channel) AS avg_cac,
    (cac) - AVG(cac) OVER(PARTITION BY acquisition_channel) AS diff_avg,
    CASE 
        WHEN (cac) - AVG(cac) OVER(PARTITION BY acquisition_channel) > 0 THEN 'Worsened (Above Avg)'
        WHEN (cac) - AVG(cac) OVER(PARTITION BY acquisition_channel) < 0 THEN 'Improved (Below Avg)' 
        ELSE 'Equals Average'
    END AS avg_change,
    -- Month-over_Month Analysis 
    LAG(cac) OVER(PARTITION BY acquisition_channel ORDER BY performance_month) AS pm_cac, 
    (cac) - LAG(cac) OVER(PARTITION BY acquisition_channel ORDER BY performance_month) AS diff_pm_cac,
    CASE 
        WHEN (cac) - LAG(cac) OVER(PARTITION BY acquisition_channel ORDER BY performance_month) > 0 THEN 'Worsened (Higher)'
        WHEN (cac) - LAG(cac) OVER(PARTITION BY acquisition_channel ORDER BY performance_month) < 0 THEN 'Improved (Lower)'
        ELSE 'No Change'
    END AS pm_change,
    ROUND(
        CASE 
            WHEN LAG(cac) OVER(PARTITION BY acquisition_channel ORDER BY performance_month) = 0 THEN NULL 
            ELSE ((cac) - LAG(cac) OVER(PARTITION BY acquisition_channel ORDER BY performance_month))/LAG(cac) OVER(PARTITION BY acquisition_channel ORDER BY performance_month)*100 
        END
    ,2) AS mom_percentage
FROM cac_metrics
WHERE acquisition_channel IS NOT NULL;
GO

SELECT *
FROM gold.channels_cac
ORDER BY acquisition_channel, performance_month;
GO

-- 3.2) Top 10 Improvements MoM CAC channels
SELECT TOP 10 *
FROM gold.channels_cac
WHERE diff_pm_cac IS NOT NULL
ORDER BY diff_pm_cac ASC; 

SELECT TOP 10 *
FROM gold.channels_cac
WHERE pm_cac IS NOT NULL
ORDER BY mom_percentage ASC;

-- 3.3) Top 10 Declines MoM CAC channels
SELECT TOP 10 *
FROM gold.channels_cac
WHERE diff_pm_cac IS NOT NULL
ORDER BY diff_pm_cac DESC; 

SELECT TOP 10 *
FROM gold.channels_cac
WHERE pm_cac IS NOT NULL
ORDER BY mom_percentage DESC;




/*
===============================================================================
4) CAMPAIGNS
===============================================================================
*/
-- 4.1) MoM by Monthly Ad Spend and Newly Acquired Customers
--      Analyze Month-over-Month TOFU CAC campaign performance 
DROP VIEW IF EXISTS gold.campaigns_cac;
GO

CREATE VIEW gold.campaigns_cac AS
WITH monthly_customers AS (
SELECT
    DATEFROMPARTS(YEAR(f.purchase_date), MONTH(f.purchase_date), 1) AS performance_month, 
    f.acquisition_campaign, 
    c.campaign_name,
    COUNT(DISTINCT f.user_id) AS new_customers
FROM gold.fact_purchases f
LEFT JOIN gold.dim_campaign c 
ON f.acquisition_campaign = c.campaign_id
WHERE f.acquisition_campaign IS NOT NULL
GROUP BY DATEFROMPARTS(YEAR(f.purchase_date), MONTH(f.purchase_date), 1), f.acquisition_campaign, c.campaign_name
), 
monthly_spend AS (
SELECT 
    DATEFROMPARTS(YEAR(spend_date), MONTH(spend_date), 1) AS performance_month,
    campaign_id, 
    SUM(spend) AS current_spend 
FROM gold.fact_spend 
WHERE campaign_id IS NOT NULL 
GROUP BY DATEFROMPARTS(YEAR(spend_date), MONTH(spend_date), 1), campaign_id
), 
cac_metrics AS (
SELECT
    COALESCE(c.performance_month, s.performance_month) AS performance_month,
    c.acquisition_campaign, 
    c.campaign_name,
    c.new_customers AS current_new_customers,
    s.current_spend,
    s.current_spend/NULLIF(c.new_customers, 0) AS cac
FROM monthly_customers c
FULL JOIN monthly_spend s 
ON c.performance_month = s.performance_month 
    AND c.acquisition_campaign = s.campaign_id
)

SELECT 
    performance_month,
    acquisition_campaign, 
    campaign_name,
    current_spend,
    current_new_customers,
    cac AS current_cac,
    AVG(cac) OVER(PARTITION BY acquisition_campaign) AS avg_cac,
    (cac) - AVG(cac) OVER(PARTITION BY acquisition_campaign) AS diff_avg,
    CASE 
        WHEN (cac) - AVG(cac) OVER(PARTITION BY acquisition_campaign) > 0 THEN 'Worsened (Above Avg)'
        WHEN (cac) - AVG(cac) OVER(PARTITION BY acquisition_campaign) < 0 THEN 'Improved (Below Avg)' 
        ELSE 'Equals Average'
    END AS avg_change,
    -- Month-over_Month Analysis 
    LAG(cac) OVER(PARTITION BY acquisition_campaign ORDER BY performance_month) AS pm_cac, 
    (cac) - LAG(cac) OVER(PARTITION BY acquisition_campaign ORDER BY performance_month) AS diff_pm_cac,
    CASE 
        WHEN (cac) - LAG(cac) OVER(PARTITION BY acquisition_campaign ORDER BY performance_month) > 0 THEN 'Worsened (Higher)'
        WHEN (cac) - LAG(cac) OVER(PARTITION BY acquisition_campaign ORDER BY performance_month) < 0 THEN 'Improved (Lower)'
        ELSE 'No Change'
    END AS pm_change,
    ROUND(
        CASE 
            WHEN LAG(cac) OVER(PARTITION BY acquisition_campaign ORDER BY performance_month) = 0 THEN NULL 
            ELSE ((cac) - LAG(cac) OVER(PARTITION BY acquisition_campaign ORDER BY performance_month))/LAG(cac) OVER(PARTITION BY acquisition_campaign ORDER BY performance_month)*100 
        END
    ,2) AS mom_percentage
FROM cac_metrics
WHERE acquisition_campaign IS NOT NULL;
GO

SELECT *
FROM gold.campaigns_cac
ORDER BY acquisition_campaign, performance_month;
GO

-- 4.2) Top 10 Improvements MoM CAC campaigns
SELECT TOP 10 *
FROM gold.campaigns_cac
WHERE diff_pm_cac IS NOT NULL
ORDER BY diff_pm_cac ASC; 

SELECT TOP 10 *
FROM gold.campaigns_cac
WHERE pm_cac IS NOT NULL
ORDER BY mom_percentage ASC;

-- 4.3) Top 10 Declines MoM CAC campaigns
SELECT TOP 10 *
FROM gold.campaigns_cac
WHERE diff_pm_cac IS NOT NULL
ORDER BY diff_pm_cac DESC; 

SELECT TOP 10 *
FROM gold.campaigns_cac
WHERE pm_cac IS NOT NULL
ORDER BY mom_percentage DESC;



