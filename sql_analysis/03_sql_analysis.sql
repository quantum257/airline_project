-- ============================================
-- AIRLINE PRICING INTELLIGENCE SYSTEM
-- Phase 2: SQL Analysis — Basic to Advanced
-- Author: Somya Srivastava
-- Tool: SQL Server Management Studio (SSMS)
-- Database: airline_project
-- ============================================

-- DESCRIPTION:
-- This script analyses 15,000+ domestic flight records
-- across 10 airlines, 380 routes, and 2,350 unique dates
-- to uncover pricing patterns, route competitiveness,
-- and revenue optimisation opportunities.

-- ============================================
-- TABLE OF CONTENTS
-- ============================================
-- SECTION 1: BASIC QUERIES
--   1.1 Total flights and average price per airline
--   1.2 Route count per source city
--   1.3 Average price by stop category

-- SECTION 2: INTERMEDIATE QUERIES
--   2.1 Airline price rank per route
--   2.2 Month over month price change
--   2.3 Percentage of non-stop flights per airline

-- SECTION 3: ADVANCED QUERIES
--   3.1 Price anomaly detection
--   3.2 Underpriced route identification
--   3.3 Competitive pricing analysis
-- ============================================

USE airline_project;
GO

-- SECTION 1: BASIC QUERIES
  
-- Total flights and average price per airline
-- Business Question: Which airline charges the most on average,
-- and is there a significant price gap between budget and
-- full-service carriers in this dataset?
SELECT
    a.airline,
    COUNT(f.flight_id)        AS total_flights,
    ROUND(AVG(f.price), 2)    AS avg_price,
    ROUND(MIN(f.price), 2)    AS cheapest_ticket,
    ROUND(MAX(f.price), 2)    AS most_expensive_ticket
FROM fact_flights f
JOIN dim_airline a ON f.airline_id = a.airline_id
GROUP BY a.airline
ORDER BY avg_price DESC;

GO

  
-- Route count per source city
-- Business Question: Which cities serve as the biggest
-- departure hubs, and does higher flight volume from a
-- city correlate with more competitive pricing?
SELECT
    r.source,
    COUNT(DISTINCT r.route_id) AS unique_routes,
    COUNT(f.flight_id)          AS total_flights
FROM fact_flights f
JOIN dim_route r ON f.route_id = r.route_id
GROUP BY r.source
ORDER BY total_flights DESC;

GO

-- Average price by stop_category
-- Business Question: How much extra does a passenger pay
-- for a non-stop flight vs a connecting flight, and is
-- the convenience premium consistent across all routes?
SELECT
    stop_category,
    COUNT(*)                AS total_flights,
    ROUND(AVG(price), 2)   AS avg_price,
    ROUND(MIN(price), 2)   AS min_price,
    ROUND(MAX(price), 2)   AS max_price
FROM fact_flights
GROUP BY stop_category
ORDER BY avg_price DESC;

GO

--SECTION 2 : INTERMEDIATE QUERIES
  
-- Ranking airlines by average price per route
-- Business Question: On any given route, which airline
-- offers the best value — and does the cheapest airline
-- on one route remain cheapest across other routes too?
SELECT
    r.source,
    r.destination,
    a.airline,
    ROUND(AVG(f.price), 2) AS avg_price,
    RANK() OVER (
        PARTITION BY r.route_id
        ORDER BY AVG(f.price) ASC
    ) AS price_rank
FROM fact_flights f
JOIN dim_airline a ON f.airline_id = a.airline_id
JOIN dim_route   r ON f.route_id   = r.route_id
GROUP BY r.route_id, r.source, r.destination, a.airline
ORDER BY r.source, r.destination, price_rank;

GO

-- Month over month change using lag
-- Business Question: Are there specific months where
-- ticket prices spike significantly, suggesting seasonal
-- demand patterns an airline could exploit for revenue optimisation?
SELECT
    d.month_name,
    d.month,
    ROUND(AVG(f.price), 2) AS avg_price,

    ROUND(LAG(AVG(f.price)) OVER (ORDER BY d.month), 2)
        AS prev_month_price,

    ROUND(AVG(f.price) - LAG(AVG(f.price)) OVER (ORDER BY d.month), 2)
        AS price_change

FROM fact_flights f
JOIN dim_date d ON f.date_id = d.date_id
GROUP BY d.month, d.month_name
ORDER BY d.month;

GO 
  
-- Percentage of non-stop flights per airline
-- Business Question: Which airlines prioritise direct
-- connectivity vs hub-and-spoke routing, and does a
-- higher non-stop percentage translate to higher average prices?
SELECT
    a.airline,
    COUNT(*)                                                        AS total_flights,

    SUM(CASE WHEN f.stop_category = 'Non-stop' THEN 1 ELSE 0 END)
        AS nonstop_flights,

    ROUND(
        SUM(CASE WHEN f.stop_category = 'Non-stop' THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*),
    2) AS nonstop_pct

FROM fact_flights f
JOIN dim_airline a ON f.airline_id = a.airline_id
GROUP BY a.airline
ORDER BY nonstop_pct DESC;

GO 

-- SECTION 3: ADVANCED QUERIES
  
-- Price Anomaly Detection
-- Business Question: Which flights are priced
-- significantly above their route average, and are
-- these anomalies concentrated in specific airlines
-- or time periods — indicating inconsistent pricing
-- strategy or data quality issues?
WITH route_stats AS (
    SELECT
        route_id,
        AVG(price)   AS avg_price,
        STDEV(price) AS std_price
        -- SQL Server uses STDEV() instead of MySQL's STDDEV()
    FROM fact_flights
    GROUP BY route_id
)
SELECT
    f.flight_id,
    a.airline,
    r.source,
    r.destination,
    f.price,
    ROUND(rs.avg_price, 2)                          AS route_avg,
    ROUND(rs.avg_price + (2 * rs.std_price), 2)     AS anomaly_threshold,
    ROUND((f.price - rs.avg_price) / rs.std_price, 2) AS std_deviations_above_mean

FROM fact_flights f
JOIN route_stats rs ON f.route_id  = rs.route_id
JOIN dim_airline a  ON f.airline_id = a.airline_id
JOIN dim_route   r  ON f.route_id   = r.route_id

WHERE f.price > (rs.avg_price + (2 * rs.std_price))
ORDER BY std_deviations_above_mean DESC;

GO

-- Underpriced Routes
-- Business Question: Which routes offer non-stop
-- convenience at below-average prices — representing
-- either a missed revenue opportunity for airlines
-- or a high-value option for price-sensitive travellers?
WITH route_summary AS (
    SELECT
        r.route_id,
        r.source,
        r.destination,
        ROUND(AVG(f.price), 2)        AS avg_price,
        ROUND(AVG(f.duration_mins), 0) AS avg_duration,
        ROUND(
            SUM(CASE WHEN f.stop_category = 'Non-stop' THEN 1 ELSE 0 END)
            * 100.0 / COUNT(*),
        2) AS nonstop_pct
    FROM fact_flights f
    JOIN dim_route r ON f.route_id = r.route_id
    GROUP BY r.route_id, r.source, r.destination
)
SELECT *,
    CASE
        WHEN avg_price < (SELECT AVG(price) FROM fact_flights)
         AND nonstop_pct > 50
        THEN 'High Value Route'
        ELSE 'Standard'
    END AS route_opportunity
FROM route_summary
ORDER BY avg_price ASC;

GO

-- Competetive Pricing Analysis
-- Business Question: On each route, how much more
-- expensive is the priciest airline compared to the
-- cheapest — and which airline consistently commands
-- the highest price premium over its competitors?
WITH airline_route_avg AS (
    SELECT
        f.route_id,
        f.airline_id,
        ROUND(AVG(f.price), 2) AS avg_price
    FROM fact_flights f
    GROUP BY f.route_id, f.airline_id
),
route_min AS (
    SELECT
        route_id,
        MIN(avg_price) AS cheapest_price
    FROM airline_route_avg
    GROUP BY route_id
)
SELECT
    r.source,
    r.destination,
    a.airline,
    ara.avg_price,
    rm.cheapest_price,
    ROUND(ara.avg_price - rm.cheapest_price, 2)                          AS premium_over_cheapest,
    ROUND((ara.avg_price - rm.cheapest_price) / rm.cheapest_price * 100, 2) AS premium_pct

FROM airline_route_avg ara
JOIN route_min  rm ON ara.route_id  = rm.route_id
JOIN dim_route   r ON ara.route_id  = r.route_id
JOIN dim_airline a ON ara.airline_id = a.airline_id
ORDER BY r.source, r.destination, ara.avg_price;
