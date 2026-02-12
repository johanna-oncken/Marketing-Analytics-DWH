/*
===============================================================================
Short Term LTV Performance Analysis (Cohort by Acquisition Month)
===============================================================================
Purpose:
    - To measure the 120-day-LTV performance overall and of marketing components 
      such as campaigns and channels over time.
    - For benchmarking and identifying high-performing entities.
    - To track monthly 2024 trends and growth.

Limitations:
    - Full LTV calculation is not possible because the datasets only span 4 months (Jan-Apr 2024).
    - Therefore 120-day-LTV is determined.
    - Some acquisition-month cohorts show unusually high LTV:CAC ratios because CAC 
      is extremely low due to limited or missing spend recorded for the acquisition 
      campaign in that month (synthetic data spend collapse after January).

Key Design Decisions:
    - cohort_size is the FIXED number of users acquired in that month (from fact_user_acquisition),
      NOT the number of active purchasers per month. This ensures the denominator stays constant 
      across months, as expected in standard cohort analysis.
    - active_users counts how many cohort members actually purchased in a given month.
    - purchase_rate_pct = active_users / cohort_size shows what percentage of the cohort 
      purchased in a given month. This is NOT classic subscription retention — users who 
      don't purchase in one month may purchase in a later month.
    - monthly_ltv = that month's revenue / cohort_size (per-month contribution).
    - cumulative_ltv = running total of revenue / cohort_size (standard LTV metric).
    - LTV:CAC ratio and ROI are based on cumulative_ltv.
    - CAC uses only spend from acquisition campaigns (not all campaign spend) to avoid 
      inflating CAC with retargeting or mid-funnel spend.
    - Organic channels (Direct, Email, Organic Search, Referral) show NULL for CAC, 
      LTV:CAC, and ROI because they have no ad spend in fact_spend.
    - Overall ROI is included in this script rather than as a separate analysis because 
      ROI = ROAS - 1 (mathematically equivalent). Channel/campaign ROI breakdowns would 
      duplicate the ROAS performance script; the overall ROI metric belongs here as part 
      of the profitability overview alongside LTV and LTV:CAC.

SQL Functions Used:
    - SUM() OVER(): Cumulative window function for LTV.
    - ROW_NUMBER() OVER(): First-touch attribution in user acquisition view.
    - LEFT JOIN, COUNT(), SUM(), ROUND(), NULLIF(), DATEDIFF()

Queries: 
    1) User Acquisition View (first-touch attribution)
    2) Overall Profitability: LTV, CAC, LTV:CAC Ratio, ROI (120 days)
    3) Cohort Analysis by Acquisition Month with LTV, LTV:CAC Ratio and ROI
    4) Cohort Analysis by Acquisition Channel with LTV, LTV:CAC Ratio and ROI
    5) Cohort Analysis by Acquisition Campaign with LTV, LTV:CAC Ratio and ROI
===============================================================================
*/
USE marketing_dw; 
GO


/*
===============================================================================
1) User Acquisition View
===============================================================================
First-touch attribution: each user is assigned to exactly one acquisition 
cohort based on their earliest recorded touchpoint.
This view is used by all subsequent queries and by the CAC performance script.
*/
DROP VIEW IF EXISTS gold.fact_user_acquisition;
GO

CREATE VIEW gold.fact_user_acquisition AS
WITH first_touch AS (
    SELECT
        user_id,
        touchpoint_time,
        channel AS acquisition_channel,
        campaign_id AS acquisition_campaign,
        ROW_NUMBER() OVER (
            PARTITION BY user_id 
            ORDER BY touchpoint_time ASC
        ) AS rn
    FROM gold.fact_touchpoints
)
SELECT
    user_id,
    touchpoint_time AS acquisition_date,
    acquisition_channel,
    acquisition_campaign
FROM first_touch
WHERE rn = 1;
GO


/*
===============================================================================
2) Overall Profitability: LTV, CAC, LTV:CAC Ratio, ROI (120 days)
===============================================================================
All key profitability metrics in one view.
- LTV uses all users from dim_user (including non-purchasers) for a conservative estimate.
- CAC uses total ad spend / acquired users (users with tracked touchpoints).
- ROI = (Revenue - Spend) / Spend — overall profitability of marketing investment.
- Note: The overall LTV:CAC is dominated by the January cohort (93% of users).
  Cohort-level analysis (Queries 3-5) reveals that later cohorts have not yet reached 
  break-even, so this aggregate should not be used as the sole profitability indicator.
*/
SELECT 
    SUM(p.revenue) AS total_revenue,
    s.total_spend,
    u.total_users,
    a.acquired_users,
    -- LTV: Revenue per user (all users, conservative)
    ROUND(SUM(p.revenue) / u.total_users, 2) AS ltv_120_days,
    -- CAC: Spend per acquired user
    ROUND(s.total_spend * 1.0 / a.acquired_users, 2) AS cac,
    -- LTV:CAC Ratio
    ROUND((SUM(p.revenue) / u.total_users) / (s.total_spend * 1.0 / a.acquired_users), 2) AS ltv_cac_ratio,
    -- ROI: Overall profitability
    ROUND((SUM(p.revenue) - s.total_spend) / s.total_spend, 2) AS roi_120_days
FROM gold.fact_purchases p
CROSS JOIN (SELECT COUNT(*) AS total_users FROM gold.dim_user) u
CROSS JOIN (SELECT SUM(spend) AS total_spend FROM gold.fact_spend) s
CROSS JOIN (SELECT COUNT(DISTINCT user_id) AS acquired_users FROM gold.fact_user_acquisition) a
GROUP BY u.total_users, s.total_spend, a.acquired_users;
GO


/*
===============================================================================
3) Cohort Analysis by Acquisition Month with LTV, LTV:CAC Ratio and ROI
===============================================================================
- cohort_size = total users acquired in that month (fixed denominator).
- active_users = users from the cohort who purchased in a given month.
- LTV is cumulative: total revenue from acquisition month through current month / cohort_size.
- CAC uses only spend from acquisition campaigns.
*/
DROP VIEW IF EXISTS gold.fact_ltv_cohort;
GO 

CREATE VIEW gold.fact_ltv_cohort AS
WITH revenue AS (
    SELECT 
        DATEFROMPARTS(YEAR(purchase_date), MONTH(purchase_date), 1) AS purchase_month,
        user_id,
        revenue
    FROM gold.fact_purchases
),
acquisitions AS (
    SELECT 
        DATEFROMPARTS(YEAR(acquisition_date), MONTH(acquisition_date), 1) AS acquisition_month,
        user_id
    FROM gold.fact_user_acquisition
),
acquisition_count AS (
    SELECT
        DATEFROMPARTS(YEAR(acquisition_date), MONTH(acquisition_date), 1) AS acquisition_month,
        COUNT(DISTINCT user_id) AS cohort_size
    FROM gold.fact_user_acquisition
    GROUP BY DATEFROMPARTS(YEAR(acquisition_date), MONTH(acquisition_date), 1)
),
acquisition_spend AS (
    SELECT
        DATEFROMPARTS(YEAR(s.spend_date), MONTH(s.spend_date), 1) AS spend_month,
        SUM(s.spend) AS total_acquisition_spend
    FROM gold.fact_spend s
    WHERE s.campaign_id IN (
        SELECT DISTINCT acquisition_campaign
        FROM gold.fact_user_acquisition
        WHERE acquisition_campaign IS NOT NULL
    )
    GROUP BY DATEFROMPARTS(YEAR(s.spend_date), MONTH(s.spend_date), 1)
),
monthly_metrics AS (
    SELECT
        a.acquisition_month, 
        r.purchase_month,
        DATEDIFF(MONTH, a.acquisition_month, r.purchase_month) AS month_number,
        SUM(r.revenue) AS monthly_revenue,
        COUNT(DISTINCT a.user_id) AS active_users,
        ac.cohort_size
    FROM acquisitions a 
    LEFT JOIN revenue r 
        ON a.user_id = r.user_id 
        AND a.acquisition_month <= r.purchase_month  
    JOIN acquisition_count ac
        ON a.acquisition_month = ac.acquisition_month
    WHERE r.purchase_month IS NOT NULL
    GROUP BY 
        a.acquisition_month, 
        r.purchase_month, 
        DATEDIFF(MONTH, a.acquisition_month, r.purchase_month),
        ac.cohort_size
),
cac AS (
    SELECT
        a.acquisition_month,
        s.total_acquisition_spend * 1.0 / a.cohort_size AS cac
    FROM acquisition_count a
    LEFT JOIN acquisition_spend s
        ON a.acquisition_month = s.spend_month
),
with_cumulative AS (
    SELECT
        m.acquisition_month,
        m.purchase_month,
        m.month_number,
        m.monthly_revenue,
        m.cohort_size,
        m.active_users,
        SUM(m.monthly_revenue) OVER (
            PARTITION BY m.acquisition_month 
            ORDER BY m.purchase_month
        ) AS cumulative_revenue,
        c.cac
    FROM monthly_metrics m
    LEFT JOIN cac c 
        ON m.acquisition_month = c.acquisition_month
)

SELECT
    acquisition_month,
    purchase_month,
    month_number,
    monthly_revenue,
    cohort_size,
    active_users,
    ROUND(active_users * 100.0 / NULLIF(cohort_size, 0), 2) AS purchase_rate_pct,
    ROUND(monthly_revenue * 1.0 / NULLIF(cohort_size, 0), 2) AS monthly_ltv,
    ROUND(cumulative_revenue * 1.0 / NULLIF(cohort_size, 0), 2) AS cumulative_ltv,
    cac,
    ROUND(cumulative_revenue * 1.0 / NULLIF(cohort_size, 0) / NULLIF(cac, 0), 2) AS ltv_cac_ratio,
    ROUND((cumulative_revenue * 1.0 / NULLIF(cohort_size, 0) - cac) / NULLIF(cac, 0), 2) AS roi
FROM with_cumulative;
GO

SELECT * 
FROM gold.fact_ltv_cohort 
ORDER BY acquisition_month, month_number;
GO


/*
===============================================================================
4) Cohort Analysis by Acquisition Channel with LTV, LTV:CAC Ratio and ROI
===============================================================================
Same methodology as Query 3, broken down by acquisition channel.
Organic channels show NULL for CAC/LTV:CAC/ROI (no ad spend).
*/
DROP VIEW IF EXISTS gold.fact_ltv_cohort_channel;
GO 

CREATE VIEW gold.fact_ltv_cohort_channel AS
WITH revenue AS (
    SELECT 
        DATEFROMPARTS(YEAR(purchase_date), MONTH(purchase_date), 1) AS purchase_month,
        user_id,
        revenue
    FROM gold.fact_purchases
),
acquisitions AS (
    SELECT 
        DATEFROMPARTS(YEAR(acquisition_date), MONTH(acquisition_date), 1) AS acquisition_month,
        user_id,
        acquisition_channel
    FROM gold.fact_user_acquisition
),
acquisition_count AS (
    SELECT
        DATEFROMPARTS(YEAR(acquisition_date), MONTH(acquisition_date), 1) AS acquisition_month,
        acquisition_channel,
        COUNT(DISTINCT user_id) AS cohort_size
    FROM gold.fact_user_acquisition
    GROUP BY DATEFROMPARTS(YEAR(acquisition_date), MONTH(acquisition_date), 1), acquisition_channel
),
acquisition_spend AS (
    SELECT
        DATEFROMPARTS(YEAR(s.spend_date), MONTH(s.spend_date), 1) AS spend_month,
        s.channel,
        SUM(s.spend) AS total_acquisition_spend
    FROM gold.fact_spend s
    WHERE s.campaign_id IN (
        SELECT DISTINCT acquisition_campaign
        FROM gold.fact_user_acquisition
        WHERE acquisition_campaign IS NOT NULL
    )
    GROUP BY DATEFROMPARTS(YEAR(s.spend_date), MONTH(s.spend_date), 1), s.channel
),
monthly_metrics AS (
    SELECT
        a.acquisition_month, 
        r.purchase_month,
        DATEDIFF(MONTH, a.acquisition_month, r.purchase_month) AS month_number,
        a.acquisition_channel,
        SUM(r.revenue) AS monthly_revenue,
        COUNT(DISTINCT a.user_id) AS active_users,
        ac.cohort_size
    FROM acquisitions a 
    LEFT JOIN revenue r 
        ON a.user_id = r.user_id
        AND a.acquisition_month <= r.purchase_month  
    JOIN acquisition_count ac
        ON a.acquisition_month = ac.acquisition_month
        AND a.acquisition_channel = ac.acquisition_channel
    WHERE r.purchase_month IS NOT NULL
    GROUP BY 
        a.acquisition_month, 
        r.purchase_month, 
        DATEDIFF(MONTH, a.acquisition_month, r.purchase_month),
        a.acquisition_channel,
        ac.cohort_size
),
cac AS (
    SELECT
        a.acquisition_month,
        a.acquisition_channel,
        s.total_acquisition_spend * 1.0 / a.cohort_size AS cac
    FROM acquisition_count a
    LEFT JOIN acquisition_spend s
        ON a.acquisition_month = s.spend_month
        AND a.acquisition_channel = s.channel
),
with_cumulative AS (
    SELECT
        m.acquisition_month,
        m.purchase_month,
        m.month_number,
        m.acquisition_channel,
        m.monthly_revenue,
        m.cohort_size,
        m.active_users,
        SUM(m.monthly_revenue) OVER (
            PARTITION BY m.acquisition_month, m.acquisition_channel
            ORDER BY m.purchase_month
        ) AS cumulative_revenue,
        c.cac
    FROM monthly_metrics m
    LEFT JOIN cac c 
        ON m.acquisition_month = c.acquisition_month
        AND m.acquisition_channel = c.acquisition_channel
)

SELECT
    acquisition_month,
    purchase_month,
    month_number,
    acquisition_channel,
    monthly_revenue,
    cohort_size,
    active_users,
    ROUND(active_users * 100.0 / NULLIF(cohort_size, 0), 2) AS purchase_rate_pct,
    ROUND(monthly_revenue * 1.0 / NULLIF(cohort_size, 0), 2) AS monthly_ltv,
    ROUND(cumulative_revenue * 1.0 / NULLIF(cohort_size, 0), 2) AS cumulative_ltv,
    cac,
    ROUND(cumulative_revenue * 1.0 / NULLIF(cohort_size, 0) / NULLIF(cac, 0), 2) AS ltv_cac_ratio,
    ROUND((cumulative_revenue * 1.0 / NULLIF(cohort_size, 0) - cac) / NULLIF(cac, 0), 2) AS roi
FROM with_cumulative;
GO 

SELECT * 
FROM gold.fact_ltv_cohort_channel
ORDER BY acquisition_channel, acquisition_month, month_number;
GO


/*
===============================================================================
5) Cohort Analysis by Acquisition Campaign with LTV, LTV:CAC Ratio and ROI
===============================================================================
Same methodology as Query 3, broken down by acquisition campaign.
Campaigns with NULL campaign_id are users acquired through organic touchpoints 
without a tracked campaign.
*/
DROP VIEW IF EXISTS gold.fact_ltv_cohort_campaign;
GO 

CREATE VIEW gold.fact_ltv_cohort_campaign AS
WITH revenue AS (
    SELECT 
        DATEFROMPARTS(YEAR(purchase_date), MONTH(purchase_date), 1) AS purchase_month,
        user_id,
        revenue
    FROM gold.fact_purchases
),
acquisitions AS (
    SELECT 
        DATEFROMPARTS(YEAR(acquisition_date), MONTH(acquisition_date), 1) AS acquisition_month,
        user_id,
        acquisition_campaign
    FROM gold.fact_user_acquisition
),
acquisition_count AS (
    SELECT
        DATEFROMPARTS(YEAR(acquisition_date), MONTH(acquisition_date), 1) AS acquisition_month,
        acquisition_campaign,
        COUNT(DISTINCT user_id) AS cohort_size
    FROM gold.fact_user_acquisition
    GROUP BY DATEFROMPARTS(YEAR(acquisition_date), MONTH(acquisition_date), 1), acquisition_campaign
),
acquisition_spend AS (
    SELECT
        DATEFROMPARTS(YEAR(s.spend_date), MONTH(s.spend_date), 1) AS spend_month,
        s.campaign_id,
        SUM(s.spend) AS total_acquisition_spend
    FROM gold.fact_spend s
    WHERE s.campaign_id IN (
        SELECT DISTINCT acquisition_campaign
        FROM gold.fact_user_acquisition
        WHERE acquisition_campaign IS NOT NULL
    )
    GROUP BY DATEFROMPARTS(YEAR(s.spend_date), MONTH(s.spend_date), 1), s.campaign_id
),
monthly_metrics AS (
    SELECT
        a.acquisition_month, 
        r.purchase_month,
        DATEDIFF(MONTH, a.acquisition_month, r.purchase_month) AS month_number,
        a.acquisition_campaign,
        c.campaign_name,
        SUM(r.revenue) AS monthly_revenue,
        COUNT(DISTINCT a.user_id) AS active_users,
        ac.cohort_size
    FROM acquisitions a 
    LEFT JOIN revenue r 
        ON a.user_id = r.user_id
        AND a.acquisition_month <= r.purchase_month 
    JOIN acquisition_count ac
        ON a.acquisition_month = ac.acquisition_month
        AND (a.acquisition_campaign = ac.acquisition_campaign 
             OR (a.acquisition_campaign IS NULL AND ac.acquisition_campaign IS NULL))
    LEFT JOIN gold.dim_campaign c 
        ON a.acquisition_campaign = c.campaign_id 
    WHERE r.purchase_month IS NOT NULL
    GROUP BY 
        a.acquisition_month, 
        r.purchase_month, 
        DATEDIFF(MONTH, a.acquisition_month, r.purchase_month),
        a.acquisition_campaign,
        c.campaign_name,
        ac.cohort_size
),
cac AS (
    SELECT
        a.acquisition_month,
        a.acquisition_campaign,
        s.total_acquisition_spend * 1.0 / a.cohort_size AS cac
    FROM acquisition_count a
    LEFT JOIN acquisition_spend s
        ON a.acquisition_month = s.spend_month
        AND a.acquisition_campaign = s.campaign_id
),
with_cumulative AS (
    SELECT
        m.acquisition_month,
        m.purchase_month,
        m.month_number,
        m.acquisition_campaign,
        m.campaign_name,
        m.monthly_revenue,
        m.cohort_size,
        m.active_users,
        SUM(m.monthly_revenue) OVER (
            PARTITION BY m.acquisition_month, m.acquisition_campaign
            ORDER BY m.purchase_month
        ) AS cumulative_revenue,
        c.cac
    FROM monthly_metrics m
    LEFT JOIN cac c 
        ON m.acquisition_month = c.acquisition_month
        AND (m.acquisition_campaign = c.acquisition_campaign
             OR (m.acquisition_campaign IS NULL AND c.acquisition_campaign IS NULL))
)

SELECT
    acquisition_month,
    purchase_month,
    month_number,
    acquisition_campaign,
    campaign_name,
    monthly_revenue,
    cohort_size,
    active_users,
    ROUND(active_users * 100.0 / NULLIF(cohort_size, 0), 2) AS purchase_rate_pct,
    ROUND(monthly_revenue * 1.0 / NULLIF(cohort_size, 0), 2) AS monthly_ltv,
    ROUND(cumulative_revenue * 1.0 / NULLIF(cohort_size, 0), 2) AS cumulative_ltv,
    cac,
    ROUND(cumulative_revenue * 1.0 / NULLIF(cohort_size, 0) / NULLIF(cac, 0), 2) AS ltv_cac_ratio,
    ROUND((cumulative_revenue * 1.0 / NULLIF(cohort_size, 0) - cac) / NULLIF(cac, 0), 2) AS roi
FROM with_cumulative;
GO 

SELECT * 
FROM gold.fact_ltv_cohort_campaign
ORDER BY acquisition_campaign, acquisition_month, month_number;
GO
