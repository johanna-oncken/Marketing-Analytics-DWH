/*
===============================================================================
Conversion Path Analysis
===============================================================================
Purpose:
    - To measure the number of touchpoints required per conversion, segmented 
      by first vs. repeat purchases.
    - To evaluate closing effectiveness (by last-touch channel/campaign) 
      and funnel nurturing difficulty (by acquisition channel/campaign).
    - To track monthly 2024 trends.

Key Design Decisions:
    - Touchpoints are counted PER CONVERSION WINDOW, not cumulatively since acquisition.
      For first purchases: all touchpoints before the purchase date.
      For repeat purchases: only touchpoints after the previous purchase date.
      This ensures path length measures actual conversion effort per purchase,
      not how long a user has been in the system.
    - purchase_type distinguishes 'First' vs 'Repeat' purchases using LAG().
      First purchases typically require more touchpoints (building trust);
      repeat purchases indicate established trust and should show shorter paths.
    - Purchases without tracked touchpoints show touchpoints_to_conversion = 0
      (direct/untracked conversions).
    - purchase_id is used as tiebreaker in LAG() ordering to handle multiple 
      purchases on the same date deterministically.

SQL Functions Used:
    - LAG(): Identifies previous purchase date per user for window segmentation.
    - CASE: Classifies first vs. repeat purchases.
    - COUNT() with interval JOIN: Counts touchpoints within each conversion window.
    - AVG(), GROUP BY, LEFT JOIN, COALESCE(), DATEFROMPARTS()

Queries: 
    1) Conversion Paths View (reusable base for all analyses)
    2) Path Length by Month (with First/Repeat split)
    3.1) Path Length by Last-Touch Channel (closing effectiveness)
    3.2) Path Length by Acquisition Channel (funnel nurturing difficulty)
    4.1) Path Length by Last-Touch Campaign 
    4.2) Path Length by Acquisition Campaign
===============================================================================
*/
USE marketing_dw;
GO


/*
===============================================================================
1) Conversion Paths View
===============================================================================
Base view: for each purchase, counts the touchpoints that occurred within 
its conversion window (after the previous purchase, or since the beginning 
for first purchases). All subsequent queries aggregate from this view.
*/
DROP VIEW IF EXISTS gold.fact_conversion_paths;
GO

CREATE VIEW gold.fact_conversion_paths AS
WITH purchase_sequence AS (
    SELECT 
        p.purchase_id,
        p.user_id,
        p.purchase_date,
        p.acquisition_channel,
        p.acquisition_campaign,
        LAG(p.purchase_date) OVER (
            PARTITION BY p.user_id 
            ORDER BY p.purchase_date, p.purchase_id
        ) AS previous_purchase_date,
        CASE 
            WHEN LAG(p.purchase_date) OVER (
                PARTITION BY p.user_id 
                ORDER BY p.purchase_date, p.purchase_id
            ) IS NULL THEN 'First'
            ELSE 'Repeat'
        END AS purchase_type
    FROM gold.fact_purchases p
),
touchpoint_counts AS (
    SELECT 
        ps.purchase_id,
        ps.user_id,
        ps.purchase_date,
        ps.acquisition_channel,
        ps.acquisition_campaign,
        ps.purchase_type,
        COUNT(t.touchpoint_key) AS touchpoints_to_conversion
    FROM purchase_sequence ps
    LEFT JOIN gold.fact_touchpoints t 
        ON ps.user_id = t.user_id
        AND t.touchpoint_time <= ps.purchase_date
        AND t.touchpoint_time > COALESCE(ps.previous_purchase_date, '1900-01-01')
    GROUP BY 
        ps.purchase_id, ps.user_id, ps.purchase_date,
        ps.acquisition_channel, ps.acquisition_campaign,
        ps.purchase_type
)
SELECT 
    tc.purchase_id,
    tc.user_id,
    DATEFROMPARTS(YEAR(tc.purchase_date), MONTH(tc.purchase_date), 1) AS performance_month,
    tc.acquisition_channel,
    tc.acquisition_campaign,
    tc.purchase_type,
    tc.touchpoints_to_conversion,
    lt.last_touch_channel,
    lt.last_touch_campaign
FROM touchpoint_counts tc
LEFT JOIN gold.fact_attribution_last_touch lt
    ON tc.purchase_id = lt.purchase_id;
GO


/*
===============================================================================
2) Path Length by Month
===============================================================================
*/
-- Overall by month
SELECT 
    performance_month,
    COUNT(*) AS purchase_count,
    AVG(touchpoints_to_conversion * 1.0) AS avg_path_length
FROM gold.fact_conversion_paths
GROUP BY performance_month
ORDER BY performance_month;
GO

-- Split by first vs. repeat purchases
SELECT 
    performance_month,
    purchase_type,
    COUNT(*) AS purchase_count,
    AVG(touchpoints_to_conversion * 1.0) AS avg_path_length
FROM gold.fact_conversion_paths
GROUP BY performance_month, purchase_type
ORDER BY performance_month, purchase_type;
GO


/*
===============================================================================
3) CHANNELS
===============================================================================
3.1) Path Length by Last-Touch Channel (closing effectiveness)
===============================================================================
Channels that close with fewer touchpoints convert more efficiently.
Lower path length = stronger closing channel.
*/
SELECT 
    performance_month,
    last_touch_channel,
    purchase_type,
    COUNT(*) AS purchase_count,
    AVG(touchpoints_to_conversion * 1.0) AS avg_path_length
FROM gold.fact_conversion_paths
WHERE last_touch_channel IS NOT NULL
GROUP BY performance_month, last_touch_channel, purchase_type
ORDER BY last_touch_channel, performance_month, purchase_type;
GO

/*
===============================================================================
3.2) Path Length by Acquisition Channel (funnel nurturing difficulty)
===============================================================================
Acquisition channels whose users need fewer touchpoints to convert 
produce higher-intent users. Lower path length = better lead quality.
*/
SELECT 
    performance_month,
    acquisition_channel,
    purchase_type,
    COUNT(*) AS purchase_count,
    AVG(touchpoints_to_conversion * 1.0) AS avg_path_length
FROM gold.fact_conversion_paths
WHERE acquisition_channel IS NOT NULL
GROUP BY performance_month, acquisition_channel, purchase_type
ORDER BY acquisition_channel, performance_month, purchase_type;
GO


/*
===============================================================================
4) CAMPAIGNS
===============================================================================
4.1) Path Length by Last-Touch Campaign
===============================================================================
*/
SELECT 
    performance_month,
    cp.last_touch_campaign,
    c.campaign_name,
    cp.purchase_type,
    COUNT(*) AS purchase_count,
    AVG(cp.touchpoints_to_conversion * 1.0) AS avg_path_length
FROM gold.fact_conversion_paths cp
LEFT JOIN gold.dim_campaign c
    ON cp.last_touch_campaign = c.campaign_id
WHERE cp.last_touch_campaign IS NOT NULL
GROUP BY performance_month, cp.last_touch_campaign, c.campaign_name, cp.purchase_type
ORDER BY cp.last_touch_campaign, performance_month, cp.purchase_type;
GO

/*
===============================================================================
4.2) Path Length by Acquisition Campaign
===============================================================================
*/
SELECT 
    performance_month,
    cp.acquisition_campaign,
    c.campaign_name,
    cp.purchase_type,
    COUNT(*) AS purchase_count,
    AVG(cp.touchpoints_to_conversion * 1.0) AS avg_path_length
FROM gold.fact_conversion_paths cp
LEFT JOIN gold.dim_campaign c
    ON cp.acquisition_campaign = c.campaign_id
WHERE cp.acquisition_campaign IS NOT NULL
GROUP BY performance_month, cp.acquisition_campaign, c.campaign_name, cp.purchase_type
ORDER BY cp.acquisition_campaign, performance_month, cp.purchase_type;
GO