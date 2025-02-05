/*
Answer to first question: Who are Fetch’s Power Users?
Assumptions:
A power user is someone who:
- Has spent at least $30 in total sales OR scanned at least 10 receipts.
- Has been an active user for at least 1 year (based on CREATED_DATE).
*/
WITH UserEngagement AS (
    SELECT 
        TT.USER_ID,
        COUNT(TT.RECEIPT_ID) AS TotalReceiptsScanned,
        SUM(CAST(TT.FINAL_SALE AS FLOAT)) AS TotalSpent,
        DATEDIFF(YEAR, UT.CREATED_DATE, GETDATE()) AS YearsSinceJoined
    FROM TRANSACTION_TAKEHOME TT
    INNER JOIN USER_TAKEHOME UT ON TT.USER_ID = UT.ID
    GROUP BY TT.USER_ID, UT.CREATED_DATE
),
FilteredUsers AS (
    SELECT 
        USER_ID,
        TotalReceiptsScanned,
        TotalSpent,
        YearsSinceJoined
    FROM UserEngagement
    WHERE (TotalSpent >= 30 OR TotalReceiptsScanned >= 10) -- Power user conditions
    AND YearsSinceJoined >= 1  -- Must be active for at least 1 year
)

SELECT * FROM FilteredUsers
ORDER BY TotalReceiptsScanned DESC, TotalSpent DESC;


/*
Answer to second question: Which is the Leading Brand in the Dips & Salsa Category?
Assumptions:
- The leading brand is defined as the brand with the highest total sales in the Dips & Salsa category.
- CATEGORY_2 field contains "Dips & Salsa" for relevant products.
- We calculate total sales (FINAL_SALE) for brands in this category.
*/
SELECT TOP 1
    PTH.BRAND,
    SUM(CAST(TT.FINAL_SALE AS FLOAT)) AS TotalSales
FROM TRANSACTION_TAKEHOME TT
INNER JOIN PRODUCTS_TAKEHOME PTH ON TT.BARCODE = PTH.BARCODE
WHERE PTH.CATEGORY_2 = 'Dips & Salsa'
GROUP BY PTH.BRAND
ORDER BY TotalSales DESC;


/*
Answer to third question: At What Percent Has Fetch Grown Year Over Year?
Assumptions:
- Fetch's growth is measured by the total number of transactions recorded per year.
- We assume that a higher number of transactions indicates higher user engagement.
- The growth rate is calculated as the percentage increase in transactions compared to the previous year.
- The current dataset we have is only for year 2024 so it would not return a YoYGrowthPercentage
*/

WITH YearlyTransactions AS (
    -- Count the number of transactions per year based on SCAN_DATE
    SELECT 
        YEAR(SCAN_DATE) AS Year, 
        COUNT(*) AS TransactionCount
    FROM TRANSACTION_TAKEHOME
    GROUP BY YEAR(SCAN_DATE)
)

-- Calculate Year-over-Year Growth
SELECT 
    Y1.Year AS CurrentYear,
    Y1.TransactionCount AS CurrentYearTransactions,
    Y2.TransactionCount AS PreviousYearTransactions,
    ((CAST(Y1.TransactionCount AS FLOAT) - Y2.TransactionCount) / NULLIF(Y2.TransactionCount, 0)) * 100 AS YoYGrowthPercentage
FROM YearlyTransactions Y1
LEFT JOIN YearlyTransactions Y2 ON Y1.Year = Y2.Year + 1  -- Compare each year with the previous year
ORDER BY Y1.Year DESC;