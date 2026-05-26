# ✈️ Airline Pricing & Revenue Intelligence System

> An end-to-end data analytics project analysing 15,000+ domestic flight records to uncover pricing patterns, route competitiveness, and revenue optimisation opportunities across 10 airlines and 380 routes.

---

## 📌 Table of Contents

- [Project Overview](#project-overview)
- [Business Problem](#business-problem)
- [Dataset](#dataset)
- [Tools & Technologies](#tools--technologies)
- [Project Architecture](#project-architecture)
- [Phase 1: Data Foundation (Excel)](#phase-1-data-foundation-excel)
- [Phase 2: Relational Modelling & SQL Analysis](#phase-2-relational-modelling--sql-analysis)
- [Phase 3: Power BI Dashboard](#phase-3-power-bi-dashboard)
- [Phase 4: Python Analysis & Prediction](#phase-4-python-analysis--prediction)
- [Key Findings](#key-findings)
- [Star Schema Design](#star-schema-design)
- [Project Structure](#project-structure)
- [How to Run This Project](#how-to-run-this-project)
- [Limitations & Future Scope](#limitations--future-scope)
- [Author](#author)

---

## Project Overview

This project simulates a real-world business intelligence engagement for a domestic airline analytics team. Starting from a raw, uncleaned CSV file, the project walks through every stage of the analytics pipeline — data cleaning, relational modelling, SQL analysis, interactive dashboarding, and machine learning — to answer one central business question:

> **"What drives ticket prices, and how can an airline optimise its route and pricing strategy?"**

---

## Business Problem

Domestic airline pricing is influenced by dozens of variables — route distance, stop count, departure timing, seasonality, and competitive pressure. Without structured analysis, airlines risk underpricing high-demand routes and overpricing others, leading to revenue leakage and poor customer retention.

This project addresses three specific business questions:

1. **Pricing Drivers** — Which factors most strongly determine ticket price?
2. **Route Competitiveness** — On each route, which airline offers the best value and by what margin?
3. **Revenue Opportunities** — Which routes are underpriced relative to their demand and convenience profile?

---

## Dataset

| Property | Detail |
|---|---|
| **Source** | Domestic Indian flight dataset |
| **Rows** | ~15,000 flight records |
| **Airlines** | 10 (IndiGo, Air India, SpiceJet, Vistara, GoAir, AirAsia India, Star Air, Akasa Air, Alliance Air, TruJet) |
| **Routes** | 380 unique source-destination combinations |
| **Date Range** | 2019 – 2025 (2,350 unique journey dates) |
| **Cities** | 20 source cities, 20 destination cities |

### Raw Columns

| Column | Description |
|---|---|
| `airline` | Airline name |
| `date_of_journey` | Date of travel (DD-MM-YYYY) |
| `source` | Departure city |
| `destination` | Arrival city |
| `route` | Full route string including stops |
| `dep_time` | Departure time |
| `arrival_time` | Arrival time |
| `duration` | Flight duration (text format) |
| `total_stops` | Number of stops (text) |
| `additional_info` | Extra flight information |
| `price` | Ticket price in INR |

---

## Tools & Technologies

| Tool | Purpose |
|---|---|
| **Microsoft Excel** | Data cleaning, derived columns, pivot analysis |
| **SQL Server (SSMS)** | Relational modelling, star schema, SQL analysis |
| **Power BI** | Interactive dashboard and business reporting |
| **Python** | EDA, feature engineering, price prediction model |
| **GitHub** | Version control and project documentation |

---

## Project Architecture

```
Raw CSV
   │
   ▼
Phase 1: Excel
   │  Data cleaning & validation
   │  Derived column engineering
   │  Exploratory pivot analysis
   │
   ▼
Phase 2: SQL Server
   │  Star schema design
   │  Staging → Dimension → Fact table pipeline
   │  Basic → Intermediate → Advanced SQL queries
   │
   ▼
Phase 3: Power BI
   │  3-page interactive dashboard
   │  DAX measures & KPIs
   │  Executive-level reporting
   │
   ▼
Phase 4: Python
      EDA & statistical validation
      Feature engineering
      Random Forest price prediction
      Feature importance analysis
```

---

## Phase 1: Data Foundation (Excel)

### Data Cleaning
- Removed duplicate rows and null values
- Standardised airline name variants (e.g. `Indigo` / `INDIGO` → `IndiGo`) using VLOOKUP mapping table
- Split the `Route` column into `Origin`, `Stop_1`, and `Destination` using Text to Columns
- Converted `Duration` text field into numeric `Duration_Mins`
- Flagged price anomalies: records below ₹500 or above ₹50,000 using conditional formatting and a `Price_Flag` helper column

### Derived Columns Engineered

| Column | Logic |
|---|---|
| `Duration_Mins` | Converted from text duration to numeric minutes |
| `Dep_Slot` | Early Morning / Morning / Afternoon / Evening / Night based on dep_time |
| `Stop_Category` | Non-stop / 1 Stop / 2+ Stops — cleaned version of total_stops |
| `Route_Type` | Domestic_Short (<120 mins) / Domestic_Long (≥120 mins) |
| `Price_Per_Min` | Price ÷ Duration_Mins — normalised cost metric |
| `Is_Weekend` | 1 if Saturday or Sunday, else 0 |
| `Month` | Numeric month extracted from date_of_journey |
| `Day_Of_Week` | Day name extracted from date_of_journey |
| `Price_Flag` | Normal / Outlier_Low / Outlier_High |

### Pivot Analysis Conducted
- Average price by airline
- Average price by route
- Price vs stop count
- Price vs departure slot
- Price vs duration bucket
- Weekend vs weekday price premium by airline
- 2D heatmap: departure slot × stop category

---

## Phase 2: Relational Modelling & SQL Analysis

### Star Schema Design

The flat CSV was normalised into a star schema with one fact table and three dimension tables:

```
                    dim_airline
                    ───────────
                    airline_id PK
                    airline_name
                         │
                         │
dim_date            fact_flights           dim_route
────────            ────────────           ─────────
date_id PK ◄──── date_id FK              route_id PK
full_date           flight_id PK    ────► source
month               airline_id FK   │     destination
month_name          route_id FK ────┘     route_type
day_of_week         dep_slot
is_weekend          stop_category
season              duration_mins
                    price
                    price_per_min
```

### SQL Analysis — Query Tiers

**Basic Queries**
- Total flights and average price per airline
- Route count per source city
- Average price by stop category

**Intermediate Queries (Window Functions)**
- Airline price rank per route using `RANK() OVER (PARTITION BY)`
- Month-over-month price change using `LAG()`
- Percentage of non-stop flights per airline using `CASE WHEN`

**Advanced Queries (CTEs)**
- Price anomaly detection — flights priced >2 standard deviations above route average
- Underpriced route identification — low price + high non-stop percentage
- Competitive pricing analysis — price premium per airline per route

---

## Phase 3: Power BI Dashboard

Three-page interactive report structured for executive consumption:

### Page 1 — Executive Overview
- KPI cards: Total Routes, Avg Ticket Price, Cheapest Airline, Priciest Route
- Bar chart: Average price by airline
- Slicer: Airline, Month, Stop Category

### Page 2 — Pricing Deep Dive
- Matrix heatmap: Airline × Departure Slot with conditional formatting
- Scatter plot: Duration vs Price coloured by airline
- Line chart: Average price by month (seasonality)
- Bar chart: Price by stop count

### Page 3 — Route Intelligence
- Top 10 most expensive routes
- Weekend vs weekday price premium comparison
- Route Competitiveness Score (custom DAX measure)

### Key DAX Measure
```dax
Route Competitiveness Score =
DIVIDE(
    AVERAGE(fact_flights[price]),
    CALCULATE(
        MIN(fact_flights[price]),
        ALLEXCEPT(fact_flights, fact_flights[route_id])
    )
)
-- Score of 1.0 = cheapest on route. Higher = more expensive vs cheapest.
```

---

## Phase 4: Python Analysis & Prediction

### Notebook Structure

**1. EDA & Statistical Validation**
- Price distribution (right-skewed → log transformed)
- Correlation heatmap of all numeric features
- Box plots: price by airline, stops, departure slot

**2. Feature Engineering**
- One-hot encoding: airline, source, destination, departure slot
- Ordinal encoding: stop count (0, 1, 2+)
- Label encoding: is_weekend

**3. Price Prediction Model**
- Algorithm: `RandomForestRegressor`
- Split: 80% train / 20% test
- Evaluation metrics: RMSE and R²

**4. Feature Importance**
- Identified top drivers of ticket price
- Results visualised as horizontal bar chart

---

## Key Findings

> ⚠️ Findings below are based on the dataset analysed. Actual values will populate as analysis completes.

1. **Stop count is the single strongest predictor of ticket price** — connecting flights are consistently cheaper, but the premium for non-stop varies dramatically by route

2. **Pricing is highly competitive** — the gap between the most and least expensive airline averages only ~3.2%, suggesting a commoditised market

3. **IndiGo is the cheapest airline on average** (₹9,174) despite being the highest-volume carrier — consistent with its low-cost positioning

4. **Akasa Air commands the highest average price** (₹9,478) — notable for a budget entrant and worth investigating further

5. **Departure slot significantly influences price** — evening flights are consistently the most expensive; early morning flights offer the best value

6. **Several routes show non-stop flights cheaper than connecting alternatives** — a pricing anomaly representing both a consumer opportunity and a potential revenue gap for airlines

---

## Project Structure

```
airline-pricing-intelligence/
│
├── data/
│   └── flights_clean.csv            # Cleaned dataset exported from Excel
│
├── excel/
│   └── flights_analysis.xlsx        # Full cleaned workbook with pivots
│
├── sql/
│   ├── 02_sql_schema_and_load.sql   # Table creation + data loading
│   └── 03_sql_analysis.sql          # Basic to advanced queries
│
├── powerbi/
│   └── airline_dashboard.pbix       # Full interactive dashboard
│
├── python/
│   └── 04_price_prediction.ipynb    # EDA + ML notebook
│
├── docs/
│   └── star_schema_diagram.png      # ERD / schema visual
│
└── README.md
```

---

## How to Run This Project

### SQL (Phase 2)
1. Open SQL Server Management Studio
2. Run `02_sql_schema_and_load.sql` in full to create schema and load data
3. Run `03_sql_analysis.sql` section by section to reproduce all analysis

### Power BI (Phase 3)
1. Open `airline_dashboard.pbix` in Power BI Desktop
2. Update the data source path to your local SQL Server instance
3. Refresh the dataset

### Python (Phase 4)
```bash
pip install pandas numpy matplotlib seaborn scikit-learn
jupyter notebook python/04_price_prediction.ipynb
```

---

## Limitations & Future Scope

### Current Limitations
- **No booking date available** — days-until-departure is a known major pricing driver and could not be computed. This is the single biggest gap in the dataset.
- **No seat class information** — economy vs business class pricing cannot be distinguished
- **No load factor data** — occupancy rates would significantly improve price prediction accuracy
- **Static dataset** — no real-time pricing feed; findings reflect historical patterns only

### Future Scope
- Integrate live flight pricing API (Skyscanner / Amadeus) for real-time analysis
- Add booking lead time once booking date becomes available
- Build a route recommendation engine for price-sensitive travellers
- Extend to international routes for cross-market comparison

---

## Author

**Somya Srivastava**
Data Analyst | SQL · Power BI · Python · Excel

- 📧 ssmsd9794@gmail.com
- 📞 8887728062
- 🔗 [www.linkedin.com/in/somya-srivastava-7386b5225](#)

---

*This project was built as part of a portfolio to demonstrate end-to-end data analytics capability across Excel, SQL, Power BI, and Python.*
