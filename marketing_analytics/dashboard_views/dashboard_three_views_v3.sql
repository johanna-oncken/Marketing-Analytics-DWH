/*
===============================================================================
Dashboard 3: Customer Journey Analysis — CSV-Export Views (Corrected)
===============================================================================
Purpose:
    - Tableau-ready views for CSV export with German decimal formatting.
    - Key Finding: "Business acquires well, but retains poorly."

Dependencies:
    - gold.fact_conversion_paths (from Script 10)

Views Created:
    1) gold.dashboard_journey_kpi — KPI row (Hero: 82% First-Time Buyers)
    2) gold.dashboard_path_trend — Line Chart: First vs Repeat by Month
    3) gold.dashboard_closing_effectiveness — Bar: Last-Touch Channel (Jan, First only)
    4) gold.dashboard_lead_quality — Bar: Acquisition Channel (Jan, First only)
    5) gold.dashboard_path_distribution — Histogram: Touchpoints to Conversion
===============================================================================
*/
USE marketing_dw;
GO


/*
===============================================================================
1) KPI Row
===============================================================================
Hero KPI: 82% First-Time Buyers (Retention Gap)
Supporting:
    - 58% convert within 0-4 touchpoints (Quick Decisions)
    - -30% efficiency for repeat buyers (Retention Potential)
    - Total conversions
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
    -- Hero KPI: First-Time Buyer Share
    REPLACE(CAST(
        ROUND(first_conversions * 100.0 / NULLIF(total_conversions, 0), 0)
    AS VARCHAR(50)), '.', ',') AS first_buyer_pct,
    
    -- Supporting: Quick Conversion Rate (0-4 touchpoints)
    REPLACE(CAST(
        ROUND(quick_conversions * 100.0 / NULLIF(total_conversions, 0), 0)
    AS VARCHAR(50)), '.', ',') AS quick_conversion_pct,
    
    -- Supporting: Repeat Buyer Efficiency
    REPLACE(CAST(
        ROUND((avg_path_repeat - avg_path_first) / NULLIF(avg_path_first, 0) * 100, 0)
    AS VARCHAR(50)), '.', ',') AS repeat_efficiency_pct,
    
    -- Context: Avg Path Lengths
    REPLACE(CAST(ROUND(avg_path_first, 1) AS VARCHAR(50)), '.', ',') AS avg_path_first,
    REPLACE(CAST(ROUND(avg_path_repeat, 1) AS VARCHAR(50)), '.', ',') AS avg_path_repeat,
    
    -- Context: Totals
    total_conversions,
    first_conversions,
    repeat_conversions
FROM base_metrics;
GO

SELECT * FROM gold.dashboard_journey_kpi;
GO


/*
===============================================================================
2) Path Length Trend: First vs Repeat by Month
===============================================================================
For the dual-line chart showing how path length evolves over time.
One row per month × purchase_type combination.
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
Which channels close with the fewest touchpoints?
Filtered to January + First purchases only for fair comparison.
Lower = better (faster closing).
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
Which acquisition channels produce the highest-intent users?
Filtered to January + First purchases only for fair comparison.
Lower = better (higher lead quality, faster first conversion).
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
How many touchpoints before conversion?
Shows full distribution for histogram visualization.
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
