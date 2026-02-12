/*
===============================================================================
Cumulative Analysis
===============================================================================
Purpose:
    - To calculate running totals or moving averages for key metrics.
    - To track performance over time cumulatively.
    - Useful for growth analysis or identifying long-term trends.

Known Data Limitations:

    Ad Spend Distribution:
    The synthetic ad spend data is concentrated on high-revenue days 
    to achieve realistic ROAS metrics. This results in declining 
    monthly spend (Jan: €41.5K → Apr: €1.1K), which would not occur 
    in production marketing operations where budgets are typically 
    allocated evenly or increased over time.

    Impact:
    - ROAS calculations remain valid (spend matches revenue-generating days)
    - Monthly spend trend analysis should not be interpreted as realistic
    - In production: expect €15-20K/month steady-state spending

    Trade-off Decision:
    Realistic ROAS values (2.12) were prioritized over uniform 
    spend distribution, as ROAS accuracy is the primary analytical 
    objective of this attribution model.

SQL Functions Used:
    - Window Functions: SUM() OVER(), AVG() OVER()

Queries: 
    1) Total Revenue and Running Total per Month
    2) Total Spend and Running Total per Month

===============================================================================
*/
USE marketing_dw; 
GO   

-- 1) Calculate the total revenue per month 
--    and the running total over time
SELECT 
    year_month,
    total_revenue,
    SUM(total_revenue) OVER(ORDER BY rn) AS running_total_revenue,
    AVG(avg_price) OVER(ORDER BY rn) AS moving_average_price 
FROM (
    SELECT 
        CONCAT(d.year, ' - ', d.month_name) AS year_month,
        SUM(f.revenue) AS total_revenue,
        AVG(f.revenue) AS avg_price,
        ROW_NUMBER() OVER(ORDER BY d.year, d.month) AS rn
    FROM gold.fact_purchases f 
    LEFT JOIN gold.dim_date d 
    ON f.date_key = d.date_key 
    GROUP BY d.year, d.month, CONCAT(d.year, ' - ', d.month_name))t
ORDER BY rn;

-- 2) Calculate the total spend per month 
--    and the running total over time
SELECT 
    year_month,
    total_spend,
    SUM(total_spend) OVER(ORDER BY rn) AS running_total_spend,
    AVG(avg_ad_spend) OVER(ORDER BY rn) AS moving_average_ad_spend
FROM (
    SELECT 
        CONCAT(d.year, ' - ', d.month_name) AS year_month,
        SUM(f.spend) AS total_spend,
        AVG(f.spend) AS avg_ad_spend,
        ROW_NUMBER() OVER(ORDER BY d.year, d.month) AS rn 
    FROM gold.fact_spend f 
    LEFT JOIN gold.dim_date d 
    ON f.date_key = d.date_key 
    GROUP BY d.year, d.month, CONCAT(d.year, ' - ', d.month_name))t
ORDER BY rn;