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
<h4>2.1)Architecture</h4>
<p>The warehouse follows a three-layer medallion architecture:</p>
<img width="1009" height="647" alt="Bildschirmfoto 2026-02-13 um 12 17 03" src="https://github.com/user-attachments/assets/bf7bdb92-56c5-4dd5-a72a-375d4bc0d7de" />
**Bronze Layer** — Raw ingestion from CSV source files via `BULK INSERT`. All columns are stored as `NVARCHAR` to preserve the original data as-is. No transformations are applied. Load method: truncate and full reload.

**Silver Layer** — Cleaned, standardized, and type-cast data. Transformations include data cleansing (e.g., fixing misspelled channel names like `"gogle search"` → `"Google Search"`), date format normalization (DD.MM.YYYY → ISO), invalid value handling (out-of-range IDs, `"not_available"` placeholders), and derived columns. Each silver table includes a `dwh_create_date` audit column.

**Gold Layer** — Business-ready tables following a star schema with dimension tables (`dim_date`, `dim_user`, `dim_campaign`, `dim_channel`) and granular atomic fact tables. The Gold layer applies data integration (joining across source systems), enrichment (e.g., adding acquisition channel to click and session facts), and business logic (attribution modeling, touchpoint path construction).




<h4>2.1) 📂 Repository Structure</h4>
