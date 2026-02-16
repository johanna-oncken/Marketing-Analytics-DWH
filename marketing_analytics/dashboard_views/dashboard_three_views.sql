/*
===============================================================================
Dashboard 3: Customer Journey Analysis — CSV-Export Views (German Locale)
===============================================================================
Purpose:
    - Tableau-ready views for CSV export with German decimal formatting.

Dependencies:
    - gold.fact_conversion_paths (from Script 10)
    - gold.channel_scorecard (from Script 11)

===============================================================================
*/
USE marketing_dw;
GO


/*
===============================================================================
1) KPI Row: Repeat Buyer Efficiency, Avg Touchpoints, Total Conversions
===============================================================================
DROP VIEW IF EXISTS gold.dashboard_journey_kpi;
GO

CREATE VIEW gold.dashboard_journey_kpi AS
WITH metrics AS (
    SELECT
        AVG(CASE WHEN purchase_type = 'First' 
            THEN touchpoints_to_conversion * 1.0 END) AS avg_tp_first,
        AVG(CASE WHEN purchase_type = 'Repeat' 
            THEN touchpoints_to_conversion * 1.0 END) AS avg_tp_repeat,
        COUNT(*) AS total_conversions
    FROM gold.fact_conversion_paths
)
SELECT
    REPLACE(CAST(avg_tp_first AS VARCHAR(50)), '.', ',') AS avg_touchpoints_first,
    REPLACE(CAST(avg_tp_repeat AS VARCHAR(50)), '.', ',') AS avg_touchpoints_repeat,
    REPLACE(CAST(
        ROUND((avg_tp_repeat - avg_tp_first) / NULLIF(avg_tp_first, 0) * 100, 1)
    AS VARCHAR(50)), '.', ',') AS delta_pct,
    total_conversions
FROM metrics;
GO

SELECT * FROM gold.dashboard_journey_kpi;
GO


/*
===============================================================================
2) Path Length Distribution (Histogram)
===============================================================================
Bins touchpoints into 1, 2, 3, 4, 5, 6, 7+ for the histogram.
One row per bin with conversion count.
*/
DROP VIEW IF EXISTS gold.dashboard_path_length_distribution;
GO

CREATE VIEW gold.dashboard_path_length_distribution AS
SELECT
    touchpoints_to_conversion,
    COUNT(*) AS conversion_count
FROM gold.fact_conversion_paths
GROUP BY touchpoints_to_conversion;
GO

SELECT * 
FROM gold.dashboard_path_length_distribution
ORDER BY touchpoints_to_conversion;
GO


/*
===============================================================================
3) First vs Repeat Buyers (Bar Chart)
===============================================================================
Two rows: one for First, one for Repeat.
Used for the grouped bar chart + delta callout.
*/
DROP VIEW IF EXISTS gold.dashboard_first_vs_repeat;
GO

CREATE VIEW gold.dashboard_first_vs_repeat AS
SELECT
    purchase_type,
    REPLACE(CAST(
        AVG(touchpoints_to_conversion * 1.0) 
    AS VARCHAR(50)), '.', ',') AS avg_touchpoints,
    COUNT(*) AS purchase_count
FROM gold.fact_conversion_paths
GROUP BY purchase_type;
GO

SELECT * FROM gold.dashboard_first_vs_repeat;
GO


/*
===============================================================================
4) Engagement vs Conversion (Table — Scorecard Query 2)
===============================================================================
One row per channel: Click Intensity, BOFU CVR, Channel Profile.
Source: gold.channel_scorecard aggregated across months.
*/
/*
DROP VIEW IF EXISTS gold.dashboard_engagement_conversion;
GO

CREATE VIEW gold.dashboard_engagement_conversion AS
SELECT
    channel,
    REPLACE(CAST(AVG(click_intensity) AS VARCHAR(50)), '.', ',') AS avg_click_intensity,
    REPLACE(CAST(AVG(bofu_cvr) AS VARCHAR(50)), '.', ',') AS avg_bofu_cvr,
    CASE
        WHEN AVG(click_intensity) > 0.5 AND AVG(bofu_cvr) >= 0.10 THEN 'Closer'
        WHEN AVG(click_intensity) > 0.5 AND AVG(bofu_cvr) < 0.10 THEN 'Assist'
        WHEN AVG(click_intensity) <= 0.5 AND AVG(bofu_cvr) >= 0.10 THEN 'Closer'
        ELSE 'Discovery'
    END AS channel_profile,
    CASE
        WHEN AVG(click_intensity) > 0.5 THEN 'High'
        ELSE 'Medium'
    END AS click_intensity_level
FROM gold.channel_scorecard
WHERE click_intensity IS NOT NULL AND bofu_cvr IS NOT NULL
GROUP BY channel;
GO

SELECT * 
FROM gold.dashboard_engagement_conversion
ORDER BY avg_bofu_cvr DESC;
GO
*/

DROP VIEW IF EXISTS gold.dashboard_engagement_conversion;
GO

CREATE VIEW gold.dashboard_engagement_conversion AS
SELECT
    channel,
    REPLACE(CAST(AVG(click_intensity) AS VARCHAR(50)), '.', ',') AS avg_click_intensity,
    CASE
        WHEN AVG(click_intensity) > 0.5 THEN 'High'
        ELSE 'Medium'
    END AS click_intensity_level,
    REPLACE(CAST(AVG(bofu_cvr) AS VARCHAR(50)), '.', ',') AS avg_bofu_cvr,
    CASE
        WHEN AVG(click_intensity) > 0.5 AND AVG(bofu_cvr) >= 0.10 THEN 'Closer'
        WHEN AVG(click_intensity) > 0.5 AND AVG(bofu_cvr) < 0.10 THEN 'Assist'
        WHEN AVG(click_intensity) <= 0.5 AND AVG(bofu_cvr) >= 0.10 THEN 'Closer'
        ELSE 'Discovery'
    END AS channel_profile
FROM gold.channel_scorecard
WHERE click_intensity IS NOT NULL AND bofu_cvr IS NOT NULL
GROUP BY channel;
GO

SELECT * 
FROM gold.dashboard_engagement_conversion
ORDER BY avg_bofu_cvr DESC;

/*
===============================================================================
5) BOFU Scale vs Efficiency (Scatter + Table — Scorecard Query 4)
===============================================================================
One row per channel: BOFU CVR (Y-axis), Total Conversions (X-axis), Profile.
Source: gold.channel_scorecard aggregated across months.

Quadrant logic:
    - Median CVR and median conversions define the quadrant boundaries.
    - Top-right = IDEAL (high CVR + high scale)
    - Top-left = Niche Performer (high CVR, low scale)
    - Bottom-right = Scale Opportunity (low CVR, high scale)
    - Bottom-left = Underperformer
*/
DROP VIEW IF EXISTS gold.dashboard_bofu_scale;
GO

CREATE VIEW gold.dashboard_bofu_scale AS
WITH channel_metrics AS (
    SELECT
        channel,
        AVG(bofu_cvr) AS avg_bofu_cvr,
        SUM(bofu_conversions) AS total_bofu_conversions,
        SUM(bofu_revenue) AS total_bofu_revenue
    FROM gold.channel_scorecard
    WHERE bofu_cvr IS NOT NULL
    GROUP BY channel
),
medians AS (
    SELECT
        AVG(avg_bofu_cvr) AS median_cvr,
        AVG(total_bofu_conversions * 1.0) AS median_conversions
    FROM channel_metrics
)
SELECT
    cm.channel,
    REPLACE(CAST(cm.avg_bofu_cvr AS VARCHAR(50)), '.', ',') AS avg_bofu_cvr,
    cm.total_bofu_conversions,
    REPLACE(CAST(cm.total_bofu_revenue AS VARCHAR(50)), '.', ',') AS total_bofu_revenue,
    CASE
        WHEN cm.avg_bofu_cvr >= m.median_cvr AND cm.total_bofu_conversions >= m.median_conversions 
            THEN 'Scale Leader'
        WHEN cm.avg_bofu_cvr >= m.median_cvr AND cm.total_bofu_conversions < m.median_conversions 
            THEN 'Niche Performer'
        WHEN cm.avg_bofu_cvr < m.median_cvr AND cm.total_bofu_conversions >= m.median_conversions 
            THEN 'Scale Opportunity'
        ELSE 'Underperformer'
    END AS scale_profile
FROM channel_metrics cm
CROSS JOIN medians m;
GO

SELECT * 
FROM gold.dashboard_bofu_scale
ORDER BY total_bofu_conversions DESC;
GO
