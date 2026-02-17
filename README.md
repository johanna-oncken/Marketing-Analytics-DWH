# Marketing-Analytics-DWH
<h3>End-to-end Data Warehouse (Bronze/Silver/Gold) with Multi-Touch Attribution and Tableau Dashboards</h3>
<p>
   📍 About: This demo project is intended to <strong>showcase skills</strong> and uses <strong>synthetically generated data</strong>.<br>
   👉 Click the images to explore the interactive dashboards on <strong>Tableau Public</strong>.
</p>
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

<p>📂 Repository Structure:</p>
<pre>
Marketing-Analytics-DWH/
├── datasets/                · marketing_platform/ · web_analytics/ · crm_system/
│             
├── data_warehouse/
│   ├── scripts/
│   │   ├────────── bronze/
│   │   ├────────── silver/  · profile_cleaning/
│   │   ├────────── gold/
│   │   ├────────── tests/   · quality_checks_silver/ · quality_checks_gold.sql
│   │   └── init_database.sql
│   └── docs/
│ 
└── marketing_analytics/
    ├────────────── scripts/  01-04 (exploration), 
    │                         05-08 (preliminary analysis),
    │                         0901-0911 (performance analysis),
    │                         10 (path length), 11 (channel efficiency)
    │                         12 (dashboard views)           
    │
    └────────────── results/ · performance_analysis/ · path_length_and_channel_efficiency/
</pre>

<h2>1) Marketing Analysis</h2>
<p>Tasked with analyzing ad data from January to April 2024, I will start by addressing stakeholder communication and presenting the analysis results. Section 2 covers the data overview, ETL pipeline, and data warehouse build.</p>

### 1.1) Executive Summary

Analysis of multi-touch marketing data across 9 channels, 53 campaigns, ~8,500 users, and 87,000+ touchpoints (January–April 2024) reveals five key findings:

**1. All paid channels follow a Launch → Saturation pattern.** January ROAS ranged from 4.3x to 6.6x; by April, all channels had dropped below 1.4x for mid and top of funnel — up to 77%+ decline. This points to audience saturation, declining ad effectiveness, and rising competition. Critically, this decline could not have been correctly analyzed per funnel stage without the cost attribution fix I built during development (see [Section 2.5](#25-why-fact_attribution_linear_with_costs-exists)).  

**2. Instagram Ads is the most consistent performer across all metrics.** Lowest CPM, best CPM-to-CVR efficiency ratio and strongest April BOFU closing rate (+28.7% CVR MoM). LTV:CAC of 3.3 places it in the top tier alongside Google Search (3.2) and Google Display (3.4). Instagram is the only paid channel that performs in the top tier across cost efficiency, closing, retention, and LTV:CAC ratio — though at lower volume than other channels.

**3. Google Search (the premium channel) and Google Display justify their cost through different strengths.** Google Search has the highest absolute LTV (€53.20), strongest revenue ranking across attribution models (twice #1, twice #2), and best lead quality. Google Display leads in LTV:CAC (3.4) despite the weakest engagement metrics (lowest click-through rate) — it acquires high-value users who convert through other channels. Both outperform the social channels in long-term value per user.

**4. TikTok Ads drives new user acquisition, not lifetime value.** Lowest absolute LTV (€41.7) but fastest closing paths (1.76 avg touchpoints) and the lowest April BOFU conversion rate (2.03%). TikTok converts quickly when it converts — but it converts rarely, and the users it brings are the least valuable long-term.

**5. Facebook Ads is the consistent underperformer.** Last or near-last in revenue ranking across all attribution models (3x last, 1x second-to-last), worst lead quality, and worst closing efficiency among paid channels. Its CAC of €15.0 is the second-highest, but unlike Google Search (€16.5 CAC, €53.2 LTV), Facebook does not compensate with higher lifetime value (€44.2). Facebook costs nearly as much as the premium channel but delivers the weakest revenue performance.

> _Note: This analysis uses synthetically generated data. Absolute values serve as a demonstration framework; relative comparisons between channels and campaigns are analytically valid. Specific data limitations are noted inline throughout the analysis._

---

### 1.2) Funnel-Based Performance Analysis

The analysis is structured around three funnel stages, each evaluated using a dedicated attribution model to match the business question to the appropriate measurement perspective.

| Funnel Stage | Attribution Model | Business Question |
|---|---|---|
| **TOFU** — Attention Efficiency | First-Touch | Which channels efficiently generate qualified awareness? |
| **MOFU** — Intent & Conversion Efficiency | Linear (Multi-Touch) | Which channels contribute to the full conversion journey? |
| **BOFU** — Profitability & Long-Term Growth | Last-Touch | Which channels capture value and drive sustainable revenue? |

---

#### 1.2.1) Attention Efficiency (TOFU)

**Goal:** Efficiently generate qualified awareness and traffic.

**Key finding:** Instagram Ads delivers the most cost-efficient reach across all attention metrics, while Google Search commands a premium that its conversion quality partially justifies.

<table>
  <thead>
    <tr><th>Channel</th><th>Avg CPC</th><th>CTR Rank</th><th>CPM-to-CVR Ratio</th><th>Efficiency</th></tr>
  </thead>
  <tbody>
    <tr><td>Instagram Ads</td><td>€0.89</td><td>#1</td><td>1,856</td><td>High</td></tr>
    <tr><td>TikTok Ads</td><td>€0.94</td><td>#4</td><td>1,966</td><td>High</td></tr>
    <tr><td>Google Display</td><td>€0.98</td><td>#5</td><td>2,078</td><td>Medium</td></tr>
    <tr><td>Google Search</td><td>€1.15</td><td>#2</td><td>2,149</td><td>Medium</td></tr>
    <tr><td>Facebook Ads</td><td>€1.04</td><td>#3</td><td>2,365</td><td>Low</td></tr>
  </tbody>
</table>

The CPM-to-CVR Efficiency Ratio combines reach cost with conversion quality, providing a composite metric that is not affected by the monthly spend distribution artifact. Instagram wins both dimensions — cheapest reach and strong conversion quality — while Facebook pays more for reach with weaker follow-through.

**TikTok's acquisition signal:** TikTok-acquired users show the shortest first-purchase paths across all months (8.36 avg touchpoints in April vs. 9.23 for Instagram), indicating audiences with high immediate purchase intent. However, this speed comes at a cost — TikTok's LTV is the lowest among paid channels (€41.70), suggesting that fast converters are not necessarily valuable long-term customers.

> _Note: CTR values exceed 100% due to synthetic data (clicks > impressions) and should be read as click intensity. Relative channel comparisons remain valid, though differentiation is minimal (3.5% total spread). Monthly CAC/CPC/CPM trends reflect declining synthetic spend, not real efficiency gains. Cross-channel comparisons remain valid._

---

#### 1.2.2) Intent & Conversion Efficiency (MOFU)

**Goal:** Evaluate the full customer journey — how efficiently do touchpoints convert attention into revenue?

**Key finding:** By April, every paid channel falls below the 1.5x profitability threshold when evaluated across the full customer journey. All channels start profitably in January (4.3–4.7x) but lose 70–77% of their MOFU ROAS within four months — confirming audience saturation not just at the top of the funnel, but across the entire conversion path. This is the strongest signal in the data that continued spend at current levels is unsustainable without new audience strategies or channel diversification.

This analysis relies on `fact_attribution_linear_with_costs`, which distributes both revenue *and* costs equally across all touchpoints in a converting journey — a table I built after discovering that the standard linear model left costs unattributed at the funnel-stage level (see [Section 1.3](#13-attribution-insights)).

**Overall MOFU ROAS:** 2.12x (€147,679 revenue / €69,607 attributed cost)

**MOFU ROAS by channel (January–April 2024):**

<p align="center"><img src="https://github.com/user-attachments/assets/b67ddb37-44e6-4ae2-80a3-0a16bac1cb09" alt="MOFU ROAS by Channel" width="700"></p>

**120-Day MOFU ROAS values (desc.):** Google Display 2.20x, Facebook Ads 2.15x, TikTok Ads 2.11x, Google Search 2.09x, Instagram Ads 2.07x

March is the tipping point: Google Search (1.56x) and TikTok Ads (1.67x) already cross below the 1.5x threshold, while the remaining channels follow in April. Facebook Ads shows the most resilient April performance (1.28x) — still unprofitable, but the slowest to deteriorate. The 120-day aggregates (2.07–2.20x) remain above threshold because strong January and February performance masks the April collapse.

**Path length and the trust effect:** The average converting user interacts with 5 touchpoints before purchasing at an average order value of €153.30. Repeat buyers need roughly 30% fewer touchpoints than first-time buyers across all months (e.g., April: 4.31 avg touchpoints for 250 repeat purchases vs. 8.90 for 555 first purchases), validating the trust effect. The share of repeat purchases grows from 4.4% in January to 31.1% in April, building a stable repeat-purchase engine even as total purchase volume declines (908 → 805).

> _Note: Monthly MOFU CVR and AOV trends show uniform growth/decline curves across all channels. This is a synthetic data artifact — the generated data produces near-identical engagement volumes across channels, resulting in parallel trend lines that would diverge with real-world data. Within-month comparisons remain valid._

---

#### 1.2.3) Profitability & Long-Term Growth (BOFU)

**Goal:** Maximize revenue and drive sustainable, profitable growth.

**Key finding:** While MOFU ROAS collapses below the profitability threshold by April, BOFU (last-touch attribution) tells a different story: the closing machine still works. BOFU CVR stabilizes at ~2.3% after an initial ramp-up — the problem is not conversion efficiency, but audience exhaustion further up the funnel. The 120-day LTV analysis confirms that three of five paid channels operate in the healthy 3–5x LTV:CAC band, with Google Search delivering the highest absolute lifetime value (€53.19) and Google Display the best efficiency ratio (3.43).

**Monthly BOFU ROAS (Last-Touch Attribution, Paid Channels):**

<table>
  <thead>
    <tr><th>Channel</th><th>Jan</th><th>Feb</th><th>Mar</th><th>Apr</th></tr>
  </thead>
  <tbody>
    <tr><td>Google Search</td><td>7.85x</td><td>6.40x</td><td>4.05x</td><td>1.97x</td></tr>
    <tr><td>TikTok Ads</td><td>6.61x</td><td>5.73x</td><td>5.33x</td><td>4.57x</td></tr>
    <tr><td>Instagram Ads</td><td>6.30x</td><td>4.67x</td><td>3.83x</td><td>4.19x</td></tr>
    <tr><td>Facebook Ads</td><td>5.96x</td><td>5.85x</td><td>4.28x</td><td>4.27x</td></tr>
    <tr><td>Google Display</td><td>5.07x</td><td>6.29x</td><td>5.70x</td><td>2.93x</td></tr>
  </tbody>
</table>

BOFU ROAS values are higher than MOFU because last-touch attribution concentrates all credit on the final converting touchpoint. The decline pattern differs by channel: Google Search drops the most (7.85x → 1.97x, −75%), while TikTok Ads (4.57x) and Facebook Ads (4.27x) show the strongest April resilience. Instagram is the only channel with an April rebound (3.83x → 4.19x, +9.5%).

<img width="1977" height="1177" alt="bofu_cvr_by_channel" src="https://github.com/user-attachments/assets/53b3e7db-779a-4405-9ab4-9bc8c933c1d9" />

**BOFU CVR stabilization:** Across all paid channels, BOFU CVR jumps from 1.43% in January to 2.59% in February, then stabilizes around 2.3–2.4% through March and April. This plateau signals that closing efficiency is not deteriorating — the funnel converts at a consistent rate once users reach the bottom. The revenue decline visible in BOFU ROAS is driven by fewer users entering the funnel, not by worsening conversion at the exit.



**120-Day LTV by Channel (All Cohorts, Dashboard Aggregates):**

<table>
  <tr>
    <td>
      <img src="https://github.com/user-attachments/assets/24879dad-be94-499c-b1b7-92c363167c4c" width="900">
    </td>
    <td>
      <img src="https://github.com/user-attachments/assets/9cc49b57-6129-411f-9c23-ba1d9bead2c0" alt="LTV vs. CAC by Channel" width="900">
    </td>
  </tr>
</table>

Google Display, Instagram Ads, and Google Search all operate in the healthy 3–5x band. Google Search justifies the highest CAC (€16.48) with the highest absolute LTV (€53.19) — it acquires the most valuable customers. Google Display achieves the best ratio (3.43) through the lowest CAC (€14.26) rather than the highest revenue per user. TikTok and Facebook sit in the Monitor band: not unprofitable, but their per-user value does not justify aggressive scaling.

**Instagram's April signal:** Instagram is the only paid channel where BOFU CVR improves in April (+28.7% MoM, rising from 1.98% to 2.55%). Combined with its April BOFU ROAS rebound (+9.5%), Instagram shows counter-cyclical closing strength — it performs better as other channels deteriorate, suggesting its audience is less saturated or more responsive in late-cycle conditions.

> _Note: For visualization purposes I build a LTV & Cohort Analysis Dashboard, which you can see <a href="https://public.tableau.com/views/Multi-TouchMarketingDashboard/Overall2?:language=de-DE&:sid=&:redirect=auth&:display_count=n&:origin=viz_share_link" >here</a>. 120-day LTV cohort sizes are heavily skewed (Jan: 93%, Feb: 6.8%, Mar: 0.5%) due to the synthetic data generation. Cross-cohort comparisons are not interpretable; the LTV table above uses all-cohort aggregates to avoid this limitation. The January cohort's purchase rate remains stable at ~10% per month over four months, indicating strong retention for a non-subscription e-commerce model._

---

### 1.3) Attribution Insights

Multi-touch attribution reveals channel dynamics that single-touch models cannot capture.

#### Assisting vs. Closing Roles

Comparing First-Touch and Last-Touch revenue per channel reveals a clear spectrum: TikTok Ads (−€5.2K) and Facebook Ads (−€4.2K) generate significantly more acquisition revenue than closing revenue — they initiate journeys that other channels finish. Google Search sits nearly balanced (−€0.2K), performing equally well at both ends. The surprise is Google Display (+€2.4K): the only channel that closes more than it initiates, acting as a silent converter for traffic other channels brought in.

<img width="1977" height="1177" alt="tofu_bofu_revenue_gap" src="https://github.com/user-attachments/assets/baaa2552-7870-41ac-8c66-c9fe3b22a985" />

#### What I Learned Building the Cost Attribution

The most significant insight of this project emerged from a limitation I discovered during development. The original `fact_attribution_linear` table distributes revenue equally across all touchpoints in a converting journey — standard practice for multi-touch attribution. But when I built the Tableau dashboards and applied funnel-stage filters, the numbers didn't add up: MOFU-filtered views showed revenue only from mid-funnel touchpoints, while costs still reflected _all_ touchpoints. The original approach summed spend without differentiating funnel stages, inflating the ROAS denominator for any filtered view. As a result, filtered ROAS values appeared significantly worse than they actually were.

The root cause was a granularity mismatch. Revenue had been attributed to individual touchpoints, but costs remained at the aggregate campaign-day level in `fact_spend`. Joining these two tables directly produces distorted results because the row structures don't align.

My solution was `fact_attribution_linear_with_costs` — a new table that distributes costs proportionally alongside revenue, so each touchpoint receives both a `revenue_share` and a `cost_share`. The technical details are documented in [Section 2.5](#25-why-fact_attribution_linear_with_costs-exists).

#### Path Length Does Not Predict Revenue

The correlation between path length and purchase revenue is effectively zero (r = −0.00028). Short paths (1–7 touchpoints) and long paths (8+ touchpoints) produce nearly identical average order values (~€135 vs. ~€133). This challenges the assumption that "more touchpoints = higher basket size" and suggests that efficient, targeted journey design matters more than maximizing touchpoint volume.

<pre>
   <code>
SELECT                                                                                              r_correlation
    (SUM(aabb))/(SQRT(SUM(a_2))*SQRT(SUM(b_2))) as r_correlation                                    -----------------------
FROM (                                                                                              -0,00027886619616565117
SELECT 
    touchpoint_number,
    revenue,
    (touchpoint_number - avg_tp)*(revenue - avg_revenue) AS aabb,
    POWER(touchpoint_number - avg_tp, 2) AS a_2,
    POWER(revenue - avg_revenue, 2) AS b_2 
FROM (
    SELECT
        touchpoint_number,
        revenue, 
        AVG(touchpoint_number) OVER()AS avg_tp,
        AVG(revenue) OVER() AS avg_revenue 
    FROM gold.fact_attribution_last_touch
) t ) b;

See 05_magnitude_analysis.sql for Query No. 10.14) Does the touchpoint number (position in the journey) correlate with revenue?
      and Queries No. 10.15) Are shorter or longer journeys associated with higher-value purchases?

SELECT                                                                                              avg_revenue_short_path
    AVG(revenue) AS avg_revenue_short_path                                                          -----------------------
FROM gold.fact_attribution_last_touch                                                               135.797271 
WHERE touchpoint_number <= (SELECT AVG(touchpoints_in_path) FROM gold.fact_attribution_linear);

SELECT 
    AVG(revenue) AS avg_revenue_long_path                                                           avg_revenue_long_path
FROM gold.fact_attribution_last_touch                                                               ---------------------
WHERE touchpoint_number > (SELECT AVG(touchpoints_in_path) FROM gold.fact_attribution_linear);      132.620637 
   </code>
</pre>

---

### 1.4) Strategic Recommendations

Based on the analysis results, the data suggests the following actions for a marketing team facing this scenario.

**Address the saturation pattern.** By April, every paid channel falls below the 1.5x profitability threshold across the full customer journey (MOFU ROAS), with declines of 70–77% from January peaks. This is the most urgent signal in the data. The response involves three levers: refreshing ad creatives to combat audience fatigue, expanding targeting to reach new audience segments, and establishing ROAS thresholds that trigger automatic campaign review — so that underperforming spend is caught before it erodes margins further.

**Reallocate budget from Facebook toward Instagram and Google Display.** Facebook is the weakest paid channel across efficiency dimensions: worst CPM-to-CVR ratio in TOFU, lowest LTV:CAC (2.95), and a −€4.2K TOFU-BOFU revenue gap showing it initiates conversions it rarely finishes. Instagram and Google Display both sit in the healthy LTV:CAC band (3.26 and 3.43 respectively), and their profiles complement each other — Instagram delivers the most cost-efficient reach and strongest late-cycle closing performance, while Google Display achieves the best return per acquisition euro through low CAC rather than high volume.

**Evaluate channels by funnel role, not single-model ROAS.** The attribution analysis shows that channels work as an ecosystem. TikTok generates acquisition revenue (−€5.2K gap = strong initiator), but these users often convert through other channels further down the journey. Google Display does the opposite (+€2.4K gap = silent closer). Cutting TikTok spend based on last-touch ROAS alone would starve the funnel of new users — exactly the kind of misallocation that multi-touch attribution is designed to prevent. Each channel should be measured against the metric that matches its funnel role.

**Prioritize retention — 81% of customers buy only once.** This is the single largest growth lever in the data. Repeat buyers need roughly 30% fewer touchpoints than first-time buyers, and the share of repeat purchases grows from 4.4% in January to 31.1% in April — proving that a retention engine is already forming organically. Every converted repeat buyer is cheaper than acquiring a new one. Investment in post-purchase journeys and re-engagement campaigns would accelerate this effect at no additional media cost.

<p align="center">
   <img width="586" height="265" alt="Repeat Purchase Growth" src="https://github.com/user-attachments/assets/167efc2c-129a-4be0-9406-bbb32b64bf03" />
</p>

---

### 1.5) Limitations & Assumptions

**Synthetic data:** All findings are based on synthetically generated data with intentional quality issues for ETL demonstration. Channel engagement volumes are unrealistically uniform (clicks, impressions, and touchpoints are near-identical across channels), limiting the differentiation potential that real data would provide.

**Monthly spend distribution:** Raw spend collapses from €41,541 (January) to €1,134 (April) — a 97.3% decline. This is a data generation artifact, not a real budget decision. Monthly cost-based trends (ROAS, CAC, CPA, CPC, CPM) are affected by this artifact. Cross-channel and cross-campaign relative comparisons within the same time period, as well as total-period aggregates, remain valid.

**Cohort imbalance:** 93% of users are acquired in January. February and March cohorts are too small for statistically reliable cross-cohort comparisons. Within-January analysis is robust.

**Attribution coverage:** 75% of purchases are matched to touchpoint paths. 25% of purchases have no attributable touchpoints (likely direct purchases or touchpoints outside the attribution window).

**CPM limitation:** CPM values are unrealistically high (~€2,519 vs. typical €5–30) due to low synthetic impression volumes. Absolute CPM values are not benchmarkable; the CPM-to-CVR ratio aggregates across months and is not affected.

**Linear attribution model:** Equal-weight distribution is a simplification. Time-decay or data-driven models could reveal additional insights. The linear model was chosen for transparency and interpretability, and the three complementary perspectives (first-touch, linear, last-touch) mitigate single-model bias.

---

### 1.6) Tactical Drill-Down (Dashboards)

While strategic conclusions are drawn at the channel level in this README, campaign-level KPIs are available in the interactive Tableau dashboards for tactical optimization and drill-down.

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

The dashboards enable:

- **Campaign ranking and filtering** — sort by ROAS, CAC, CVR, and LTV:CAC across all 53 campaigns
- **Attribution model comparison** — side-by-side first-touch, linear, and last-touch views per campaign
- **Funnel-stage breakdown** — TOFU/MOFU/BOFU performance with correct cost attribution at each stage
- **Trend monitoring** — monthly performance tracking to identify saturation and intervention signals

Campaign-level analysis is positioned as a tactical tool, not a parallel narrative. Where individual campaigns illustrate strategic patterns (e.g., Winter_Sale_2024 #21 as the top LTV:CAC performer, or the divergent trajectories of Flash_Sale_Weekend #44 vs. #17), they are referenced in the analysis above as supporting evidence.

---

### 1.8) What I Would Do Next

Building this project taught me where the analytical boundaries are — and where the natural extensions would be. These are the directions I would explore with real production data and a longer time horizon.

**Additional attribution models.** The linear model distributes credit equally, which is a deliberate simplification. The next step would be implementing time-decay attribution (weighting recent touchpoints higher) and position-based attribution (emphasizing the first and last touch). Comparing all models side-by-side for the same data would show where they agree (robust findings) and where they diverge (areas that need closer investigation). I'd also want to understand when linear attribution is "good enough" versus when a more complex model would change real budget decisions.

**Testing for causation, not just correlation.** Multi-touch attribution shows which channels _appear_ alongside conversions — but it cannot prove that a channel actually _caused_ the conversion. A user who clicks a Google Search ad might have bought anyway. The way to test this is through holdout experiments: suppress ads for a random user group and compare their conversion rate against the exposed group. This is something I haven't built yet, but it's the logical next question after attribution — and it's the question I'd want to answer first in a real marketing team.

**Longer LTV window and retention modeling.** The current 120-day LTV captures early repeat behavior, but true customer lifetime value requires 12–24 months of data. With a longer time horizon, I'd build customer segmentation based on purchase recency, frequency, and monetary value (RFM analysis) to identify which user segments deserve the most retention investment. The 81% one-time buyer rate is the most obvious starting point — understanding _why_ these users don't return is worth more than optimizing which channel acquires them.

**Moving from batch to real-time.** The current warehouse uses a full-load, truncate-and-insert pattern. That's appropriate for a demo project, but in production, I'd want incremental loading (only new or changed records), automated quality checks on each load, and alerting when key metrics move outside expected ranges. The goal: detecting a saturation pattern like the one in this data in February, not after four months of batch analysis.

<hr>

<h2>2) End-To-End Data Warehouse and ETL</h2>
<p>A SQL Server data warehouse for marketing analytics, built on a Bronze → Silver → Gold medallion architecture. The warehouse, named <strong>marketing_dw</strong>, integrates data from three source systems (marketing platform, web analytics, CRM system) and models it into a star schema with a fact constellation for multi-touch attribution.</p>
<h4>2.1) Architecture</h4>
<p>The warehouse follows a three-layer medallion architecture:</p>
<img width="1009" height="647" alt="High Level Architecture" src="https://github.com/user-attachments/assets/bf7bdb92-56c5-4dd5-a72a-375d4bc0d7de" />

<p><b>Bronze Layer</b> — Raw ingestion from CSV source files via <code>BULK INSERT</code>. All columns are stored as <code>NVARCHAR</code> to preserve the original data as-is. No transformations are applied. Load method: truncate and full reload.</p>

<p><b>Silver Layer</b> — Cleaned, standardized, and type-cast data. Transformations include data cleansing (e.g., fixing misspelled channel names like <code>"gogle search"</code> → <code>"Google Search"</code>), date format normalization (DD.MM.YYYY → ISO), invalid value handling (out-of-range IDs, <code>"not_available"</code> placeholders), and derived columns. Each silver table includes a <code>dwh_create_date</code> audit column.</p>

<p><b>Gold Layer</b> — Business-ready tables following a star schema with dimension tables (<code>dim_date</code>, <code>dim_user</code>, <code>dim_campaign</code>, <code>dim_channel</code>) and granular atomic fact tables. The Gold layer applies data integration (joining across source systems), enrichment (e.g., adding acquisition channel to click and session facts), and business logic (attribution modeling, touchpoint path construction).</p>

<p>Example visualisation demonstrating the data flow for <code>fact_attribution_linear_with_costs</code> table (to see the full <strong>Data Flow Document</strong>, click the image):</p>
 <a href="https://github.com/johanna-oncken/Marketing-Analytics-DWH/blob/main/data_warehouse/docs/data_flow.pdf">
  <img width="1220" height="291" alt="Bildschirmfoto 2026-02-13 um 15 22 35" src="https://github.com/user-attachments/assets/7c561e49-d21a-49ea-99c3-a37d59933b9c" />
 </a>

<hr>

<h4>2.2) Data Sources</h4>

<p>The raw source data was intentionally generated with messy, inconsistent, and partially erroneous records to demonstrate realistic ETL/ELT data cleansing scenarios. This includes misspelled channel names, mixed date formats, invalid IDs, non-numeric values in numeric fields, and placeholder strings like "not_available". The raw tables contain <strong>up to 104,773 rows</strong> to simulate a realistic data ingestion volume.</p>

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

<p>The warehouse contains 8 Bronze tables (raw ingestion), 8 Silver tables (cleaned and standardized), 4 Gold dimension tables, and 9 Gold fact tables. The table below summarizes all layers. For detailed column-level documentation of the Gold layer (data types, descriptions, grain), see the <a href="https://github.com/johanna-oncken/Marketing-Analytics-DWH/blob/main/data_warehouse/docs/data_catalog.md">Data Catalog</a>.</p>

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
    <tr><td rowspan="8"><b>Bronze</b></td><td><code>mrkt_raw_ad_spend</code></td><td>Channel × Campaign x Day</td><td>Raw CSV ingestion, all NVARCHAR</td></tr>
    <tr><td><code>mrkt_raw_campaigns</code></td><td>Campaign</td><td>Raw CSV ingestion, all NVARCHAR</td></tr>
    <tr><td><code>mrkt_raw_clicks</code></td><td>Click event</td><td>Raw CSV ingestion, all NVARCHAR</td></tr>
    <tr><td><code>web_raw_sessions</code></td><td>Session</td><td>Raw CSV ingestion, all NVARCHAR</td></tr>
    <tr><td><code>web_raw_touchpoints</code></td><td>Touchpoint event</td><td>Raw CSV ingestion, all NVARCHAR</td></tr>
    <tr><td><code>crm_raw_channels</code></td><td>Channel</td><td>Raw CSV ingestion, all NVARCHAR</td></tr>
    <tr><td><code>crm_raw_purchases</code></td><td>Purchase</td><td>Raw CSV ingestion, all NVARCHAR</td></tr>
    <tr><td><code>crm_raw_user_acquisitions</code></td><td>User</td><td>Raw CSV ingestion, all NVARCHAR</td></tr>
    <tr><td rowspan="8"><b>Silver</b></td><td><code>mrkt_ad_spend</code></td><td>Channel × Campaign x Day</td><td>Date parsing, channel standardization, spend cleaning</td></tr>
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
    <tr><td rowspan="9"><b>Gold Fact</b></td><td><code>fact_spend</code></td><td>Spend record (Date × Channel × Campaign)</td><td>Ad spend enriched with campaign metadata</td></tr>
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

<h4>2.4) Data Model</h4>

<p>The Gold layer follows a <b>star schema</b> for core marketing analytics (spend, clicks, sessions, touchpoints, purchases), combined with a <b>fact constellation</b> for attribution modeling.</p>

<p>The core fact tables (<code>fact_spend</code>, <code>fact_clicks</code>, <code>fact_sessions</code>, <code>fact_touchpoints</code>, <code>fact_purchases</code>) each relate to the shared dimensions <code>dim_date</code>, <code>dim_user</code>, <code>dim_channel</code>, and <code>dim_campaign</code> through natural keys rather than surrogate foreign keys. This design choice optimizes for BI tool compatibility (Tableau, Power BI) and query simplicity. A classic Kimball star schema with surrogate key FKs could be implemented by adding <code>user_key</code>, <code>channel_key</code>, and <code>campaign_key</code> columns to the fact tables.</p>

<p>The analytical fact tables (<code>fact_touchpath</code>, <code>fact_attribution_linear</code>, <code>fact_attribution_last_touch</code>, <code>fact_attribution_linear_with_costs</code>) form a fact constellation that references <code>fact_purchases</code> through the natural key <code>purchase_id</code> to enable multi-touch attribution analysis.</p>

<p>See the <a href="https://github.com/johanna-oncken/Marketing-Analytics-DWH/blob/main/data_warehouse/docs/data_model.pdf"><strong>Data Model Document</strong></a></p>

<p align="center">
   <img width="847" height="696" style="display:block; margin: 0 auto;" alt="Data model" src="https://github.com/user-attachments/assets/4e1d7917-fc2a-42d9-9bea-ab54effc50f1" />
</p>


<hr>

<h4>2.5) Why <code>fact_attribution_linear_with_costs</code> exists</h4>

<h5>2.5.1) The Problem</h5>

<p>The original <code>fact_attribution_linear</code> table distributes <b>revenue</b> equally across all touchpoints in a converting user journey. This enables questions like "How much revenue does each channel contribute?" However, it cannot answer efficiency questions like "What is the true ROI per channel?" — because <b>costs remain at the spend-record level (channel × campaign × day)</b> in <code>fact_spend</code>, while revenue is distributed at the touchpoint level in the attribution table.</p>

<p>Joining these two tables directly would produce distorted ROAS and ROI values, since the granularity mismatch causes costs to be either duplicated or lost depending on the join logic.</p>

<p>This is a common structural problem in marketing attribution: revenue attribution is well-established, but cost attribution is often left as an afterthought, forcing analysts to compare touchpoint-level revenue against aggregate-level spend in separate queries — which breaks down when trying to evaluate channel or campaign efficiency at the touchpoint level.</p>

<h5>2.5.2) The Solution</h5>

<p><code>fact_attribution_linear_with_costs</code> solves this by applying <b>proportional cost allocation</b> alongside revenue attribution. For each touchpoint in a converting journey, the table includes both a <code>revenue_share</code> (from the original linear model) and a <code>cost_share</code> calculated as:</p>

<pre><code>cost_share = daily_campaign_spend / touchpoints_for_that_campaign_on_that_day</code></pre>

<p>This means if Campaign 5 spent €100 on January 15 and had 20 attributed touchpoints that day, each touchpoint receives a <code>cost_share</code> of €5. Revenue and cost are now at the same granularity, enabling accurate per-touchpoint ROI and ROAS calculations.</p>

<h5>2.5.3) Scope</h5>

<p>The cost-enhanced table is restricted to <b>paid marketing channels only</b> (Facebook Ads, Google Display, Google Search, Instagram Ads, TikTok Ads). Organic channels (Direct, Email, Organic Search, Referral) are excluded because they carry no media cost — including them would distort efficiency metrics. For full customer journey analysis including organic channels, the original <code>fact_attribution_linear</code> table remains available.</p>

<h5>2.5.4) Usage example</h5>

<pre><code>-- Channel-level ROAS with attributed costs
SELECT
    channel,
    SUM(revenue_share)  AS attributed_revenue,
    SUM(cost_share)     AS attributed_costs,
    SUM(revenue_share) / NULLIF(SUM(cost_share), 0) AS roas
FROM gold.fact_attribution_linear_with_costs
GROUP BY channel;</code></pre>

<hr>

<h4>2.6) Data Quality</h4>

<p>Quality assurance is applied at every layer:</p>

<p><b>Bronze → Silver (Profiling &amp; Cleaning):</b> Each source table has a dedicated profiling script (<code>profile_clean_*.sql</code>) that documents row counts, duplicate checks, column-level quality assessments with categorized status flags (<code>Valid</code>, <code>Missing</code>, <code>Invalid</code>, <code>Out of range</code>), and cleaned column previews. Findings from profiling directly inform the transformation logic in <code>proc_load_silver</code>.</p>

<pre>
-- Excerpt from <code>profile_clean_mrkt_ad_spend.sql</code> running Campaign ID Quality Check:
   <code>
      campaign_id  id_status           occurrences
      -----------  ------------------  -----------
      NULL         Non-numeric         8          
      110.0        Out of range (>53)  3          
      125.0        Out of range (>53)  3          
      140.0        Out of range (>53)  3          
       64.0        Out of range (>53)  2          
       78.0        Out of range (>53)  3          
       99.0        Out of range (>53)  1          
        1.0        Valid               3          
       11.0        Valid               1
      ... (truncated)
   </code>
</pre>

<p><b>Silver (Post-Load Checks):</b> <code>quality_checks_silver.sql</code> validates the silver tables after loading — checking for NULLs in critical columns, consistent channel names, reasonable value ranges, and cross-table consistency (e.g., verifying that negative revenue values correspond to matching positive returns).</p>

<p><b>Gold — Dimensions:</b> <code>quality_checks_dim.sql</code> validates surrogate key uniqueness, natural key uniqueness, and row count consistency with silver source tables.</p>

<p><b>Gold — Fact Tables:</b> <code>quality_checks_fact.sql</code> and <code>quality_checks_fact_multi_touch.sql</code> validate surrogate key uniqueness, referential integrity against all related dimensions and fact tables, date/timestamp consistency with <code>dim_date</code>, NOT NULL constraints, revenue share accuracy (sum of shares equals total revenue per purchase within rounding tolerance), and row count comparisons with silver source tables.</p>

<p><b>Gold — Attribution with Costs:</b> The DDL script for <code>fact_attribution_linear_with_costs</code> includes inline quality checks for row count comparison against the original table, cost attribution coverage percentage, total revenue vs. total cost plausibility, and cost attribution breakdown by channel.</p>

<hr>

<h4>2.7) Execution Order</h4>

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

<h4>2.8) Technical Environment</h4>

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

