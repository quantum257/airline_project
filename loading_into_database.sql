CREATE TABLE dim_airline (
    airline_id   INT IDENTITY(1,1) PRIMARY KEY,
    airline_name VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE dim_route (
    route_id   INT IDENTITY(1,1) PRIMARY KEY,
    Source     VARCHAR(100) NOT NULL,
    destination VARCHAR(100) NOT NULL,
    Total_stops  VARCHAR(50),
    CONSTRAINT uq_route UNIQUE (source, destination)
);

CREATE TABLE dim_date (
    date_id INT IDENTITY(1,1) PRIMARY KEY,
    date_of_journey   DATE NOT NULL UNIQUE,
    month INT,
    month_name  VARCHAR(20),
    day_of_week VARCHAR(20),
    is_weekend  BIT,        -- SQL Server uses BIT instead of TINYINT(1)
                            -- 0 = weekday, 1 = weekend
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

CREATE TABLE fact_flights (
    flight_id      INT IDENTITY(1,1) PRIMARY KEY,
    airline_id     INT NOT NULL,
    route_id       INT NOT NULL,
    date_id        INT NOT NULL,
    Total_stops VARCHAR(50),
    duration_mins  INT,
    price          int,
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


