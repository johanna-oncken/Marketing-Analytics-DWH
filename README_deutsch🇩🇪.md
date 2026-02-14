# Marketing-Analytics-DWH
<h3>End-to-end Data Warehouse (Bronze/Silver/Gold) mit Multi-Touch Attribution und Tableau Dashboards</h3>
<p>
   📍 Über dieses Projekt: Dieses Demo-Projekt dient der <strong>Präsentation von Fähigkeiten</strong> und verwendet <strong>synthetisch generierte Daten</strong>.<br>
   👉 Klicke auf die Bilder, um die interaktiven Dashboards auf <strong>Tableau Public</strong> zu erkunden.
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

<p>📂 Repository-Struktur:</p>
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
    ├────────────── scripts/  01-04 (Exploration), 
    │                         05-08 (Voranalyse),
    │                         0901-0911 (Performance-Analyse),
    │                         10 (Pfadlänge), 11 (Kanaleffizienz)
    │
    └────────────── results/ · performance_analysis/ · path_length_and_channel_efficiency/
</pre>

<h2>1) Marketing-Analyse</h2>
<h4>1.1) Projektauftrag</h4>
<p>Aufgabe ist die Analyse von Werbedaten aus Januar bis April 2024. Zunächst werden die Stakeholder-Kommunikation und die Analyseergebnisse vorgestellt. Abschnitt 2 behandelt die Datenübersicht, die ETL-Pipeline und den Aufbau des Data Warehouse.</p>

<hr>

<h2>2) End-To-End Data Warehouse und ETL</h2>
<p>Grundlage ist ein SQL Server Data Warehouse für Marketing-Analytics, aufgebaut nach einer Bronze → Silver → Gold Medallion-Architektur. Das Warehouse <strong>marketing_dw</strong> integriert Daten aus drei Quellsystemen (Marketing-Plattform, Web Analytics, CRM-System) und modelliert sie in ein Star Schema mit einer Fact Constellation für Multi-Touch Attribution.</p>

<h4>2.1) Architektur</h4>
<p>Das Warehouse folgt einer dreischichtigen Medallion-Architektur:</p>
<img width="1009" height="647" alt="High Level Architecture" src="https://github.com/user-attachments/assets/bf7bdb92-56c5-4dd5-a72a-375d4bc0d7de" />

<p><b>Bronze Layer</b> — Rohdatenübernahme aus CSV-Quelldateien via <code>BULK INSERT</code>. Alle Spalten werden als <code>NVARCHAR</code> gespeichert, um die Originaldaten unverändert zu erhalten. Keine Transformationen. Lademethode: Truncate und vollständiger Reload.</p>

<p><b>Silver Layer</b> — Bereinigte, standardisierte und typkonvertierte Daten. Transformationen umfassen Datenbereinigung (z.B. Korrektur fehlerhafter Channel-Namen wie <code>"gogle search"</code> → <code>"Google Search"</code>), Datumsformat-Normalisierung (DD.MM.YYYY → ISO), Behandlung ungültiger Werte (IDs außerhalb des gültigen Bereichs, Platzhalter wie <code>"not_available"</code>) sowie abgeleitete Spalten. Jede Silver-Tabelle enthält eine <code>dwh_create_date</code>-Audit-Spalte.</p>

<p><b>Gold Layer</b> — Business-ready Tabellen nach einem Star Schema mit Dimensionstabellen (<code>dim_date</code>, <code>dim_user</code>, <code>dim_campaign</code>, <code>dim_channel</code>) und granularen atomaren Faktentabellen. Der Gold Layer umfasst Datenintegration (Verknüpfung über Quellsysteme hinweg), Anreicherung (z.B. Ergänzung des Akquisitionskanals bei Click- und Session-Fakten) und Geschäftslogik (Attributionsmodellierung, Touchpoint-Pfad-Konstruktion).</p>

<p>Beispielvisualisierung des Datenflusses für die Tabelle <code>fact_attribution_linear_with_costs</code> (für das vollständige <strong>Data Flow Dokument</strong> auf das Bild klicken):</p>
 <a href="https://github.com/johanna-oncken/Marketing-Analytics-DWH/blob/main/data_warehouse/docs/data_flow.pdf">
  <img width="1220" height="291" alt="Bildschirmfoto 2026-02-13 um 15 22 35" src="https://github.com/user-attachments/assets/7c561e49-d21a-49ea-99c3-a37d59933b9c" />
 </a>

<hr>

<h4>2.2) Datenquellen</h4>

<p>Die Rohdaten wurden absichtlich mit fehlerhaften, inkonsistenten und teilweise falschen Einträgen generiert, um realistische ETL/ELT-Bereinigungsszenarien abzubilden. Dazu gehören falsch geschriebene Channel-Namen, gemischte Datumsformate, ungültige IDs, nicht-numerische Werte in numerischen Feldern und Platzhalter-Strings wie "not_available". Die Rohtabellen umfassen <strong>bis zu 104.773 Zeilen</strong>, um ein realistisches Dateningestionvolumen zu simulieren.</p>

<table>
  <thead>
    <tr>
      <th>Quellsystem</th>
      <th>Schema-Präfix</th>
      <th>Beschreibung</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>Marketing-Plattform (<code>MRKT</code>)</td>
      <td><code>mrkt_</code></td>
      <td>Werbeausgaben, Kampagnen-Metadaten, Klick-Events aus Paid Channels</td>
    </tr>
    <tr>
      <td>Web Analytics (<code>WEB</code>)</td>
      <td><code>web_</code></td>
      <td>Session-Daten, Touchpoint-Events (Views, Impressions, Clicks)</td>
    </tr>
    <tr>
      <td>CRM-System (<code>CRM</code>)</td>
      <td><code>crm_</code></td>
      <td>Käufe, User-Akquisitionsdaten, Channel-Referenzdaten</td>
    </tr>
  </tbody>
</table>

<hr>

<h4>2.3) Tabellenübersicht</h4>

<p>Das Warehouse enthält 8 Bronze-Tabellen (Rohdatenübernahme), 8 Silver-Tabellen (bereinigt und standardisiert), 4 Gold-Dimensionstabellen und 9 Gold-Faktentabellen. Die folgende Tabelle fasst alle Schichten zusammen. Für die detaillierte Spaltendokumentation des Gold Layers (Datentypen, Beschreibungen, Granularität) siehe den <a href="https://github.com/johanna-oncken/Marketing-Analytics-DWH/blob/main/data_warehouse/docs/data_catalog.md">Data Catalog</a>.</p>

<table>
  <thead>
    <tr>
      <th>Layer</th>
      <th>Tabelle</th>
      <th>Granularität</th>
      <th>Transformationen / Beschreibung</th>
    </tr>
  </thead>
  <tbody>
    <tr><td rowspan="8"><b>Bronze</b></td><td><code>mrkt_raw_ad_spend</code></td><td>Channel × Campaign × Day</td><td>CSV-Rohdatenübernahme, alle Spalten NVARCHAR</td></tr>
    <tr><td><code>mrkt_raw_campaigns</code></td><td>Campaign</td><td>CSV-Rohdatenübernahme, alle Spalten NVARCHAR</td></tr>
    <tr><td><code>mrkt_raw_clicks</code></td><td>Click Event</td><td>CSV-Rohdatenübernahme, alle Spalten NVARCHAR</td></tr>
    <tr><td><code>web_raw_sessions</code></td><td>Session</td><td>CSV-Rohdatenübernahme, alle Spalten NVARCHAR</td></tr>
    <tr><td><code>web_raw_touchpoints</code></td><td>Touchpoint Event</td><td>CSV-Rohdatenübernahme, alle Spalten NVARCHAR</td></tr>
    <tr><td><code>crm_raw_channels</code></td><td>Channel</td><td>CSV-Rohdatenübernahme, alle Spalten NVARCHAR</td></tr>
    <tr><td><code>crm_raw_purchases</code></td><td>Purchase</td><td>CSV-Rohdatenübernahme, alle Spalten NVARCHAR</td></tr>
    <tr><td><code>crm_raw_user_acquisitions</code></td><td>User</td><td>CSV-Rohdatenübernahme, alle Spalten NVARCHAR</td></tr>
    <tr><td rowspan="8"><b>Silver</b></td><td><code>mrkt_ad_spend</code></td><td>Channel × Campaign × Day</td><td>Datumsparsing, Channel-Standardisierung, Spend-Bereinigung</td></tr>
    <tr><td><code>mrkt_campaigns</code></td><td>Campaign</td><td>Kampagnennamen-Korrekturen, Objective-Normalisierung</td></tr>
    <tr><td><code>mrkt_clicks</code></td><td>Click Event</td><td>Timestamp-Vereinheitlichung, Channel-Standardisierung</td></tr>
    <tr><td><code>web_sessions</code></td><td>Session</td><td>Typkonvertierung, Channel-Standardisierung</td></tr>
    <tr><td><code>web_touchpoints</code></td><td>Touchpoint Event</td><td>Interaction-Type-Normalisierung, Channel-Standardisierung</td></tr>
    <tr><td><code>crm_channels</code></td><td>Channel</td><td>Trimmen und Validieren</td></tr>
    <tr><td><code>crm_purchases</code></td><td>Purchase</td><td>Revenue-Typkonvertierung, Last-Touch-Channel-Bereinigung</td></tr>
    <tr><td><code>crm_user_acquisitions</code></td><td>User</td><td>Datumsparsing, Channel-Standardisierung</td></tr>
    <tr><td rowspan="4"><b>Gold Dim</b></td><td><code>dim_date</code></td><td>Kalendertag</td><td>Generiert via rekursiver CTE (2023–2024)</td></tr>
    <tr><td><code>dim_user</code></td><td>User</td><td>Union aller User-IDs über alle Silver-Tabellen</td></tr>
    <tr><td><code>dim_campaign</code></td><td>Campaign</td><td>53 Kampagnen über 5 Paid Channels</td></tr>
    <tr><td><code>dim_channel</code></td><td>Channel</td><td>9 Kanäle in 2 Kategorien (Paid, Organic)</td></tr>
    <tr><td rowspan="9"><b>Gold Fact</b></td><td><code>fact_spend</code></td><td>Spend Record (Date × Channel × Campaign)</td><td>Werbeausgaben angereichert mit Kampagnen-Metadaten</td></tr>
    <tr><td><code>fact_clicks</code></td><td>Click Event</td><td>Klicks angereichert mit Akquisitionskanal (First-Touch)</td></tr>
    <tr><td><code>fact_sessions</code></td><td>Session</td><td>Sessions angereichert mit Akquisitionskanal</td></tr>
    <tr><td><code>fact_touchpoints</code></td><td>Touchpoint Event</td><td>Alle Touchpoint-Interaktionen angereichert mit Kampagnenname</td></tr>
    <tr><td><code>fact_purchases</code></td><td>Purchase</td><td>Käufe angereichert mit Akquisitionsdaten</td></tr>
    <tr><td><code>fact_touchpath</code></td><td>Touchpoint × Purchase</td><td>Geordnete Touchpoint-Sequenzen pro konvertierender Journey</td></tr>
    <tr><td><code>fact_attribution_linear</code></td><td>Touchpoint × Purchase</td><td>Lineare (gleichgewichtete) Revenue-Attribution</td></tr>
    <tr><td><code>fact_attribution_last_touch</code></td><td>Purchase</td><td>Last-Touch Attribution (100 % zum letzten Touchpoint)</td></tr>
    <tr><td><code>fact_attribution_linear_with_costs</code></td><td>Touchpoint × Purchase</td><td>Lineare Attribution mit proportionaler Kostenverteilung (nur Paid)</td></tr>
  </tbody>
</table>

<hr>

<h4>2.4) Datenmodell</h4>

<p>Der Gold Layer folgt einem <b>Star Schema</b> für die Marketing-Kernanalysen (Spend, Clicks, Sessions, Touchpoints, Purchases), kombiniert mit einer <b>Fact Constellation</b> für die Attributionsmodellierung.</p>

<p>Die Kern-Faktentabellen (<code>fact_spend</code>, <code>fact_clicks</code>, <code>fact_sessions</code>, <code>fact_touchpoints</code>, <code>fact_purchases</code>) verweisen jeweils auf die gemeinsamen Dimensionen <code>dim_date</code>, <code>dim_user</code>, <code>dim_channel</code> und <code>dim_campaign</code> über natürliche Schlüssel statt über Surrogatschlüssel-Fremdschlüssel. Diese Designentscheidung optimiert die Kompatibilität mit BI-Tools (Tableau, Power BI) und die Abfrageeinfachheit. Ein klassisches Kimball Star Schema mit Surrogatschlüssel-FKs ließe sich durch Ergänzung von <code>user_key</code>, <code>channel_key</code> und <code>campaign_key</code> in den Faktentabellen implementieren.</p>

<p>Die analytischen Faktentabellen (<code>fact_touchpath</code>, <code>fact_attribution_linear</code>, <code>fact_attribution_last_touch</code>, <code>fact_attribution_linear_with_costs</code>) bilden eine Fact Constellation, die über den natürlichen Schlüssel <code>purchase_id</code> auf <code>fact_purchases</code> verweist und so Multi-Touch-Attributionsanalysen ermöglicht.</p>

<p>Siehe das <a href="https://github.com/johanna-oncken/Marketing-Analytics-DWH/blob/main/data_warehouse/docs/data_model.pdf"><strong>Data-Model-Dokument</strong></a></p>

<img width="847" height="696" alt="Data model" src="https://github.com/user-attachments/assets/4e1d7917-fc2a-42d9-9bea-ab54effc50f1" />

<hr>

<h4>2.5) Warum <code>fact_attribution_linear_with_costs</code> existiert</h4>

<h5>2.5.1) Das Problem</h5>

<p>Die ursprüngliche <code>fact_attribution_linear</code>-Tabelle verteilt den <b>Umsatz</b> gleichmäßig auf alle Touchpoints einer konvertierenden User Journey. Das ermöglicht Fragen wie „Wie viel Umsatz trägt jeder Kanal bei?" Allerdings kann sie keine Effizienzfragen beantworten wie „Was ist der tatsächliche ROI pro Kanal?" — denn die <b>Kosten verbleiben auf Spend-Record-Ebene (Channel × Campaign × Day)</b> in <code>fact_spend</code>, während der Umsatz auf Touchpoint-Ebene in der Attributionstabelle verteilt wird.</p>

<p>Ein direkter Join dieser beiden Tabellen würde verzerrte ROAS- und ROI-Werte erzeugen, da der Granularitätsunterschied dazu führt, dass Kosten je nach Join-Logik entweder dupliziert werden oder verloren gehen.</p>

<p>Das ist ein verbreitetes strukturelles Problem in der Marketing-Attribution: Revenue Attribution ist gut etabliert, aber Cost Attribution wird häufig vernachlässigt. Analysten sind dann gezwungen, Touchpoint-Level-Umsätze mit aggregierten Ausgaben in getrennten Abfragen zu vergleichen — was bei der Bewertung von Kanal- oder Kampagneneffizienz auf Touchpoint-Ebene zusammenbricht.</p>

<h5>2.5.2) Die Lösung</h5>

<p><code>fact_attribution_linear_with_costs</code> löst dieses Problem durch <b>proportionale Kostenverteilung</b> parallel zur Umsatzattribution. Für jeden Touchpoint in einer konvertierenden Journey enthält die Tabelle sowohl einen <code>revenue_share</code> (aus dem ursprünglichen linearen Modell) als auch einen <code>cost_share</code>, der wie folgt berechnet wird:</p>

<pre><code>cost_share = daily_campaign_spend / touchpoints_for_that_campaign_on_that_day</code></pre>

<p>Das bedeutet: Wenn Campaign 5 am 15. Januar 100 € ausgegeben hat und an diesem Tag 20 attribuierte Touchpoints hatte, erhält jeder Touchpoint einen <code>cost_share</code> von 5 €. Umsatz und Kosten liegen nun auf derselben Granularitätsebene, was präzise ROI- und ROAS-Berechnungen auf Touchpoint-Ebene ermöglicht.</p>

<h5>2.5.3) Scope</h5>

<p>Die kostenerweiterte Tabelle ist auf <b>bezahlte Marketingkanäle</b> beschränkt (Facebook Ads, Google Display, Google Search, Instagram Ads, TikTok Ads). Organische Kanäle (Direct, Email, Organic Search, Referral) werden ausgeschlossen, da sie keine Medienkosten verursachen — ihre Einbeziehung würde die Effizienzkennzahlen verzerren. Für eine vollständige Customer-Journey-Analyse einschließlich organischer Kanäle steht die ursprüngliche <code>fact_attribution_linear</code>-Tabelle weiterhin zur Verfügung.</p>

<h5>2.5.4) Anwendungsbeispiel</h5>

<pre><code>-- ROAS auf Kanalebene mit attribuierten Kosten
SELECT
    channel,
    SUM(revenue_share)  AS attributed_revenue,
    SUM(cost_share)     AS attributed_costs,
    SUM(revenue_share) / NULLIF(SUM(cost_share), 0) AS roas
FROM gold.fact_attribution_linear_with_costs
GROUP BY channel;</code></pre>

<hr>

<h4>2.6) Datenqualität</h4>

<p>Qualitätssicherung wird in jeder Schicht durchgeführt:</p>

<p><b>Bronze → Silver (Profiling &amp; Cleaning):</b> Jede Quelltabelle hat ein eigenes Profiling-Skript (<code>profile_clean_*.sql</code>), das Zeilenanzahlen, Duplikatprüfungen, spaltenweise Qualitätsbewertungen mit kategorisierten Statusflags (<code>Valid</code>, <code>Missing</code>, <code>Invalid</code>, <code>Out of range</code>) sowie bereinigte Spaltenvorschauen dokumentiert. Die Erkenntnisse aus dem Profiling fließen direkt in die Transformationslogik von <code>proc_load_silver</code> ein.</p>

<pre>
-- Auszug aus <code>profile_clean_mrkt_ad_spend.sql</code>, Campaign-ID Quality Check:
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
      ... (gekürzt)
   </code>
</pre>

<p><b>Silver (Post-Load Checks):</b> <code>quality_checks_silver.sql</code> validiert die Silver-Tabellen nach dem Laden — Prüfung auf NULLs in kritischen Spalten, konsistente Channel-Namen, plausible Wertebereiche und Cross-Table-Konsistenz (z.B. Überprüfung, dass negative Revenue-Werte korrespondierenden positiven Retouren zugeordnet werden können).</p>

<p><b>Gold — Dimensionen:</b> <code>quality_checks_dim.sql</code> validiert die Eindeutigkeit von Surrogatschlüsseln und natürlichen Schlüsseln sowie die Zeilenanzahl-Konsistenz mit den Silver-Quelltabellen.</p>

<p><b>Gold — Faktentabellen:</b> <code>quality_checks_fact.sql</code> und <code>quality_checks_fact_multi_touch.sql</code> validieren Surrogatschlüssel-Eindeutigkeit, referenzielle Integrität gegen alle zugehörigen Dimensions- und Faktentabellen, Datums-/Timestamp-Konsistenz mit <code>dim_date</code>, NOT-NULL-Constraints, Revenue-Share-Genauigkeit (Summe der Anteile entspricht dem Gesamtumsatz pro Kauf innerhalb der Rundungstoleranz) sowie Zeilenanzahl-Vergleiche mit Silver-Quelltabellen.</p>

<p><b>Gold — Attribution mit Kosten:</b> Das DDL-Skript für <code>fact_attribution_linear_with_costs</code> enthält integrierte Qualitätschecks für den Zeilenanzahl-Vergleich mit der Originaltabelle, den Prozentsatz der Kostenattributions-Abdeckung, die Plausibilität von Gesamtumsatz vs. Gesamtkosten sowie die Aufschlüsselung der Kostenattribution nach Kanal.</p>

<hr>

<h4>2.7) Ausführungsreihenfolge</h4>

<table>
  <thead>
    <tr>
      <th>#</th>
      <th>Skript</th>
      <th>Zweck</th>
    </tr>
  </thead>
  <tbody>
    <tr><td>1</td><td><code>init_database.sql</code></td><td>Datenbank und Schemas anlegen (bronze, silver, gold)</td></tr>
    <tr><td>2</td><td><code>ddl_bronze.sql</code></td><td>Bronze-Tabellen erstellen</td></tr>
    <tr><td>3</td><td><code>proc_load_bronze.sql</code></td><td>Erstellen und ausführen: <code>EXEC bronze.load_bronze</code></td></tr>
    <tr><td>4</td><td><code>profile_clean_mrkt_*.sql</code></td><td>Datenprofiling (informativ, nicht für den Ladevorgang erforderlich)</td></tr>
    <tr><td>5</td><td><code>ddl_silver.sql</code></td><td>Silver-Tabellen erstellen</td></tr>
    <tr><td>6</td><td><code>proc_load_silver.sql</code></td><td>Erstellen und ausführen: <code>EXEC silver.load_silver</code></td></tr>
    <tr><td>7</td><td><code>quality_checks_silver.sql</code></td><td>Silver Layer validieren</td></tr>
    <tr><td>8</td><td><code>ddl_gold_dim.sql</code></td><td>Dimensionstabellen erstellen und befüllen</td></tr>
    <tr><td>9</td><td><code>quality_checks_dim.sql</code></td><td>Dimensionen validieren</td></tr>
    <tr><td>10</td><td><code>ddl_gold_fact.sql</code></td><td>Kern-Faktentabellen erstellen und befüllen</td></tr>
    <tr><td>11</td><td><code>quality_checks_fact.sql</code></td><td>Kern-Faktentabellen validieren</td></tr>
    <tr><td>12</td><td><code>ddl_gold_fact_multi_touch.sql</code></td><td>Touchpath- und Attributionstabellen erstellen</td></tr>
    <tr><td>13</td><td><code>quality_checks_fact_multi_touch.sql</code></td><td>Attributionstabellen validieren</td></tr>
    <tr><td>14</td><td><code>ddl_gold_fact_attribution_with_costs.sql</code></td><td>Kostenerweiterte Attribution erstellen</td></tr>
  </tbody>
</table>

<hr>

<h4>2.8) Technische Umgebung</h4>

<table>
  <thead>
    <tr>
      <th>Merkmal</th>
      <th>Wert</th>
    </tr>
  </thead>
  <tbody>
    <tr><td>Datenbank</td><td>SQL Server (T-SQL)</td></tr>
    <tr><td>Lademuster</td><td>Full Load, Truncate and Insert (kein inkrementelles Laden / CDC)</td></tr>
    <tr><td>Datenzeitraum</td><td>Januar – April 2024 (Kampagnen- und Transaktionsdaten), Kalenderdimension: 2023–2024</td></tr>
    <tr><td>Umfang</td><td>~8.500 User · ~3.500 Käufe · ~87.000 Touchpoints · ~70.000 Klicks · 53 Kampagnen · 9 Kanäle</td></tr>
  </tbody>
</table>
