--1. Database and table details
SELECT name
FROM sqlite_master
WHERE type = 'table';

PRAGMA table_info(customer_loyalty_history);
PRAGMA table_info("Customer Flight Activity");
PRAGMA table_info("Calendar");
PRAGMA table_info("Airline Loyalty Data Dictionary");


--2. Dataset overview
SELECT 'Customer History' AS Table_Name, COUNT(*) AS Total_Records
FROM customer_loyalty_history
UNION ALL
SELECT 'Flight Activity', COUNT(*)
FROM "Customer Flight Activity"
UNION ALL
SELECT 'Calendar', COUNT(*)
FROM "Calendar"
UNION ALL
SELECT 'Data Dictionary', COUNT(*)
FROM "Airline Loyalty Data Dictionary";


SELECT
    COUNT(*) AS Total_Records,
    COUNT(DISTINCT "Loyalty Number") AS Unique_Customers
FROM customer_loyalty_history;


--3. Data quality analysis Duplicate customer records
SELECT
    COUNT(*) AS Total_Rows,
    COUNT(DISTINCT "Loyalty Number") AS Unique_Customers,
    COUNT(*) - COUNT(DISTINCT "Loyalty Number") AS Duplicate_Rows
FROM customer_loyalty_history;


--Duplicate customer-month records
SELECT
    "Loyalty Number",
    Year,
    Month,
    COUNT(*) AS Duplicate_Count
FROM "Customer Flight Activity"
GROUP BY "Loyalty Number", Year, Month
HAVING COUNT(*) > 1;


--Missing values
SELECT
    SUM(CASE WHEN "Loyalty Number" IS NULL THEN 1 ELSE 0 END) AS Missing_ID,
    SUM(CASE WHEN Gender IS NULL THEN 1 ELSE 0 END) AS Missing_Gender,
    SUM(CASE WHEN Education IS NULL THEN 1 ELSE 0 END) AS Missing_Education,
    SUM(CASE WHEN "Loyalty Card" IS NULL THEN 1 ELSE 0 END) AS Missing_Card,
    SUM(CASE WHEN CLV IS NULL THEN 1 ELSE 0 END) AS Missing_CLV
FROM customer_loyalty_history;


--Zero-flight records
SELECT
    COUNT(*) AS Total_Records,
    SUM(CASE WHEN "Total Flights" = 0 THEN 1 ELSE 0 END) AS Zero_Flights,
    SUM(CASE WHEN "Total Flights" > 0 THEN 1 ELSE 0 END) AS Positive_Flights
FROM "Customer Flight Activity";


--4. Join validation Matching records
SELECT COUNT(*) AS Matching_Records
FROM "Customer Flight Activity" f
INNER JOIN customer_loyalty_history c
ON f."Loyalty Number" = c."Loyalty Number";


--Unmatched records
SELECT COUNT(*) AS Unmatched_Records
FROM "Customer Flight Activity" f
LEFT JOIN customer_loyalty_history c
ON f."Loyalty Number" = c."Loyalty Number"
WHERE c."Loyalty Number" IS NULL;


--5. Descriptive analysis – 14 queries
--5.1. Overall flight performance
SELECT
    SUM("Total Flights") AS Total_Flights,
    SUM(Distance) AS Total_Distance,
    SUM("Points Accumulated") AS Total_Points_Accumulated,
    SUM("Points Redeemed") AS Total_Points_Redeemed
FROM "Customer Flight Activity";


--5.2. Year-wise flight performance
SELECT
    Year,
    SUM("Total Flights") AS Total_Flights,
    SUM(Distance) AS Total_Distance,
    SUM("Points Accumulated") AS Total_Points
FROM "Customer Flight Activity"
GROUP BY Year
ORDER BY Year;


--5.3. Month-wise flight performance
SELECT
    Month,
    SUM("Total Flights") AS Total_Flights,
    SUM(Distance) AS Total_Distance,
    SUM("Points Accumulated") AS Total_Points
FROM "Customer Flight Activity"
GROUP BY Month
ORDER BY Month;


--5.4. Loyalty Card-wise CLV
SELECT
    "Loyalty Card",
    COUNT(*) AS Customer_Count,
    ROUND(AVG(CLV), 2) AS Average_CLV
FROM customer_loyalty_history
GROUP BY "Loyalty Card";


--5.5. Gender-wise CLV
SELECT
    Gender,
    COUNT(*) AS Customer_Count,
    ROUND(AVG(CLV), 2) AS Average_CLV
FROM customer_loyalty_history
GROUP BY Gender;


--5.6. Education-wise CLV
SELECT
    Education,
    COUNT(*) AS Customer_Count,
    ROUND(AVG(CLV), 2) AS Average_CLV
FROM customer_loyalty_history
GROUP BY Education;


--5.7. Country-wise customer analysis
SELECT
    Country,
    COUNT(DISTINCT "Loyalty Number") AS Customer_Count,
    ROUND(AVG(CLV), 2) AS Average_CLV
FROM customer_loyalty_history
GROUP BY Country
ORDER BY Customer_Count DESC;


--5.8. Active vs Cancelled customers
SELECT
    CASE
        WHEN "Cancellation Year" IS NULL THEN 'Active'
        ELSE 'Cancelled'
    END AS Customer_Status,
    COUNT(*) AS Customer_Count
FROM customer_loyalty_history
GROUP BY Customer_Status;


--5.9. Enrollment Year analysis
SELECT
    "Enrollment Year",
    COUNT(*) AS Customer_Count
FROM customer_loyalty_history
GROUP BY "Enrollment Year"
ORDER BY "Enrollment Year";


--5.10. Enrollment Type analysis
SELECT
    "Enrollment Type",
    COUNT(*) AS Customer_Count
FROM customer_loyalty_history
GROUP BY "Enrollment Type";


--5.11. Points Redemption analysis
SELECT
    SUM("Points Redeemed") AS Total_Redeemed,
    SUM("Points Accumulated") AS Total_Accumulated,
    ROUND(
        100.0 * SUM("Points Redeemed") /
        NULLIF(SUM("Points Accumulated"), 0), 2
    ) AS Redemption_Percentage
FROM "Customer Flight Activity";


--5.12. Flight Activity by Loyalty Card
SELECT
    c."Loyalty Card",
    SUM(f."Total Flights") AS Total_Flights,
    SUM(f.Distance) AS Total_Distance
FROM "Customer Flight Activity" f
JOIN customer_loyalty_history c
ON f."Loyalty Number" = c."Loyalty Number"
GROUP BY c."Loyalty Card";


--5.13. Average Flight Activity per Customer
SELECT
    ROUND(AVG(Total_Flights), 2) AS Average_Flights_Per_Customer
FROM (
    SELECT
        "Loyalty Number",
        SUM("Total Flights") AS Total_Flights
    FROM "Customer Flight Activity"
    GROUP BY "Loyalty Number"
);


--5.14. Customer Segmentation by CLV
SELECT
    CASE
        WHEN CLV < 5000 THEN 'Low'
        WHEN CLV < 10000 THEN 'Medium'
        ELSE 'High'
    END AS CLV_Segment,
    COUNT(*) AS Customer_Count,
    ROUND(AVG(CLV), 2) AS Average_CLV,
    ROUND(MIN(CLV), 2) AS Minimum_CLV,
    ROUND(MAX(CLV), 2) AS Maximum_CLV
FROM customer_loyalty_history
WHERE CLV IS NOT NULL
GROUP BY CLV_Segment;


--6. KPI queries KPI 1–4
SELECT
    SUM("Total Flights") AS Total_Flights,
    SUM(Distance) AS Total_Distance,
    SUM("Points Accumulated") AS Total_Points_Accumulated,
    SUM("Points Redeemed") AS Total_Points_Redeemed
FROM "Customer Flight Activity";


--KPI 5–6
SELECT
    COUNT(DISTINCT "Loyalty Number") AS Total_Customers,
    ROUND(AVG(CLV), 2) AS Average_CLV
FROM customer_loyalty_history;


--7. Customer Cohort Retention Analysis
WITH customer_cohorts AS (
    SELECT
        "Loyalty Number",
        "Enrollment Year" AS Cohort_Year,
        "Enrollment Month" AS Cohort_Month,
        ("Enrollment Year" * 12 + "Enrollment Month") AS Cohort_Index
    FROM customer_loyalty_history
    WHERE "Enrollment Year" IS NOT NULL
      AND "Enrollment Month" BETWEEN 1 AND 12
),
flight_activity AS (
    SELECT DISTINCT
        "Loyalty Number",
        Year,
        Month,
        (Year * 12 + Month) AS Activity_Index
    FROM "Customer Flight Activity"
    WHERE "Total Flights" > 0
),
cohort_sizes AS (
    SELECT
        Cohort_Year,
        Cohort_Month,
        COUNT(DISTINCT "Loyalty Number") AS Cohort_Size
    FROM customer_cohorts
    GROUP BY Cohort_Year, Cohort_Month
)
SELECT
    c.Cohort_Year,
    c.Cohort_Month,
    a.Activity_Index - c.Cohort_Index AS Cohort_Period,
    cs.Cohort_Size,
    COUNT(DISTINCT c."Loyalty Number") AS Active_Customers,
    ROUND(
        COUNT(DISTINCT c."Loyalty Number") * 100.0 /
        NULLIF(cs.Cohort_Size, 0), 2
    ) AS Retention_Percentage
FROM customer_cohorts c
JOIN flight_activity a
    ON c."Loyalty Number" = a."Loyalty Number"
JOIN cohort_sizes cs
    ON c.Cohort_Year = cs.Cohort_Year
   AND c.Cohort_Month = cs.Cohort_Month
WHERE a.Activity_Index >= c.Cohort_Index
GROUP BY
    c.Cohort_Year,
    c.Cohort_Month,
    Cohort_Period,
    cs.Cohort_Size
ORDER BY
    c.Cohort_Year,
    c.Cohort_Month,
    Cohort_Period;


--8. Additional SQL concepts
--HAVING clause
SELECT
    "Loyalty Card",
    COUNT(*) AS Customer_Count
FROM customer_loyalty_history
GROUP BY "Loyalty Card"
HAVING COUNT(*) > 1000;


--Window function – Customer CLV ranking
SELECT
    "Loyalty Number",
    "Loyalty Card",
    CLV,
    RANK() OVER (
        PARTITION BY "Loyalty Card"
        ORDER BY CLV DESC
    ) AS CLV_Rank
FROM customer_loyalty_history
WHERE CLV IS NOT NULL;