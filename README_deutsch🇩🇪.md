# Marketing-Analytics-DWH
<h3>End-to-End Data Warehouse (Bronze/Silver/Gold) mit Multi-Touch-Attribution und Tableau-Dashboards</h3>
<p>
   📍 Info: Dieses Demo-Projekt dient der <strong>Demonstration von Fähigkeiten</strong> und verwendet <strong>synthetisch generierte Daten</strong>.<br>
   👉 Für die Detailansicht der interaktiven Dashboards auf <strong>Tableau Public</strong>, bitte auf das jeweilige Bild klicken.
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
    │                         12 (Dashboard-Views)           
    │
    └────────────── results/ · performance_analysis/ · path_length_and_channel_efficiency/
</pre>

<h2>1) Marketing-Analyse</h2>
<p>Aufgabe ist die Analyse von Werbedaten aus Januar bis April 2024. Ich beginne mit der Stakeholder-Kommunikation und der Präsentation der Analyseergebnisse. <a href="#2-end-to-end-data-warehouse-und-etl">Abschnitt 2</a> behandelt den Datenüberblick, die ETL-Pipeline und den Data-Warehouse-Aufbau.</p>

### 1.1) Executive Summary

Die analysierten Multi-Touch-Marketingdaten über 9 Kanäle, 53 Kampagnen, ~8.500 Nutzer und 87.000+ Touchpoints (Januar–April 2024) zeigen fünf zentrale Erkenntnisse:

**1. Alle Paid-Kanäle folgen einem Launch → Sättigungs-Muster.** Der MOFU-ROAS im Januar lag zwischen 4,3x und 4,7x; bis April waren alle Kanäle unter 1,3x gefallen — ein Rückgang von bis zu 77%. Das deutet auf Zielgruppensättigung, nachlassende Werbewirksamkeit und steigenden Wettbewerb hin. Entscheidend: Dieser Rückgang hätte ohne die Kosten-Attributionskorrektur, die ich während der Entwicklung gebaut habe, nicht korrekt pro Funnel-Stufe analysiert werden können (siehe [Abschnitt 2.5](#25-warum-fact_attribution_linear_with_costs-existiert)).

**2. Instagram Ads ist der konsistenteste Performer über alle Metriken.** Niedrigster CPM, bestes CPM-zu-CVR-Effizienzverhältnis und stärkste BOFU-Closing-Verbesserung im April (+28,7% CVR MoM). LTV:CAC von 3,3 platziert Instagram in der Top-Tier neben Google Search (3,2) und Google Display (3,4). Instagram ist der einzige Paid-Kanal, der über Kosteneffizienz, LTV:CAC Verhältnis und einem Closing mit April-Rebound hinweg in der Top-Tier performt — allerdings bei geringerem Volumen als andere Kanäle.

**3. Google Search (der Premium-Kanal) und Google Display rechtfertigen ihre Kosten durch unterschiedliche Stärken.** Google Search hat den höchsten absoluten LTV (€53,20), das stärkste Revenue-Ranking über alle Attributionsmodelle (zweimal #1, zweimal #2) und die beste Lead-Qualität. Google Display führt beim LTV:CAC (3,4) trotz der schwächsten Engagement-Metriken (niedrigste Klickrate). Es schließt Conversions ab, die andere Kanäle initiieren — der einzige Paid-Kanal mit positiver TOFU-BOFU-Revenue-Differenz (+€2,4K).

**4. TikTok Ads treibt Neukundenakquise, nicht Lifetime Value.** Niedrigster absoluter LTV (€41,7), kürzeste Last-Touch-Pfade (1,76 Touchpoints im Durchschnitt) und die niedrigste BOFU-Conversion-Rate im April (2,03%). TikTok konvertiert schnell, wenn es konvertiert — aber es konvertiert selten, und die gewonnenen Nutzer sind langfristig am wenigsten wertvoll.

**5. Facebook Ads ist der konstante Underperformer.** Letzter oder vorletzter Platz im Revenue-Ranking über alle Attributionsmodelle (3x letzter, 1x vorletzter), schlechteste Lead-Qualität und schwächste Closing-Effizienz unter den Paid-Kanälen. Der CAC von €15,0 ist der zweithöchste, aber anders als Google Search (€16,5 CAC; €53,2 LTV) kompensiert Facebook nicht mit höherem Lifetime Value (€44,2). Facebook kostet fast so viel wie der Premium-Kanal, liefert aber die schwächste Revenue-Performance.

> _Hinweis: Diese Analyse verwendet synthetisch generierte Daten. Absolute Werte dienen als Demonstrationsrahmen; relative Vergleiche zwischen Kanälen und Kampagnen sind analytisch valide. Spezifische Datenlimitierungen werden inline in der gesamten Analyse vermerkt._

---

### 1.2) Funnel-basierte Performance-Analyse

Die Analyse differenziert drei Funnel-Stufen, die jeweils mit einem dedizierten Attributionsmodell ausgewertet werden, um Geschäftsfragen der passenden Messperspektive zuzuordnen.

| Funnel-Stufe | Attributionsmodell | Geschäftsfrage |
|---|---|---|
| **TOFU** — Aufmerksamkeitseffizienz | First-Touch | Welche Kanäle erzeugen effizient qualifizierte Awareness? |
| **MOFU** — Intent- & Conversionseffizienz | Linear (Multi-Touch) | Welche Kanäle tragen zur gesamten Conversion-Journey bei? |
| **BOFU** — Profitabilität & Langzeitwachstum | Last-Touch | Welche Kanäle erfassen Wert und treiben nachhaltigen Umsatz? |

---

#### 1.2.1) Aufmerksamkeitseffizienz (TOFU)

**Ziel:** Effizient qualifizierte Awareness und Traffic generieren.

**Kernerkenntnis:** Instagram Ads liefert die kosteneffizienteste Reichweite über alle Aufmerksamkeitsmetriken, während Google Search einen Premium-Preis verlangt, den seine Conversion-Qualität teilweise rechtfertigt.

<table align="center">
  <thead>
    <tr><th>Kanal</th><th>Ø CPC</th><th>CTR Rang</th><th>CPM-zu-CVR-Verhältnis</th><th>Effizienz</th></tr>
  </thead>
  <tbody>
    <tr><td>Instagram Ads</td><td>€0,89</td><td>#1</td><td>1.856</td><td>Hoch</td></tr>
    <tr><td>TikTok Ads</td><td>€0,94</td><td>#4</td><td>1.966</td><td>Hoch</td></tr>
    <tr><td>Google Display</td><td>€0,98</td><td>#5</td><td>2.078</td><td>Mittel</td></tr>
    <tr><td>Google Search</td><td>€1,15</td><td>#2</td><td>2.149</td><td>Mittel</td></tr>
    <tr><td>Facebook Ads</td><td>€1,04</td><td>#3</td><td>2.365</td><td>Niedrig</td></tr>
  </tbody>
</table>

Das CPM-zu-CVR-Effizienzverhältnis kombiniert Reichweitenkosten mit Conversion-Qualität und liefert eine zusammengesetzte Metrik, die nicht vom monatlichen Spend-Verteilungsartefakt betroffen ist. Instagram gewinnt beide Dimensionen — günstigste Reichweite und starke Conversion-Qualität — während Facebook mehr für Reichweite bezahlt, mit schwächerer Nachfolge.

**TikToks Akquisitionssignal:** Von TikTok akquirierte Nutzer zeigen die kürzesten First-Purchase-Pfade über alle Monate (8,36 Touchpoints im Durchschnitt im April vs. 9,23 bei Instagram), was auf Zielgruppen mit hoher sofortiger Kaufabsicht hindeutet. Allerdings hat diese Geschwindigkeit ihren Preis — TikToks LTV ist der niedrigste unter den Paid-Kanälen (€41,70), was darauf hindeutet, dass schnelle Konvertierer nicht unbedingt langfristig wertvolle Kunden sind.

> _Hinweis: CTR-Werte übersteigen 100% aufgrund synthetischer Daten (Klicks > Impressions) und sollten als Klickintensität gelesen werden. Relative Kanalvergleiche bleiben valide, obwohl die Differenzierung minimal ist (3,5% Gesamtspanne). Monatliche CAC/CPC/CPM-Trends spiegeln sinkende synthetische Ausgaben wider, nicht reale Effizienzgewinne. Kanalübergreifende Vergleiche bleiben valide._

---

#### 1.2.2) Intent- & Conversionseffizienz (MOFU)

**Ziel:** Die gesamte Customer Journey bewerten — wie effizient wandeln Touchpoints Aufmerksamkeit in Umsatz um?

**Kernerkenntnis:** Bis April fällt jeder Paid-Kanal unter die 1,5x-Profitabilitätsschwelle (Break-Even ROAS) bei Betrachtung der gesamten Customer Journey. Alle Kanäle starten profitabel im Januar (4,3–4,7x), verlieren aber 70–77% ihres MOFU-ROAS innerhalb von vier Monaten — was die Zielgruppensättigung nicht nur am oberen Ende des Funnels, sondern über den gesamten Conversion-Pfad hinweg bestätigt. Dies ist das stärkste Signal in den Daten, dass fortgesetzte Ausgaben auf aktuellem Niveau ohne neue Zielgruppenstrategien oder Kanaldiversifikation nicht tragbar sind.

Diese Analyse stützt sich auf `fact_attribution_linear_with_costs`, die sowohl Umsatz *als auch* Kosten gleichmäßig auf alle Touchpoints einer konvertierenden Journey verteilt — eine Tabelle, die ich gebaut habe, nachdem ich entdeckte, dass das Standard-Linear-Modell Kosten auf Funnel-Stufen-Ebene nicht attribuiert hatte (siehe [Abschnitt 1.3](#13-attributions-insights)).

**Gesamt-MOFU-ROAS:** 2,12x (€147.679 Umsatz / €69.607 attribuierte Kosten)

**MOFU-ROAS nach Kanal (Januar–April 2024):**

<p align="center"><img src="https://github.com/user-attachments/assets/696d1550-45a5-4a1b-bf3b-b1f01ee9442d" alt="MOFU ROAS nach Kanal" width="100%" height="460"></p>

**120-Tage MOFU-ROAS-Werte (abst.):** Google Display 2,20x, Facebook Ads 2,15x, TikTok Ads 2,11x, Google Search 2,09x, Instagram Ads 2,07x

März ist der Kipppunkt: Google Search (1,56x) und TikTok Ads (1,67x) fallen bereits unter die 1,5x-Schwelle, während die übrigen Kanäle im April folgen. Facebook Ads zeigt die widerstandsfähigste April-Performance (1,28x) — immer noch unprofitabel, aber am langsamsten im Verfall. Die 120-Tage-Aggregate (2,07–2,20x) bleiben über der Schwelle, weil die starke Januar- und Februar-Performance den April-Einbruch maskiert.

**Pfadlänge und der Vertrauenseffekt:** Der durchschnittliche konvertierende Nutzer interagiert mit 5 Touchpoints vor dem Kauf bei einem durchschnittlichen Bestellwert (AOV) von €153,30. Wiederkaufende Kunden benötigen über alle Monate hinweg etwa 30% weniger Touchpoints als Erstkäufer (z.B. April: 4,31 Touchpoints im Durchschnitt für 250 Wiederholungskäufe vs. 8,90 für 555 Erstkäufe), was den Vertrauenseffekt validiert. Der Anteil der Wiederholungskäufe wächst von 4,4% im Januar auf 31,1% im April und baut eine stabile Repeat-Purchase-Engine auf, obwohl das Gesamtkaufvolumen sinkt (908 → 805).

> _Hinweis: Monatliche MOFU-CVR- und AOV-Trends zeigen einheitliche Wachstums-/Rückgangskurven über alle Kanäle. Dies ist ein Artefakt synthetischer Daten — die generierten Daten produzieren nahezu identische Engagement-Volumen über die Kanäle, was zu parallelen Trendlinien führt, die bei realen Daten divergieren würden. Vergleiche innerhalb eines Monats bleiben valide._

---

#### 1.2.3) Profitabilität & Langzeitwachstum (BOFU)

**Ziel:** Umsatz maximieren und nachhaltiges, profitables Wachstum treiben.

**Kernerkenntnis:** Während der MOFU-ROAS bis April unter die Profitabilitätsschwelle einbricht, erzählt der BOFU (Last-Touch-Attribution) eine andere Geschichte: Der Closing-Mechanismus funktioniert noch. Die BOFU-CVR stabilisiert sich bei ~2,3% nach einem anfänglichen Anstieg — das Problem ist nicht die Conversionseffizienz, sondern die Zielgruppenerschöpfung weiter oben im Funnel. Die 120-Tage-LTV-Analyse bestätigt, dass drei von fünf Paid-Kanälen im gesunden 3–5x LTV:CAC-Band operieren, wobei Google Search den höchsten absoluten Lifetime Value (€53,19) und Google Display das beste Effizienzverhältnis (3,43) liefert.

**Monatlicher BOFU-ROAS (Last-Touch-Attribution, Paid-Kanäle):**

<table align="center">
   <thead>
    <tr><th>Kanal</th><th>Jan</th><th>Feb</th><th>Mär</th><th>Apr</th></tr>
   </thead>
   <tbody>
    <tr><td>Google Search</td><td>7,85x</td><td>6,40x</td><td>4,05x</td><td>1,97x</td></tr>
    <tr><td>TikTok Ads</td><td>6,61x</td><td>5,73x</td><td>5,33x</td><td>4,57x</td></tr>
    <tr><td>Instagram Ads</td><td>6,30x</td><td>4,67x</td><td>3,83x</td><td>4,19x</td></tr>
    <tr><td>Facebook Ads</td><td>5,96x</td><td>5,85x</td><td>4,28x</td><td>4,27x</td></tr>
    <tr><td>Google Display</td><td>5,07x</td><td>6,29x</td><td>5,70x</td><td>2,93x</td></tr>
   </tbody>
</table>

BOFU-ROAS-Werte sind höher als MOFU, weil Last-Touch-Attribution den gesamten Credit auf den letzten konvertierenden Touchpoint konzentriert. Das Rückgangsmuster unterscheidet sich nach Kanal: Google Search fällt am stärksten (7,85x → 1,97x, −75%), während TikTok Ads (4,57x) und Facebook Ads (4,27x) die stärkste April-Resilienz zeigen. Instagram ist der einzige Kanal mit einem April-Rebound (3,83x → 4,19x, +9,5%).

**BOFU-CVR-Stabilisierung:**

<img width="100%" height="742" alt="bofu_cvr_by_channel" src="https://github.com/user-attachments/assets/b01bf06d-14c5-4df9-a94c-8b7fab4f5a99" />

Über alle Paid-Kanäle hinweg springt die BOFU-CVR von 1,43% im Januar auf 2,59% im Februar und stabilisiert sich dann bei etwa 2,3–2,4% im März und April. Dieses Plateau signalisiert, dass die Closing-Effizienz sich nicht verschlechtert — der Funnel konvertiert mit einer konstanten Rate, sobald Nutzer den unteren Bereich erreichen. Der in der BOFU-ROAS sichtbare Umsatzrückgang wird dadurch getrieben, dass weniger Nutzer in den Funnel eintreten, nicht durch nachlassende Conversion am Ausgang.



**120-Tage LTV nach Kanal (Alle Kohorten, Dashboard-Aggregate):**

<table>
  <tr>
    <td>
      <table>
        <thead>
          <tr><th>Kanal</th><th>LTV (120T)</th><th>CAC</th><th>LTV:CAC</th></tr>
        </thead>
        <tbody>
          <tr><td>Google Display</td><td>€48,95</td><td>€14,26</td><td>3,43</td></tr>
          <tr><td>Instagram Ads</td><td>€43,55</td><td>€13,36</td><td>3,26</td></tr>
          <tr><td>Google Search</td><td>€53,19</td><td>€16,48</td><td>3,23</td></tr>
          <tr><td>TikTok Ads</td><td>€41,66</td><td>€14,02</td><td>2,97</td></tr>
          <tr><td>Facebook Ads</td><td>€44,24</td><td>€14,97</td><td>2,95</td></tr>
        </tbody>
      </table>
    </td>
    <td>
      <img src="https://github.com/user-attachments/assets/9cc49b57-6129-411f-9c23-ba1d9bead2c0" alt="LTV vs. CAC nach Kanal" width="900">
    </td>
  </tr>
</table>

Google Display, Instagram Ads und Google Search operieren alle im gesunden 3–5x-Band. Google Search rechtfertigt den höchsten CAC (€16,48) mit dem höchsten absoluten LTV (€53,19) — es akquiriert die wertvollsten Kunden. Google Display erreicht das beste Verhältnis (3,43) durch eine günstige Kombination aus überdurchschnittlichem LTV (€48,95, nur hinter Google Search) und unterdurchschnittlichem CAC (€14,26). TikTok und Facebook liegen im Monitor-Band: nicht unprofitabel, aber ihr Pro-Nutzer-Wert rechtfertigt keine aggressive Skalierung.

**Instagrams April-Signal:** Instagram ist der einzige Paid-Kanal, bei dem die BOFU-CVR im April steigt (+28,7% MoM, von 1,98% auf 2,55%). In Kombination mit dem April-BOFU-ROAS-Rebound (+9,5%) zeigt Instagram antizyklische Closing-Stärke — es performt besser, während andere Kanäle sich verschlechtern, was darauf hindeutet, dass seine Zielgruppe weniger gesättigt oder reaktionsfreudiger in Spätphasen-Bedingungen ist.

> _Hinweis: Zu Visualisierungszwecken habe ich ein LTV- & Kohortenanalyse-Dashboard gebaut, das <a href="https://public.tableau.com/views/Multi-TouchMarketingDashboard/Overall2?:language=de-DE&:sid=&:redirect=auth&:display_count=n&:origin=viz_share_link">hier</a> eingesehen werden kann. Die 120-Tage-LTV-Kohortengrößen sind stark verzerrt (Jan: 93%, Feb: 6,8%, Mär: 0,5%) aufgrund der synthetischen Datengenerierung. Kohortenübergreifende Vergleiche sind nicht interpretierbar; die obige LTV-Tabelle verwendet Alle-Kohorten-Aggregate, um diese Limitation zu umgehen. Die Kaufrate der Januar-Kohorte bleibt über vier Monate bei ~10% pro Monat stabil, was eine starke Retention für ein Nicht-Abonnement-E-Commerce-Modell anzeigt._

---

### 1.3) Attributions-Insights

Multi-Touch-Attribution enthüllt Kanaldynamiken, die Single-Touch-Modelle nicht erfassen können.

#### Assisting- vs. Closing-Rollen

Der Vergleich von First-Touch- und Last-Touch-Revenue pro Kanal zeigt ein klares Spektrum: TikTok Ads (−€5,2K) und Facebook Ads (−€4,2K) generieren deutlich mehr Akquisitions-Revenue als Closing-Revenue — sie initiieren Journeys, die andere Kanäle abschließen. Google Search liegt nahezu ausgeglichen (−€0,2K) und performt an beiden Enden gleich gut. Die Überraschung ist Google Display (+€2,4K): der einzige Kanal, der mehr abschließt als er initiiert, und als stiller Konvertierer für Traffic agiert, den andere Kanäle herangebracht haben.

**TOFU vs. BOFU Revenue (€) nach Kanal (Januar–April 2024):**

<img width="100%" height="713" alt="tofu_bofu_revenue_gap" src="https://github.com/user-attachments/assets/4e177ee0-8cb3-43c0-b764-40b3968c360b" />

#### Was ich beim Aufbau der Kosten-Attribution gelernt habe

Die bedeutsamste Erkenntnis dieses Projekts ergab sich aus einer Limitation, die ich während der Entwicklung entdeckte. Die ursprüngliche `fact_attribution_linear`-Tabelle verteilt Revenue gleichmäßig auf alle Touchpoints einer konvertierenden Journey — Standardpraxis für Multi-Touch-Attribution. Aber als ich die Tableau-Dashboards baute und Funnel-Stufen-Filter anwendete, stimmten die Zahlen nicht: MOFU-gefilterte Ansichten zeigten Revenue nur von Mid-Funnel-Touchpoints, während die Kosten weiterhin _alle_ Touchpoints widerspiegelten. Der ursprüngliche Ansatz summierte Spend ohne Funnel-Stufen-Differenzierung und blähte den ROAS-Nenner für jede gefilterte Ansicht auf. Dadurch erschienen gefilterte ROAS-Werte deutlich schlechter als sie tatsächlich waren.

Die Ursache war eine Granularitäts-Diskrepanz. Revenue war auf einzelne Touchpoints attribuiert worden, aber die Kosten blieben auf der aggregierten Kampagnen-Tages-Ebene in `fact_spend`. Einen direkten Join dieser beiden Tabellen zu machen, produziert verzerrte Ergebnisse, weil die Zeilenstrukturen nicht übereinstimmen.

Meine Lösung war `fact_attribution_linear_with_costs` — eine neue Tabelle, die Kosten proportional neben dem Revenue verteilt, sodass jeder Touchpoint sowohl einen `revenue_share` als auch einen `cost_share` erhält. Die technischen Details sind in [Abschnitt 2.5](#25-warum-fact_attribution_linear_with_costs-existiert) dokumentiert.

#### Pfadlänge prognostiziert keinen Umsatz

Die Korrelation zwischen Pfadlänge und Kaufumsatz ist praktisch null (r = −0,00028). Kurze Pfade (1–7 Touchpoints) und lange Pfade (8+ Touchpoints) produzieren nahezu identische durchschnittliche Bestellwerte (~€135 vs. ~€133). Das stellt die Annahme in Frage, dass „mehr Touchpoints = höherer Warenkorbwert" und legt nahe, dass effizientes, gezieltes Journey-Design wichtiger ist als die Maximierung des Touchpoint-Volumens.

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

Siehe 05_magnitude_analysis.sql für Query Nr. 10.14) Korreliert die Touchpoint-Nummer (Position in der Journey) mit dem Umsatz?
      und Queries Nr. 10.15) Sind kürzere oder längere Journeys mit höherwertigen Käufen verbunden?

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

### 1.4) Strategische Empfehlungen

Basierend auf den Analyseergebnissen legen die Daten folgende Maßnahmen für ein Marketingteam in diesem Szenario nahe.

**Das Sättigungsmuster adressieren.** Bis April fällt jeder Paid-Kanal unter die 1,5x-Profitabilitätsschwelle über die gesamte Customer Journey (MOFU-ROAS), mit Rückgängen von 70–77% gegenüber den Januar-Spitzenwerten. Dies ist das dringendste Signal in den Daten. Die Antwort umfasst zwei Hebel: Auffrischung der Werbemittel zur Bekämpfung der Zielgruppen-Ermüdung und Erweiterung des Targetings, um neue Zielgruppensegmente zu erreichen, bevor bestehende Pools vollständig erschöpft sind.

**Budget von Facebook zu Instagram und Google Display umschichten.** Facebook underperformt über mehrere Dimensionen hinweg ohne kompensatorische Stärke: schlechtestes CPM-zu-CVR-Verhältnis im TOFU, eine −€4,2K TOFU-BOFU-Revenue-Differenz, die zeigt, dass es Conversions initiiert, die es selten abschließt, und LTV:CAC im Monitor-Band (2,95) — ähnlich wie TikTok (2,97), aber anders als TikTok trägt Facebook kein bedeutendes Akquisitionsvolumen am oberen Ende des Funnels bei. Instagram und Google Display liegen beide im gesunden LTV:CAC-Band (3,26 und 3,43) und ergänzen sich in ihren Profilen — Instagram liefert die kosteneffizienteste Reichweite und die stärkste Spätphasen-Closing-Performance, während Google Display das beste Verhältnis durch eine günstige Kombination aus überdurchschnittlichem LTV und unterdurchschnittlichem CAC erreicht.

**Kanäle nach Funnel-Rolle bewerten, nicht nach Single-Model-Metriken.** Die Attributionsanalyse zeigt, dass Kanäle als Ökosystem funktionieren. Google Display hat die schwächsten Engagement-Metriken (niedrigste CTR, rückläufige Klicks) und wäre ein natürlicher Kandidat für Budgetkürzungen basierend auf TOFU-Performance allein — dennoch ist es der einzige Kanal, der mehr Revenue abschließt als er initiiert (+€2,4K Differenz). Display zu kürzen würde den effektivsten stillen Closer des Funnels entfernen. Jeder Kanal sollte an der Metrik gemessen werden, die seiner Funnel-Rolle entspricht.

**Retention priorisieren — 81% der Kunden kaufen nur einmal.** Dies ist der größte einzelne Wachstumshebel in den Daten. Wiederkaufende Kunden benötigen etwa 30% weniger Touchpoints als Erstkäufer, und der Anteil der Wiederholungskäufe wächst von 4,4% im Januar auf 31,1% im April — was beweist, dass sich organisch bereits eine Retention-Engine bildet. Investitionen in Post-Purchase-Journeys und Re-Engagement-Kampagnen würden diesen Effekt zu niedrigeren Kosten pro Conversion beschleunigen als Neukundenakquise.

<p align="center">
   <img width="586" height="265" alt="Wiederholungskauf-Wachstum" src="https://github.com/user-attachments/assets/167efc2c-129a-4be0-9406-bbb32b64bf03" />
</p>

---

### 1.5) Limitierungen & Annahmen

**Synthetische Daten:** Alle Erkenntnisse basieren auf synthetisch generierten Daten mit absichtlichen Qualitätsproblemen zur ETL-Demonstration. Kanal-Engagement-Volumen sind unrealistisch einheitlich (Klicks, Impressions und Touchpoints sind nahezu identisch über die Kanäle), was das Differenzierungspotenzial einschränkt, das reale Daten bieten würden.

**Monatliche Spend-Verteilung:** Der Roh-Spend bricht von €41.541 (Januar) auf €1.134 (April) ein — ein Rückgang von 97,3%. Dies ist ein Datengenerierungsartefakt, keine reale Budgetentscheidung. Monatliche kostenbasierte Trends (ROAS, CAC, CPA, CPC, CPM) sind von diesem Artefakt betroffen. Kanalübergreifende und kampagnenübergreifende relative Vergleiche innerhalb desselben Zeitraums sowie Gesamtzeitraum-Aggregate bleiben valide.

**Kohorten-Ungleichgewicht:** 93% der Nutzer werden im Januar akquiriert. Februar- und März-Kohorten sind zu klein für statistisch zuverlässige kohortenübergreifende Vergleiche. Die Within-Januar-Analyse ist robust.

**CPM- und CTR-Limitation:** CPM-Werte sind unrealistisch hoch (>€4.053 vs. typische €5–30) aufgrund niedriger synthetischer Impression-Volumen. Absolute CPM-Werte sind nicht benchmarkbar; das CPM-zu-CVR-Verhältnis aggregiert über Monate und ist nicht betroffen. Ebenso produzieren niedrige Impression-Volumen CTR-Werte über 100% (~244%), die als Klickintensität statt als wörtliche Conversion-Raten gelesen werden sollten. Kanalübergreifende Vergleiche bleiben valide.

---

### 1.6) Taktischer Drill-Down (Dashboards)

Während strategische Schlussfolgerungen auf Kanal-Ebene in diesem README gezogen werden, sind kampagnenbezogene KPIs im interaktiven Budget-Allocation-Dashboard für taktische Optimierung und Drill-Down verfügbar (klicken Sie auf das Bild, um es auf der Website von **Tableau Public** genauer anzusehen).

<p align="center">
  <a href="https://public.tableau.com/views/Multi-TouchMarketingDashboard/Overall?:language=de-DE&:sid=&:redirect=auth&:display_count=n&:origin=viz_share_link">
    <img src="https://github.com/user-attachments/assets/374a6cf6-2f55-4d5a-a97c-fd4636b1c662" width="100%" alt="Budget Allocation Dashboard"/>
  </a>
</p>

Die Dashboards ermöglichen:

- **Kampagnen-Ranking und -Filterung** — Sortierung nach Revenue, ROAS, CPA, CVR über alle 53 Kampagnen
- **Funnel-Stufen-Aufschlüsselung** — filterbare Funnel-Stufen-Ansichten (TOFU/MOFU/BOFU) pro Kampagne und korrekte Kosten-Attribution auf jeder Stufe
- **Kanal-Filterlogik** — Durch Klick auf einen Kanal in einer der anderen Visualisierungen wird der Kampagnen-Drill-Down entsprechend dem ausgewählten übergeordneten Kanal gefiltert
- **Trend-Monitoring** — monatliche Performance-Verfolgung zur Identifikation von Sättigungs- und Interventionssignalen

> _Hinweis zu Spend: Die KPI-Zeile zeigt ACTUAL SPEND (wann Geld ausgegeben wurde) aus gold.fact_spend. gold.roas zeigt ATTRIBUTED SPEND (Spend verknüpft mit Conversions) — unterschiedliches Konzept!_

---

### 1.7) Was ich als Nächstes tun würde

Dies sind die Richtungen, die ich mit realen Produktionsdaten und einem längeren Zeithorizont erkunden würde.

**Zusätzliche Attributionsmodelle.** Das lineare Modell verteilt Credit gleichmäßig, was eine bewusste Vereinfachung ist. Der nächste Schritt wäre die Implementierung von Time-Decay-Attribution (höhere Gewichtung neuerer Touchpoints) und positionsbasierter Attribution (Betonung des ersten und letzten Touchs). Der Vergleich aller Modelle nebeneinander für dieselben Daten würde zeigen, wo sie übereinstimmen (robuste Erkenntnisse) und wo sie divergieren (Bereiche, die genauere Untersuchung erfordern). Ich würde auch verstehen wollen, wann lineare Attribution „gut genug" ist versus wann ein komplexeres Modell reale Budgetentscheidungen verändern würde.

**Kausalitätstests durch Holdout-Experimente.** Multi-Touch-Attribution zeigt, welche Kanäle _neben_ Conversions _erscheinen_ — aber sie kann nicht beweisen, dass ein Kanal die Conversion tatsächlich _verursacht_ hat. Ein Nutzer, der auf eine Google-Search-Anzeige klickt, hätte möglicherweise ohnehin gekauft. Der Standardprozess wäre Incrementality Testing (Holdout-Experimente): Anzeigen für eine zufällige Nutzergruppe unterdrücken und ihre Conversion-Rate mit der exponierten Gruppe vergleichen. Das ist etwas, das ich noch nicht gebaut habe, aber es ist die logische nächste Frage nach der Attribution — und die Frage, die ich in einem echten Marketingteam beantworten wollen würde.

**Längeres LTV-Fenster und Retention-Modellierung.** Der aktuelle 120-Tage-LTV erfasst frühes Wiederkaufverhalten, aber wahrer Customer Lifetime Value erfordert 12–24 Monate Daten. Mit einem längeren Zeithorizont könnte man Kundensegmentierung basierend auf Kaufaktualität, -häufigkeit und -wert (RFM-Analyse) aufbauen, um zu identifizieren, welche Nutzersegmente die meiste Retention-Investition verdienen. Die 81%-Einmalkäufer-Rate ist der offensichtlichste Ausgangspunkt — zu verstehen, _warum_ diese Nutzer nicht zurückkehren, ist mehr wert als zu optimieren, welcher Kanal sie akquiriert.

**Von Batch- zu inkrementeller Verarbeitung.** Das aktuelle Warehouse ([Abschnitt 2.1](#21-architektur)) verwendet ein Full-Load-, Truncate-and-Insert-Muster. Das ist angemessen für ein Demo-Projekt, aber in der Produktion würde ich inkrementelles Laden (nur neue oder geänderte Datensätze), automatisierte Qualitätsprüfungen bei jedem Load und Alerting, wenn Schlüsselmetriken sich außerhalb erwarteter Bereiche bewegen, haben wollen. Das Ziel: Ein Sättigungsmuster wie das in diesen Daten im Februar sofort erkennen, nicht nach vier Monaten Batch-Analyse.

<hr>

<h2 id="2-end-to-end-data-warehouse-und-etl">2) End-To-End Data Warehouse und ETL</h2>
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

