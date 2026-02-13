# Marketing-Analytics-DWH
<h3>End-to-end Data Warehouse (Bronze/Silver/Gold) with Multi-Touch Attribution and Tableau Dashboards</h3>

 👉 Click the images to explore the interactive dashboards on **Tableau Public**.
<p align="center">
   <a href="https://public.tableau.com/views/Multi-TouchMarketingDashboard/Overall?:language=de-DE&:sid=&:redirect=auth&:display_count=n&:origin=viz_share_link">
    <img src="https://github.com/user-attachments/assets/374a6cf6-2f55-4d5a-a97c-fd4636b1c662" width="30%" alt="Budget Allocation Dashboard"/>
  </a>
  <a href="https://public.tableau.com/views/Multi-TouchMarketingDashboard/Overall2?:language=de-DE&:sid=&:redirect=auth&:display_count=n&:origin=viz_share_link">
    <img src="https://github.com/user-attachments/assets/da7e4af0-ce2a-44c6-8f08-ae042cbd7ad4" width="30%" alt="LTV Cohort Dashboard"/>
  </a>
  <a href="https://public.tableau.com/views/Multi-TouchMarketingDashboard/Overall3?:language=de-DE&:sid=&:redirect=auth&:display_count=n&:origin=viz_share_link">
    <img src="https://github.com/user-attachments/assets/67e6bea1-75c6-4f61-8891-8810d2bf830f" width="30%" alt="Customer Journey Dashboard"/>
  </a>
</p>

<p>📍 About: This demo project is intended to <strong>showcase skills</strong> and uses <strong>synthetically generated data</strong>.</p>

<h2>1) Marketing Analysis</h2>
<h4>1.1) Project Brief</h4>
<p>Tasked with analyzing ad data from January to April 2024, I will start by addressing stakeholder communication and presenting the analysis results. In Section 2, I will then cover the data overview, the ETL pipeline, and the data warehouse build process.</p>

<h2>2) End-To-End Data Warehouse and ETL</h2>
<p>A SQL Server data warehouse for marketing analytics, built on a Bronze → Silver → Gold medallion architecture. The warehouse, named <strong>marketing_dw</strong>, integrates data from three source systems (marketing platform, web analytics, crm systems) and models it into a star schema with a fact constellation for multi-touch attribution.</p>
<h4>2.1) Architecture</h4>
<p>The warehouse follows a three-layer medallion architecture:</p>
<img width="1009" height="647" alt="High Level Architecture" src="https://github.com/user-attachments/assets/bf7bdb92-56c5-4dd5-a72a-375d4bc0d7de" />

<p><b>Bronze Layer</b> — Raw ingestion from CSV source files via <code>BULK INSERT</code>. All columns are stored as <code>NVARCHAR</code> to preserve the original data as-is. No transformations are applied. Load method: truncate and full reload.</p>

<p><b>Silver Layer</b> — Cleaned, standardized, and type-cast data. Transformations include data cleansing (e.g., fixing misspelled channel names like <code>"gogle search"</code> → <code>"Google Search"</code>), date format normalization (DD.MM.YYYY → ISO), invalid value handling (out-of-range IDs, <code>"not_available"</code> placeholders), and derived columns. Each silver table includes a <code>dwh_create_date</code> audit column.</p>

<p><b>Gold Layer</b> — Business-ready tables following a star schema with dimension tables (<code>dim_date</code>, <code>dim_user</code>, <code>dim_campaign</code>, <code>dim_channel</code>) and granular atomic fact tables. The Gold layer applies data integration (joining across source systems), enrichment (e.g., adding acquisition channel to click and session facts), and business logic (attribution modeling, touchpoint path construction).</p>

<hr>

<h4>2.2) Data Sources</h4>

<table>
  <thead>
    <tr>
      <th>Source System</th>
      <th>Schema Prefix</th>
      <th>Description</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>Marketing Platform (<code>MRKT</code>)</td>
      <td><code>mrkt_</code></td>
      <td>Ad spend, campaign metadata, click events from paid channels</td>
    </tr>
    <tr>
      <td>Web Analytics (<code>WEB</code>)</td>
      <td><code>web_</code></td>
      <td>Session data, touchpoint events (views, impressions, clicks)</td>
    </tr>
    <tr>
      <td>CRM System (<code>CRM</code>)</td>
      <td><code>crm_</code></td>
      <td>Purchases, user acquisition records, channel reference data</td>
    </tr>
  </tbody>
</table>

<hr>

<h4>2.3) Table Inventory</h4>

<p>The warehouse contains 8 Bronze tables (raw ingestion), 8 Silver tables (cleaned and standardized), 4 Gold dimension tables, and 9 Gold fact tables. The table below summarizes all layers. For detailed column-level documentation of the Gold layer (data types, descriptions, grain), see the <a href="https://github.com/johanna-oncken/Marketing-Analytics-DWH/blob/main/data_warehouse/docs/data_catalog.md?plain=1">Data Catalog</a>.</p>

<table>
  <thead>
    <tr>
      <th>Layer</th>
      <th>Table</th>
      <th>Granularity</th>
      <th>Key Transformations / Description</th>
    </tr>
  </thead>
  <tbody>
    <tr><td rowspan="8"><b>Bronze</b></td><td><code>mrkt_raw_ad_spend</code></td><td>Channel × Day</td><td>Raw CSV ingestion, all NVARCHAR</td></tr>
    <tr><td><code>mrkt_raw_campaigns</code></td><td>Campaign</td><td>Raw CSV ingestion, all NVARCHAR</td></tr>
    <tr><td><code>mrkt_raw_clicks</code></td><td>Click event</td><td>Raw CSV ingestion, all NVARCHAR</td></tr>
    <tr><td><code>web_raw_sessions</code></td><td>Session</td><td>Raw CSV ingestion, all NVARCHAR</td></tr>
    <tr><td><code>web_raw_touchpoints</code></td><td>Touchpoint event</td><td>Raw CSV ingestion, all NVARCHAR</td></tr>
    <tr><td><code>crm_raw_channels</code></td><td>Channel</td><td>Raw CSV ingestion, all NVARCHAR</td></tr>
    <tr><td><code>crm_raw_purchases</code></td><td>Purchase</td><td>Raw CSV ingestion, all NVARCHAR</td></tr>
    <tr><td><code>crm_raw_user_acquisitions</code></td><td>User</td><td>Raw CSV ingestion, all NVARCHAR</td></tr>
    <tr><td rowspan="8"><b>Silver</b></td><td><code>mrkt_ad_spend</code></td><td>Channel × Day</td><td>Date parsing, channel standardization, spend cleaning</td></tr>
    <tr><td><code>mrkt_campaigns</code></td><td>Campaign</td><td>Campaign name corrections, objective normalization</td></tr>
    <tr><td><code>mrkt_clicks</code></td><td>Click event</td><td>Timestamp unification, channel standardization</td></tr>
    <tr><td><code>web_sessions</code></td><td>Session</td><td>Type casting, channel standardization</td></tr>
    <tr><td><code>web_touchpoints</code></td><td>Touchpoint event</td><td>Interaction type normalization, channel standardization</td></tr>
    <tr><td><code>crm_channels</code></td><td>Channel</td><td>Trim and validate</td></tr>
    <tr><td><code>crm_purchases</code></td><td>Purchase</td><td>Revenue type casting, last-touch channel cleaning</td></tr>
    <tr><td><code>crm_user_acquisitions</code></td><td>User</td><td>Date parsing, channel standardization</td></tr>
    <tr><td rowspan="4"><b>Gold Dim</b></td><td><code>dim_date</code></td><td>Calendar date</td><td>Generated via recursive CTE (2023–2024)</td></tr>
    <tr><td><code>dim_user</code></td><td>User</td><td>Union of all user IDs across silver tables</td></tr>
    <tr><td><code>dim_campaign</code></td><td>Campaign</td><td>53 campaigns across 5 paid channels</td></tr>
    <tr><td><code>dim_channel</code></td><td>Channel</td><td>9 channels in 2 categories (Paid, Organic)</td></tr>
    <tr><td rowspan="9"><b>Gold Fact</b></td><td><code>fact_spend</code></td><td>Campaign × Day</td><td>Ad spend enriched with campaign metadata</td></tr>
    <tr><td><code>fact_clicks</code></td><td>Click event</td><td>Clicks enriched with acquisition channel (first-touch)</td></tr>
    <tr><td><code>fact_sessions</code></td><td>Session</td><td>Sessions enriched with acquisition channel</td></tr>
    <tr><td><code>fact_touchpoints</code></td><td>Touchpoint event</td><td>All touchpoint interactions enriched with campaign name</td></tr>
    <tr><td><code>fact_purchases</code></td><td>Purchase</td><td>Purchases enriched with acquisition data</td></tr>
    <tr><td><code>fact_touchpath</code></td><td>Touchpoint × Purchase</td><td>Ordered touchpoint sequences per converting journey</td></tr>
    <tr><td><code>fact_attribution_linear</code></td><td>Touchpoint × Purchase</td><td>Linear (equal-weight) revenue attribution</td></tr>
    <tr><td><code>fact_attribution_last_touch</code></td><td>Purchase</td><td>Last-touch attribution (100% to final touchpoint)</td></tr>
    <tr><td><code>fact_attribution_linear_with_costs</code></td><td>Touchpoint × Purchase</td><td>Linear attribution with proportional cost allocation (paid only)</td></tr>
  </tbody>
</table>

<hr>

<h4>2.5) Data Model</h4>

<p>The Gold layer follows a <b>star schema</b> for core marketing analytics (spend, clicks, sessions, touchpoints, purchases), combined with a <b>fact constellation</b> for attribution modeling.</p>

<p>The core fact tables (<code>fact_spend</code>, <code>fact_clicks</code>, <code>fact_sessions</code>, <code>fact_touchpoints</code>, <code>fact_purchases</code>) each relate to the shared dimensions <code>dim_date</code>, <code>dim_user</code>, <code>dim_channel</code>, and <code>dim_campaign</code> through natural keys rather than surrogate foreign keys. This design choice optimizes for BI tool compatibility (Tableau, Power BI) and query simplicity. A classic Kimball star schema with surrogate key FKs could be implemented by adding <code>user_key</code>, <code>channel_key</code>, and <code>campaign_key</code> columns to the fact tables.</p>

<p>The analytical fact tables (<code>fact_touchpath</code>, <code>fact_attribution_linear</code>, <code>fact_attribution_last_touch</code>, <code>fact_attribution_linear_with_costs</code>) form a fact constellation that references <code>fact_purchases</code> through the natural key <code>purchase_id</code> to enable multi-touch attribution analysis.</p>

<img width="847" height="696" alt="Data model" src="https://github.com/user-attachments/assets/4e1d7917-fc2a-42d9-9bea-ab54effc50f1" />

<hr>

<h4>2.6) Why <code>fact_attribution_linear_with_costs</code> Exists</h4>

<h5>2.6.1) The Problem</h5>

<p>The original <code>fact_attribution_linear</code> table distributes <b>revenue</b> equally across all touchpoints in a converting user journey. This enables questions like "How much revenue does each channel contribute?" However, it cannot answer efficiency questions like "What is the true ROI per channel?" — because <b>costs remain at the campaign/day level</b> in <code>fact_spend</code>, while revenue is distributed at the touchpoint level in the attribution table.</p>

<p>Joining these two tables directly would produce distorted ROAS and ROI values, since the granularity mismatch causes costs to be either duplicated or lost depending on the join logic.</p>

<p>This is a common structural problem in marketing attribution: revenue attribution is well-established, but cost attribution is often left as an afterthought, forcing analysts to compare touchpoint-level revenue against aggregate-level spend in separate queries — which breaks down when trying to evaluate channel or campaign efficiency at the touchpoint level.</p>

<h5>2.6.1) The Solution</h5>

<p><code>fact_attribution_linear_with_costs</code> solves this by applying <b>proportional cost allocation</b> alongside revenue attribution. For each touchpoint in a converting journey, the table includes both a <code>revenue_share</code> (from the original linear model) and a <code>cost_share</code> calculated as:</p>

<pre><code>cost_share = daily_campaign_spend / touchpoints_for_that_campaign_on_that_day</code></pre>

<p>This means if Campaign 5 spent €100 on January 15 and had 20 attributed touchpoints that day, each touchpoint receives a <code>cost_share</code> of €5. Revenue and cost are now at the same granularity, enabling accurate per-touchpoint ROI and ROAS calculations.</p>

<h4>2.6.2) Scope</h4>

<p>The cost-enhanced table is restricted to <b>paid marketing channels only</b> (Facebook Ads, Google Display, Google Search, Instagram Ads, TikTok Ads). Organic channels (Direct, Email, Organic Search, Referral) are excluded because they carry no media cost — including them would distort efficiency metrics. For full customer journey analysis including organic channels, the original <code>fact_attribution_linear</code> table remains available.</p>

<h4>2.6.3) Usage</h4>

<pre><code>-- Channel-level ROI with attributed costs
SELECT
    channel,
    SUM(revenue_share)  AS attributed_revenue,
    SUM(cost_share)     AS attributed_costs,
    SUM(revenue_share) / NULLIF(SUM(cost_share), 0) AS roas,
    (SUM(revenue_share) - SUM(cost_share)) / NULLIF(SUM(cost_share), 0) AS roi
FROM gold.fact_attribution_linear_with_costs
GROUP BY channel;</code></pre>

<hr>

<h4>2.7) Data Quality</h4>

<p>Quality assurance is applied at every layer:</p>

<p><b>Bronze → Silver (Profiling &amp; Cleaning):</b> Each source table has a dedicated profiling script (<code>profile_clean_*.sql</code>) that documents row counts, duplicate checks, column-level quality assessments with categorized status flags (<code>Valid</code>, <code>Missing</code>, <code>Invalid</code>, <code>Out of range</code>), and cleaned column previews. Findings from profiling directly inform the transformation logic in <code>proc_load_silver</code>.</p>

<p><b>Silver (Post-Load Checks):</b> <code>quality_checks_silver.sql</code> validates the silver tables after loading — checking for NULLs in critical columns, consistent channel names, reasonable value ranges, and cross-table consistency (e.g., verifying that negative revenue values correspond to matching positive returns).</p>

<p><b>Gold — Dimensions:</b> <code>quality_checks_dim.sql</code> validates surrogate key uniqueness, natural key uniqueness, and row count consistency with silver source tables.</p>

<p><b>Gold — Fact Tables:</b> <code>quality_checks_fact.sql</code> and <code>quality_checks_fact_multi_touch.sql</code> validate surrogate key uniqueness, referential integrity against all related dimensions and fact tables, date/timestamp consistency with <code>dim_date</code>, NOT NULL constraints, revenue share accuracy (sum of shares equals total revenue per purchase within rounding tolerance), and row count comparisons with silver source tables.</p>

<p><b>Gold — Attribution with Costs:</b> The DDL script for <code>fact_attribution_linear_with_costs</code> includes inline quality checks for row count comparison against the original table, cost attribution coverage percentage, total revenue vs. total cost plausibility, and cost attribution breakdown by channel.</p>

<hr>

<h4>2.8) Execution Order</h4>

<table>
  <thead>
    <tr>
      <th>#</th>
      <th>Script</th>
      <th>Purpose</th>
    </tr>
  </thead>
  <tbody>
    <tr><td>1</td><td><code>init_database.sql</code></td><td>Create database and schemas (bronze, silver, gold)</td></tr>
    <tr><td>2</td><td><code>ddl_bronze.sql</code></td><td>Create bronze tables</td></tr>
    <tr><td>3</td><td><code>proc_load_bronze.sql</code></td><td>Create and run <code>EXEC bronze.load_bronze</code></td></tr>
    <tr><td>4</td><td><code>profile_clean_mrkt_*.sql</code></td><td>Data profiling (informational, not required for load)</td></tr>
    <tr><td>5</td><td><code>ddl_silver.sql</code></td><td>Create silver tables</td></tr>
    <tr><td>6</td><td><code>proc_load_silver.sql</code></td><td>Create and run <code>EXEC silver.load_silver</code></td></tr>
    <tr><td>7</td><td><code>quality_checks_silver.sql</code></td><td>Validate silver layer</td></tr>
    <tr><td>8</td><td><code>ddl_gold_dim.sql</code></td><td>Create and populate dimension tables</td></tr>
    <tr><td>9</td><td><code>quality_checks_dim.sql</code></td><td>Validate dimensions</td></tr>
    <tr><td>10</td><td><code>ddl_gold_fact.sql</code></td><td>Create and populate core fact tables</td></tr>
    <tr><td>11</td><td><code>quality_checks_fact.sql</code></td><td>Validate core facts</td></tr>
    <tr><td>12</td><td><code>ddl_gold_fact_multi_touch.sql</code></td><td>Create touchpath + attribution tables</td></tr>
    <tr><td>13</td><td><code>quality_checks_fact_multi_touch.sql</code></td><td>Validate attribution tables</td></tr>
    <tr><td>14</td><td><code>ddl_gold_fact_attribution_with_costs.sql</code></td><td>Create cost-enhanced attribution</td></tr>
  </tbody>
</table>

<hr>

<h4>2.9) Technical Environment</h4>

<table>
  <thead>
    <tr>
      <th>Attribute</th>
      <th>Value</th>
    </tr>
  </thead>
  <tbody>
    <tr><td>Database</td><td>SQL Server (T-SQL)</td></tr>
    <tr><td>Load Pattern</td><td>Full load, truncate and insert (no incremental/CDC)</td></tr>
    <tr><td>Data Period</td><td>January – April 2024 (campaign and transaction data), calendar dimension covering 2023–2024</td></tr>
    <tr><td>Scale</td><td>~8,500 users · ~3,500 purchases · ~87,000 touchpoints · ~70,000 clicks · 53 campaigns · 9 channels</td></tr>
  </tbody>
</table>





<h4>2.1) 📂 Repository Structure</h4>
