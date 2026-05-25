-- ============================================
-- AIRLINE PRICING INTELLIGENCE SYSTEM
-- Phase 2: Schema Design & Data Loading
-- Author: Somya Srivastava
-- ============================================

-- STEP 1: Create Dimension Tables
-- STEP 2: Create Staging Table
-- STEP 3: Create Fact Table
-- STEP 4: Populate Dimension Tables
-- STEP 5: Populate Fact Table
-- STEP 6: Verification Queries

drop table dim_airline
CREATE TABLE dim_airline (
    airline_id   INT IDENTITY(1,1) PRIMARY KEY,
    airline VARCHAR(100) NOT NULL UNIQUE
);
drop table dim_route
CREATE TABLE dim_route (
    route_id   INT IDENTITY(1,1) PRIMARY KEY,
    Source     VARCHAR(100) NOT NULL,
    destination VARCHAR(100) NOT NULL,
    route_type  VARCHAR(50),
    CONSTRAINT uq_route UNIQUE (source, destination)
);

DROP TABLE dim_date

CREATE TABLE dim_date (
    date_id     INT IDENTITY(1,1) PRIMARY KEY,
    full_date   DATE NOT NULL,      -- removed UNIQUE for now
    month       INT,
    month_name  VARCHAR(20),
    day_of_week VARCHAR(20),
    is_weekend  BIT,
    season      VARCHAR(20)
);


CREATE TABLE staging_flights (
    airline_name          VARCHAR(100),
    date_of_journey  VARCHAR(50),
	month int,
	month_name		VARCHAR(50),
	day_of_week		varchar(50),
	is_weekend		varchar(50),
    Source           VARCHAR(100),
    destination      VARCHAR(100),
	route			varchar(100),
    Origin			varchar(20),
	Stop_1			varchar(20),
	Stop_2			varchar(20),
	Stop_3			varchar(20),
	Total_Stops		varchar(50),
	dep_time        time,
	arrival_time	time,
	duration VARCHAR(50),
	duration_mins INT,
	Route_type	varchar(50),
	Additional_info varchar(50),
	Price	int,
	Price_Per_Min varchar(50)
);

drop table fact_flights
CREATE TABLE fact_flights (
    flight_id      INT IDENTITY(1,1) PRIMARY KEY,
    airline_id     INT NOT NULL,
    route_id       INT NOT NULL,
    date_id        INT NOT NULL,
    stop_category  VARCHAR(50),
    duration_mins  INT,
    price          DECIMAL(10,2),
    price_per_min  DECIMAL(10,2),

    -- Foreign Keys
    CONSTRAINT fk_airline FOREIGN KEY (airline_id) REFERENCES dim_airline(airline_id),
    CONSTRAINT fk_route   FOREIGN KEY (route_id)   REFERENCES dim_route(route_id),
    CONSTRAINT fk_date    FOREIGN KEY (date_id)     REFERENCES dim_date(date_id)
);


BULK INSERT staging_flights
FROM 'C:\Users\ssmsd\Desktop\flights.csv'
WITH (
    FIRSTROW = 2,          -- Skip the header row
    FIELDTERMINATOR = ',', -- Columns separated by comma
    ROWTERMINATOR = '\n',  -- Rows separated by new line
    TABLOCK
);

truncate table staging_flights
select count(*) 
from staging_flights


INSERT INTO dim_airline (airline)
SELECT DISTINCT TRIM(airline_name)
FROM staging_flights
WHERE airline_name IS NOT NULL
ORDER BY TRIM(airline_name)

SELECT * FROM dim_airline;
-- Should see each airline with an auto-assigned ID

INSERT INTO dim_route (source, destination, route_type)
SELECT 
    TRIM(UPPER(source)),
    TRIM(UPPER(destination)),
    MAX(route_type)        -- picks one route_type when duplicates exist
FROM staging_flights
WHERE source IS NOT NULL
  AND destination IS NOT NULL
GROUP BY TRIM(UPPER(source)), TRIM(UPPER(destination));

SELECT count(*) FROM dim_route

SELECT DISTINCT source FROM dim_route ORDER BY source;

SELECT DISTINCT destination FROM dim_route ORDER BY destination;

DELETE FROM dim_date;
DBCC CHECKIDENT ('dim_date', RESEED, 0);

-- Step 2: Insert using CTE
WITH unique_dates AS (
    SELECT DISTINCT 
        TRY_CONVERT(DATE, date_of_journey, 103) AS full_date
    FROM staging_flights
    WHERE TRY_CONVERT(DATE, date_of_journey, 103) IS NOT NULL
)
INSERT INTO dim_date (full_date, month, month_name, day_of_week, is_weekend, season)
SELECT
    full_date,
    MONTH(full_date)                AS month,
    DATENAME(MONTH,   full_date)    AS month_name,
    DATENAME(WEEKDAY, full_date)    AS day_of_week,
    CASE 
        WHEN DATENAME(WEEKDAY, full_date) 
             IN ('Saturday','Sunday') THEN 1 
        ELSE 0 
    END                             AS is_weekend,
    CASE
        WHEN MONTH(full_date) IN (12,1,2)  THEN 'Winter'
        WHEN MONTH(full_date) IN (3,4,5)   THEN 'Spring'
        WHEN MONTH(full_date) IN (6,7,8,9) THEN 'Monsoon'
        ELSE 'Autumn'
    END                             AS season
FROM unique_dates
ORDER BY full_date;

SELECT * FROM dim_date ORDER BY full_date;

truncate table fact_flights
INSERT INTO fact_flights
    (airline_id, route_id, date_id,
     stop_category, duration_mins, price, price_per_min)

SELECT
    a.airline_id,
    r.route_id,
    d.date_id,
    s.Total_Stops,
    s.duration_mins,
    s.price,
    CASE 
        WHEN s.price_per_min IS NULL THEN NULL
        ELSE CAST(s.price_per_min AS DECIMAL(10,2))
    END AS price_per_min

FROM staging_flights s

JOIN dim_airline a
    ON LTRIM(RTRIM(s.airline_name)) = a.airline

JOIN dim_route r
    ON LTRIM(RTRIM(s.source))       = r.source
    AND LTRIM(RTRIM(s.destination)) = r.destination

JOIN dim_date d
    ON CONVERT(DATE, s.date_of_journey, 105) = d.full_date;

SELECT COUNT(*) AS total_flights FROM fact_flights;
-- Should match staging_flights row count

SELECT TOP 5 * FROM fact_flights;

-- Row count check
SELECT 'staging'     AS tbl, COUNT(*) AS rows FROM staging_flights UNION ALL
SELECT 'fact_flights'         , COUNT(*)        FROM fact_flights    UNION ALL
SELECT 'dim_airline'          , COUNT(*)        FROM dim_airline     UNION ALL
SELECT 'dim_route'            , COUNT(*)        FROM dim_route       UNION ALL
SELECT 'dim_date'             , COUNT(*)        FROM dim_date;

-- Check for any NULLs in key columns
SELECT
    SUM(CASE WHEN airline_id    IS NULL THEN 1 ELSE 0 END) AS null_airline,
    SUM(CASE WHEN route_id      IS NULL THEN 1 ELSE 0 END) AS null_route,
    SUM(CASE WHEN date_id       IS NULL THEN 1 ELSE 0 END) AS null_date,
    SUM(CASE WHEN price         IS NULL THEN 1 ELSE 0 END) AS null_price
FROM fact_flights;




