/*
===============================================================================
Channel Efficiency Scorecard (Cross-Dimensional Analysis)
===============================================================================
Purpose:
    - To combine key marketing metrics across dimensions (engagement, conversion,
      cost, revenue, lifetime value) into a single Channel × Month view.
    - To identify channels that generate attention but don't close, channels that
      acquire cheap users with low LTV, and channels where efficiency and scale
      diverge.
    - To enable cross-metric comparisons on a consistent granularity level.

Key Design Decisions:
    - All metrics are aggregated to Channel × Month granularity to avoid
      mismatched JOIN granularities that distort averages.
    - Metrics are pulled from base fact tables rather than cross-joining 
      pre-aggregated performance views, which have different row structures.
    - TOFU perspective: acquisition_channel from fact_purchases (first-touch).
    - BOFU perspective: last_touch_channel from fact_attribution_last_touch.
    - Engagement metrics (clicks, impressions) come from fact_clicks/fact_touchpoints.
    - LTV metrics are aggregated from the cohort view at the final observed month
      per channel to avoid averaging across cohort months.
    - Channels without ad spend (organic) show NULL for CAC, ROAS, and spend.

Limitations:
    - In the synthetic data, more users have clicks (8,554) than impressions (8,267).
      This means click_intensity (clicks/impressions) can exceed 1.0 and should be 
      interpreted as relative engagement intensity rather than a true CTR.
    - LTV is based on 120-day cumulative values; true LTV would require 12-24 months.

SQL Functions Used:
    - CTEs for modular metric aggregation
    - COALESCE() for combining TOFU/BOFU perspectives
    - NULLIF() for division safety
    - LEFT JOIN for preserving channels without spend
    - MAX() for selecting latest cohort month LTV

Queries:
    1) Channel Efficiency Scorecard View (Channel × Month)
    2) Summary: Engagement vs. Conversion (which channels generate attention vs. close?)
    3) Summary: Acquisition Efficiency (cheap users vs. valuable users?)
    4) Summary: BOFU Scale vs. Efficiency (closing well vs. scaling?)
===============================================================================
*/
USE marketing_dw;
GO


/*
===============================================================================
1) Channel Efficiency Scorecard View
===============================================================================
Single view combining all key metrics per Channel × Month.
*/
DROP VIEW IF EXISTS gold.channel_scorecard;
GO

CREATE VIEW gold.channel_scorecard AS
WITH engagement AS (
    -- Impressions and clicks per channel per month
    SELECT
        DATEFROMPARTS(YEAR(t.touchpoint_time), MONTH(t.touchpoint_time), 1) AS performance_month,
        t.channel,
        COUNT(DISTINCT CASE WHEN t.interaction_type = 'Impression' THEN t.user_id END) AS users_with_impressions,
        SUM(CASE WHEN t.interaction_type = 'Impression' THEN 1 ELSE 0 END) AS impressions
    FROM gold.fact_touchpoints t
    GROUP BY DATEFROMPARTS(YEAR(t.touchpoint_time), MONTH(t.touchpoint_time), 1), t.channel
),
clicks AS (
    SELECT
        DATEFROMPARTS(YEAR(c.click_timestamp), MONTH(c.click_timestamp), 1) AS performance_month,
        c.click_channel AS channel,
        COUNT(*) AS total_clicks,
        COUNT(DISTINCT c.user_id) AS users_with_clicks
    FROM gold.fact_clicks c
    GROUP BY DATEFROMPARTS(YEAR(c.click_timestamp), MONTH(c.click_timestamp), 1), c.click_channel
),
bofu_conversions AS (
    -- Last-touch conversions and revenue per channel per month
    SELECT
        DATEFROMPARTS(YEAR(lt.purchase_date), MONTH(lt.purchase_date), 1) AS performance_month,
        lt.last_touch_channel AS channel,
        COUNT(*) AS bofu_conversions,
        COUNT(DISTINCT lt.user_id) AS bofu_converters,
        SUM(lt.revenue) AS bofu_revenue
    FROM gold.fact_attribution_last_touch lt
    GROUP BY DATEFROMPARTS(YEAR(lt.purchase_date), MONTH(lt.purchase_date), 1), lt.last_touch_channel
),
tofu_conversions AS (
    -- First-touch (acquisition) conversions and revenue per channel per month
    SELECT
        DATEFROMPARTS(YEAR(p.purchase_date), MONTH(p.purchase_date), 1) AS performance_month,
        p.acquisition_channel AS channel,
        COUNT(*) AS tofu_conversions,
        COUNT(DISTINCT p.user_id) AS tofu_converters,
        SUM(p.revenue) AS tofu_revenue
    FROM gold.fact_purchases p
    WHERE p.acquisition_channel IS NOT NULL
    GROUP BY DATEFROMPARTS(YEAR(p.purchase_date), MONTH(p.purchase_date), 1), p.acquisition_channel
),
spend AS (
    SELECT
        DATEFROMPARTS(YEAR(s.spend_date), MONTH(s.spend_date), 1) AS performance_month,
        s.channel,
        SUM(s.spend) AS total_spend
    FROM gold.fact_spend s
    WHERE s.channel IS NOT NULL
    GROUP BY DATEFROMPARTS(YEAR(s.spend_date), MONTH(s.spend_date), 1), s.channel
),
acquisitions AS (
    -- Users acquired per channel per month (for CAC)
    SELECT
        DATEFROMPARTS(YEAR(a.acquisition_date), MONTH(a.acquisition_date), 1) AS acquisition_month,
        a.acquisition_channel AS channel,
        COUNT(DISTINCT a.user_id) AS users_acquired
    FROM gold.fact_user_acquisition a
    GROUP BY DATEFROMPARTS(YEAR(a.acquisition_date), MONTH(a.acquisition_date), 1), a.acquisition_channel
),
ltv_latest AS (
    -- Latest cumulative LTV per acquisition channel × acquisition month
    -- Uses MAX(month_number) to get the most mature LTV reading per cohort
    SELECT
        l.acquisition_month,
        l.acquisition_channel AS channel,
        MAX(l.cumulative_ltv) AS cumulative_ltv,
        MAX(l.ltv_cac_ratio) AS ltv_cac_ratio
    FROM gold.fact_ltv_cohort_channel l
    WHERE l.month_number = (
        SELECT MAX(l2.month_number)
        FROM gold.fact_ltv_cohort_channel l2
        WHERE l2.acquisition_month = l.acquisition_month
          AND l2.acquisition_channel = l.acquisition_channel
    )
    GROUP BY l.acquisition_month, l.acquisition_channel
)

SELECT
    COALESCE(e.performance_month, c.performance_month, b.performance_month, 
             t.performance_month, s.performance_month) AS performance_month,
    COALESCE(e.channel, c.channel, b.channel, t.channel, s.channel) AS channel,

    -- Engagement
    e.impressions,
    c.total_clicks,
    ROUND(c.total_clicks * 1.0 / NULLIF(e.impressions, 0), 4) AS click_intensity,

    -- BOFU (last-touch)
    b.bofu_conversions,
    b.bofu_revenue,
    ROUND(b.bofu_conversions * 1.0 / NULLIF(c.total_clicks, 0), 4) AS bofu_cvr,

    -- TOFU (first-touch acquisition)
    t.tofu_conversions,
    t.tofu_revenue,

    -- Spend & Efficiency
    s.total_spend,
    ROUND(b.bofu_revenue / NULLIF(s.total_spend, 0), 2) AS bofu_roas,
    ROUND(t.tofu_revenue / NULLIF(s.total_spend, 0), 2) AS tofu_roas,

    -- Acquisition
    a.users_acquired,
    ROUND(s.total_spend * 1.0 / NULLIF(a.users_acquired, 0), 2) AS cac,

    -- LTV (latest cumulative per cohort)
    ltv.cumulative_ltv,
    ltv.ltv_cac_ratio

FROM engagement e
FULL OUTER JOIN clicks c
    ON e.performance_month = c.performance_month AND e.channel = c.channel
FULL OUTER JOIN bofu_conversions b
    ON COALESCE(e.performance_month, c.performance_month) = b.performance_month
    AND COALESCE(e.channel, c.channel) = b.channel
FULL OUTER JOIN tofu_conversions t
    ON COALESCE(e.performance_month, c.performance_month) = t.performance_month
    AND COALESCE(e.channel, c.channel) = t.channel
FULL OUTER JOIN spend s
    ON COALESCE(e.performance_month, c.performance_month) = s.performance_month
    AND COALESCE(e.channel, c.channel) = s.channel
LEFT JOIN acquisitions a
    ON COALESCE(e.performance_month, c.performance_month) = a.acquisition_month
    AND COALESCE(e.channel, c.channel) = a.channel
LEFT JOIN ltv_latest ltv
    ON COALESCE(e.performance_month, c.performance_month) = ltv.acquisition_month
    AND COALESCE(e.channel, c.channel) = ltv.channel;
GO

SELECT *
FROM gold.channel_scorecard
ORDER BY channel, performance_month;
GO


/*
===============================================================================
2) Engagement vs. Conversion
===============================================================================
Which channels generate attention but don't close?
High click_intensity + low BOFU CVR = attention without conversion.
*/
SELECT
    channel,
    AVG(click_intensity) AS avg_click_intensity,
    AVG(bofu_cvr) AS avg_bofu_cvr,
    CASE
        WHEN AVG(click_intensity) > 0.5 AND AVG(bofu_cvr) < 0.10 THEN 'High Engagement, Low Conversion'
        WHEN AVG(click_intensity) > 0.5 AND AVG(bofu_cvr) >= 0.10 THEN 'High Engagement, High Conversion'
        WHEN AVG(click_intensity) <= 0.5 AND AVG(bofu_cvr) >= 0.10 THEN 'Low Engagement, High Conversion'
        ELSE 'Low Engagement, Low Conversion'
    END AS engagement_conversion_profile
FROM gold.channel_scorecard
WHERE click_intensity IS NOT NULL AND bofu_cvr IS NOT NULL
GROUP BY channel;
GO


/*
===============================================================================
3) Acquisition Efficiency
===============================================================================
Which channels acquire cheap users vs. valuable users?
Low CAC + high LTV = most efficient acquisition channel.
*/
SELECT
    channel,
    AVG(cac) AS avg_cac,
    AVG(cumulative_ltv) AS avg_ltv_120d,
    AVG(ltv_cac_ratio) AS avg_ltv_cac_ratio,
    CASE
        WHEN AVG(ltv_cac_ratio) >= 5 THEN 'Highly Efficient'
        WHEN AVG(ltv_cac_ratio) >= 3 THEN 'Efficient'
        WHEN AVG(ltv_cac_ratio) >= 1 THEN 'Approaching Break-Even'
        WHEN AVG(ltv_cac_ratio) IS NOT NULL THEN 'Unprofitable'
        ELSE 'Organic (No CAC)'
    END AS acquisition_efficiency
FROM gold.channel_scorecard
GROUP BY channel;
GO


/*
===============================================================================
4) BOFU Scale vs. Efficiency
===============================================================================
Which channels close well AND can scale?
High BOFU CVR + high conversion volume = efficient AND scalable.
*/
SELECT
    channel,
    AVG(bofu_cvr) AS avg_bofu_cvr,
    SUM(bofu_conversions) AS total_bofu_conversions,
    SUM(bofu_revenue) AS total_bofu_revenue,
    CASE
        WHEN AVG(bofu_cvr) >= 0.10 AND SUM(bofu_conversions) >= 200 THEN 'Efficient & Scalable'
        WHEN AVG(bofu_cvr) >= 0.10 AND SUM(bofu_conversions) < 200 THEN 'Efficient, Limited Scale'
        WHEN AVG(bofu_cvr) < 0.10 AND SUM(bofu_conversions) >= 200 THEN 'Scalable, Low Efficiency'
        ELSE 'Low Efficiency & Scale'
    END AS scale_efficiency_profile
FROM gold.channel_scorecard
WHERE bofu_cvr IS NOT NULL
GROUP BY channel;
GO
