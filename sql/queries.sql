-- ================================================================
-- SALES FORECASTING & INVENTORY OPTIMISATION
-- SQL Analysis Queries
-- Author  : Omer Bin Wahid Latifi
-- Dataset : Retail Store Inventory (73,100 rows | 5 Stores | 20 Products)
-- Tool    : SQLite Online
-- ================================================================


-- ----------------------------------------------------------------
-- QUERY 1: Stores With Most Products Below Reorder Point
-- Skill   : Aggregation, GROUP BY, ORDER BY
-- Insight : Identifies which stores need urgent restocking action
-- ----------------------------------------------------------------

SELECT
    "Store ID"                        AS Store,
    COUNT("Product ID")               AS Total_Products,
    ROUND(AVG("Reorder_Point"), 0)    AS Avg_Reorder_Point,
    ROUND(AVG("Avg_Daily_Demand"), 1) AS Avg_Daily_Demand,
    ROUND(AVG("Safety_Stock"), 0)     AS Avg_Safety_Stock
FROM inventory_optimisation_results
WHERE "Avg_Inventory" < "Reorder_Point"
GROUP BY "Store ID"
ORDER BY Total_Products DESC;


-- ----------------------------------------------------------------
-- QUERY 2: Top 10 Highest Stockout Risk Store-Product Combinations
-- Skill   : Filtering, ORDER BY, LIMIT
-- Insight : Pinpoints exact store-product combos at highest risk
-- ----------------------------------------------------------------

SELECT
    "Store ID"                            AS Store,
    "Product ID"                          AS Product,
    ROUND("Stockout_Risk_Pct", 2)         AS Stockout_Risk_Pct,
    ROUND("Avg_Daily_Demand", 1)          AS Avg_Daily_Demand,
    ROUND("Safety_Stock", 0)              AS Safety_Stock,
    ROUND("Reorder_Point", 0)             AS Reorder_Point,
    "Recommendation"                      AS Action
FROM inventory_optimisation_results
ORDER BY "Stockout_Risk_Pct" DESC
LIMIT 10;


-- ----------------------------------------------------------------
-- QUERY 3: Total Revenue and Units Sold by Category and Region
-- Skill   : Multi-column GROUP BY, aggregate functions, ROUND
-- Insight : Reveals which category-region combos drive most revenue
-- ----------------------------------------------------------------

SELECT
    "Category"                            AS Category,
    "Region"                              AS Region,
    SUM("Units Sold")                     AS Total_Units_Sold,
    ROUND(SUM("Revenue"), 2)              AS Total_Revenue,
    ROUND(AVG("Units Sold"), 1)           AS Avg_Daily_Units,
    ROUND(AVG("Price"), 2)                AS Avg_Price
FROM retail_inventory_cleaned
GROUP BY "Category", "Region"
ORDER BY Total_Revenue DESC;


-- ----------------------------------------------------------------
-- QUERY 4: Average Safety Stock and EOQ by Store
-- Skill   : GROUP BY, AVG, ROUND
-- Insight : Shows recommended stock buffer and order size per store
-- ----------------------------------------------------------------

SELECT
    "Store ID"                            AS Store,
    ROUND(AVG("Safety_Stock"), 0)         AS Avg_Safety_Stock,
    ROUND(AVG("EOQ"), 0)                  AS Avg_EOQ,
    ROUND(AVG("Reorder_Point"), 0)        AS Avg_Reorder_Point,
    ROUND(AVG("Avg_Daily_Demand"), 1)     AS Avg_Daily_Demand,
    ROUND(SUM("Total_Revenue"), 2)        AS Total_Revenue
FROM inventory_optimisation_results
GROUP BY "Store ID"
ORDER BY Avg_Safety_Stock DESC;


-- ----------------------------------------------------------------
-- QUERY 5: Monthly Sales Trend per Store
-- Skill   : Date functions, GROUP BY, ORDER BY
-- Insight : Tracks how each store's sales volume changed month by month
-- ----------------------------------------------------------------

SELECT
    "Store ID"                            AS Store,
    STRFTIME('%Y-%m', "Date")             AS Year_Month,
    SUM("Units Sold")                     AS Monthly_Units_Sold,
    ROUND(SUM("Revenue"), 2)              AS Monthly_Revenue,
    ROUND(AVG("Units Sold"), 1)           AS Avg_Daily_Units
FROM retail_inventory_cleaned
GROUP BY "Store ID", STRFTIME('%Y-%m', "Date")
ORDER BY "Store ID", Year_Month;


-- ----------------------------------------------------------------
-- QUERY 6: Running Total of Revenue Per Store (Window Function)
-- Skill   : Window functions — SUM() OVER (PARTITION BY ... ORDER BY)
-- Insight : Shows cumulative revenue build-up over time per store
-- ----------------------------------------------------------------

SELECT
    "Store ID"                            AS Store,
    STRFTIME('%Y-%m', "Date")             AS Year_Month,
    ROUND(SUM("Revenue"), 2)              AS Monthly_Revenue,
    ROUND(
        SUM(SUM("Revenue")) OVER (
            PARTITION BY "Store ID"
            ORDER BY STRFTIME('%Y-%m', "Date")
        ), 2
    )                                     AS Running_Total_Revenue
FROM retail_inventory_cleaned
GROUP BY "Store ID", STRFTIME('%Y-%m', "Date")
ORDER BY "Store ID", Year_Month;


-- ----------------------------------------------------------------
-- QUERY 7: Products Consistently Below Reorder Point (CTE)
-- Skill   : CTE (Common Table Expression), subquery, filtering
-- Insight : Identifies chronic understocking vs occasional dips
-- ----------------------------------------------------------------

WITH StockStatus AS (
    SELECT
        "Store ID"                        AS Store,
        "Product ID"                      AS Product,
        ROUND("Avg_Daily_Demand", 1)      AS Avg_Daily_Demand,
        ROUND("Avg_Inventory", 0)         AS Avg_Inventory,
        ROUND("Reorder_Point", 0)         AS Reorder_Point,
        ROUND("Safety_Stock", 0)          AS Safety_Stock,
        ROUND("EOQ", 0)                   AS EOQ,
        ROUND("Stockout_Risk_Pct", 2)     AS Stockout_Risk_Pct,
        ROUND("Reorder_Point" -
              "Avg_Inventory", 0)         AS Stock_Deficit,
        "Recommendation"                  AS Action
    FROM inventory_optimisation_results
),
HighRisk AS (
    SELECT *
    FROM StockStatus
    WHERE Avg_Inventory < Reorder_Point
      AND Stockout_Risk_Pct > 1.0
)
SELECT
    Store,
    Product,
    Avg_Daily_Demand,
    Avg_Inventory,
    Reorder_Point,
    Safety_Stock,
    EOQ,
    Stock_Deficit,
    Stockout_Risk_Pct,
    Action
FROM HighRisk
ORDER BY Stockout_Risk_Pct DESC, Stock_Deficit DESC;


-- ================================================================
-- END OF QUERIES
-- ================================================================
