/*Answers to first question: What are the top 5 brands by receipts scanned among users 21 and over?
*/

----Query to show the top 5 brands regardless of ties between number of receipts scanned
WITH FilteredUsers AS (
    SELECT ID
    FROM USER_TAKEHOME
    WHERE DATEDIFF(YEAR, BIRTH_DATE, GETDATE()) >= 21
),
BrandReceipts AS (
    SELECT 
        PTH.BRAND,
        COUNT(TTH.RECEIPT_ID) AS ReceiptsScanned
    FROM TRANSACTION_TAKEHOME TTH
    INNER JOIN PRODUCTS_TAKEHOME PTH ON TTH.BARCODE = PTH.BARCODE
    INNER JOIN FilteredUsers FU ON TTH.USER_ID = FU.ID
	WHERE 
	1=1
	AND TTH.SCAN_DATE IS NOT NULL
	AND PTH.BRAND IS NOT NULL
    GROUP BY PTH.BRAND
)

SELECT TOP 5
    BRAND, 
    ReceiptsScanned
FROM BrandReceipts
ORDER BY ReceiptsScanned DESC;


/*Answers to seconds question: What are the top 5 brands by sales among users that have had their account for at least six months?
*/

----Query to show the top 5 brands regardless of ties between number of sales
WITH EligibleUsers AS (
    SELECT ID
    FROM USER_TAKEHOME
    WHERE DATEDIFF(MONTH, CREATED_DATE, GETDATE()) >= 6
),
BrandSales AS (
    SELECT 
        PTH.BRAND,
        SUM(TTH.FINAL_SALE) AS TotalSales
    FROM TRANSACTION_TAKEHOME TTH
    INNER JOIN PRODUCTS_TAKEHOME PTH ON TTH.BARCODE = PTH.BARCODE
    INNER JOIN EligibleUsers EU ON TTH.USER_ID = EU.ID
    WHERE 
	1=1
	AND TTH.FINAL_SALE IS NOT NULL
	AND PTH.BRAND IS NOT NULL
    GROUP BY PTH.BRAND
)

SELECT TOP 5
    BRAND, 
    TotalSales
FROM BrandSales
ORDER BY TotalSales DESC;

/*Answer to third question: What is the percentage of sales in the Health & Wellness category by generation?
Query below categorizes the generations into Gen Z, Millenials, Gen X, Baby Boomers and Others
*/

WITH UserGenerations AS (
    SELECT 
        ID AS USER_ID,
        CASE 
            WHEN BIRTH_DATE >= '1997-01-01' THEN 'Gen Z'
            WHEN BIRTH_DATE BETWEEN '1981-01-01' AND '1996-12-31' THEN 'Millennials'
            WHEN BIRTH_DATE BETWEEN '1965-01-01' AND '1980-12-31' THEN 'Gen X'
            WHEN BIRTH_DATE BETWEEN '1946-01-01' AND '1964-12-31' THEN 'Baby Boomers'
            ELSE 'Other'
        END AS Generation
    FROM USER_TAKEHOME
),
HealthWellnessSales AS (
    SELECT 
        UG.Generation,
        SUM(TT.FINAL_SALE) AS HealthWellnessTotalSales
    FROM TRANSACTION_TAKEHOME TT
    INNER JOIN PRODUCTS_TAKEHOME PT ON TT.BARCODE = PT.BARCODE
    INNER JOIN UserGenerations UG ON TT.USER_ID = UG.USER_ID
    WHERE PT.CATEGORY_1 = 'Health & Wellness'
    GROUP BY UG.Generation
),
TotalSalesByGeneration AS (
    SELECT 
        UG.Generation,
        SUM(TT.FINAL_SALE) AS TotalSales
    FROM TRANSACTION_TAKEHOME TT
    INNER JOIN PRODUCTS_TAKEHOME PT ON TT.BARCODE = PT.BARCODE
    INNER JOIN UserGenerations UG ON TT.USER_ID = UG.USER_ID
    GROUP BY UG.Generation
)

SELECT 
    HWS.Generation,
    HWS.HealthWellnessTotalSales,
    TS.TotalSales,
    (CAST(HWS.HealthWellnessTotalSales AS FLOAT) / NULLIF(TS.TotalSales, 0)) * 100 AS HealthWellnessSalesPercentage
FROM HealthWellnessSales HWS
INNER JOIN TotalSalesByGeneration TS ON HWS.Generation = TS.Generation
ORDER BY HealthWellnessSalesPercentage DESC;