-- EDA
SELECT DISTINCT repair_status from warrantys;

SELECT * FROM category;

-- PERFORMANCE QUERIES

SET STATISTICS TIME ON;

SELECT * 
FROM SALE
WHERE PRODUCT_ID = 'P-44';

SET STATISTICS TIME OFF;

-- CREATE INDEX SALE
CREATE INDEX SALE_PRODUCT_ID ON SALE(PRODUCT_ID);


SET STATISTICS TIME ON;
SELECT * 
FROM SALE
WHERE STORE_ID = 'ST-31'
SET STATISTICS TIME OFF;


-- CREATE INDEX SALE
CREATE INDEX SALE_PRODUCT_ID ON SALE(PRODUCT_ID);


-- CREATE INDEX SALE
CREATE INDEX SALE_STORE_ID ON SALE(STORE_ID);

-- 36MS > 15MS

-- CREATE INDEX SALE
CREATE INDEX SALE_DATE ON SALE(SALE_DATE);

-- BUSINESS PROBLEM

-- 1. FIND THE NUMBER OF STORES IN EACH COUNTRY
SELECT COUNTRY,COUNT(STORE_ID) AS NUMBER_STORE_COUNTRY
FROM STORES
GROUP BY COUNTRY
ORDER BY NUMBER_STORE_COUNTRY ASC

-- 2. TOTAL NUMBER OF UNIT SOLD BY EACH STORE
SELECT S.STORE_ID,
		ST.STORE_NAME, SUM(S.QUANTITY) AS TOTAL_UNIT_SOLD
FROM SALE S
JOIN STORES ST
ON ST.STORE_ID = S.STORE_ID
GROUP BY S.STORE_ID,ST.STORE_NAME
ORDER BY TOTAL_UNIT_SOLD ASC

-- 3. HOW MANY SALES OCCURED IN DECEMBER 2023
SELECT COUNT(SALE_ID) AS TOTAL_SALE
FROM SALE
WHERE FORMAT(SALE_DATE, 'MM-yyyy') = '12-2023'

-- 4. DETERMINE HOW MANY STORES HAVE NEVER HAD A WARRANTY CLAIM FILED
SELECT COUNT(*) FROM STORES WHERE STORE_ID 
NOT IN  (SELECT DISTINCT STORE_ID
		FROM SALE S
		RIGHT JOIN warrantys W
		ON S.sale_id = W.sale_id
		);

-- 5. CALCULATE THE PERCENTAGE OF WARRANTY CLAIM MARKED AS 'REJECTED' 
WITH RejectedWarranties AS (
    SELECT COUNT(*) AS TOTAL_REJECTED
    FROM warrantys
    WHERE repair_status = 'REJECTED'
),
TotalWarranties AS (
    SELECT COUNT(*) AS TOTAL_WARRANTIES
    FROM warrantys
)
SELECT 
    COALESCE(ROUND(CAST(rw.TOTAL_REJECTED AS FLOAT) / NULLIF(tw.TOTAL_WARRANTIES, 0), 2), 0) * 100 AS PERCENTAGE_REJECTED
FROM RejectedWarranties rw, TotalWarranties tw;

-- 6. Which store had the highest total units sold in the last year (for 1 year ago).
SELECT TOP 20
    s.store_id,
    st.store_name,
    SUM(s.quantity) AS total_quantity
FROM sale AS s
JOIN stores AS st
    ON s.store_id = st.store_id
WHERE sale_date >= DATEADD(YEAR, -1, GETDATE())
GROUP BY s.store_id, st.store_name
ORDER BY total_quantity DESC;

-- 7. Find the average price of product in each category
SELECT P.Category_ID, C.category_name,
ROUND(AVG(price),1) AS avg_price
FROM product P
JOIN category C 
ON P.Category_ID = C.category_id
GROUP BY P.Category_ID, C.category_name

--8. How many warranty claims were filed in 2024
SELECT COUNT(*) AS WARRANTY_CLAIM
FROM warrantys
WHERE YEAR(claim_date) = 2024;

--9. For each store, identify the best-selling day based on highest quantity sold.
WITH DailySales AS (
    SELECT 
        store_id,
        sale_date,
        SUM(quantity) AS total_quantity
    FROM sale
    GROUP BY store_id, sale_date
)
SELECT 
    store_id,
    sale_date AS best_selling_day,
    total_quantity
FROM (
    SELECT 
        store_id,
        sale_date,
        total_quantity,
        ROW_NUMBER() OVER (PARTITION BY store_id ORDER BY total_quantity DESC) AS rn
    FROM DailySales
) AS RankedSales
WHERE rn = 1;

-- Medium to Hard
select *from sale
select *from stores

-- 11. Identify the least selling product in each country for each year based on total units sold.

-- OPTION 1
WITH ProductSales AS (
    SELECT 
        p.product_id,
        s.store_id,
        st.country,
        YEAR(s.sale_date) AS sale_year,
        SUM(s.quantity) AS total_quantity
    FROM sale s
    JOIN stores st ON s.store_id = st.store_id
    JOIN product p ON s.product_id = p.product_id
    GROUP BY p.product_id, st.country, YEAR(s.sale_date), s.store_id
)
LeastSelling AS (
    SELECT 
        country,
        sale_year,
        MIN(total_quantity) AS least_quantity
    FROM ProductSales
    GROUP BY country, sale_year
)
SELECT 
    ps.product_id,
    ps.store_id,
    ps.country,
    ps.sale_year,
    ps.total_quantity AS least_quantity
FROM ProductSales ps
JOIN LeastSelling ls 
ON ps.country = ls.country 
   AND ps.sale_year = ls.sale_year
   AND ps.total_quantity = ls.least_quantity;

-- OPTION 2
   WITH ProductSales AS (
    SELECT 
        p.product_id,
        st.country,
        YEAR(s.sale_date) AS sale_year,
        SUM(s.quantity) AS total_quantity,
        RANK() OVER (PARTITION BY st.country, YEAR(s.sale_date) ORDER BY SUM(s.quantity) ASC) AS rank
    FROM sale s
    JOIN stores st ON s.store_id = st.store_id
    JOIN product p ON s.product_id = p.product_id
    GROUP BY p.product_id, st.country, YEAR(s.sale_date)
)
SELECT 
    ps.product_id,
    ps.country,
    ps.sale_year,
    ps.total_quantity AS least_quantity
FROM ProductSales ps
WHERE ps.rank = 1
ORDER BY ps.sale_year

-- OPTION 3
WITH Product_Rank AS (
    SELECT 
        p.product_id,
        st.country,
        SUM(s.quantity) AS total_quantity,
        RANK() OVER (PARTITION BY st.country ORDER BY SUM(s.quantity) ASC) AS rank
    FROM sale s
    JOIN stores st ON s.store_id = st.store_id
    JOIN product p ON s.product_id = p.product_id
    GROUP BY p.product_id, st.country
)
SELECT * FROM Product_Rank
WHERE rank = 1

-- 12. CALCULATE WARRANTY CLAIM WITHIN 180 DAYS 

SELECT W.*, S.sale_date FROM warrantys W
LEFT JOIN sale S
ON W.sale_id = s.sale_id
WHERE DATEDIFF(DAY, S.sale_date, W.claim_date) <= 180;

-- 13. how many warranty claims were filed for products launched in the last two year.
SELECT P.Product_Name, COUNT(W.claim_id) AS warranty_claims_count
FROM warrantys AS W
JOIN sale AS S
ON S.sale_id = W.sale_id
JOIN product AS P
ON P.product_id = S.product_id
WHERE P.Launch_Date >= DATEADD(YEAR, -2, GETDATE())
GROUP BY P.Product_Name

-- 14. List the months in the last three years where sales exceeded 5.000 units in the USA.
select FORMAT(SALE_DATE, 'MM-yyyy') as month, SUM(s.quantity) as total_unit_sold
from 
sale as s join stores as st on
s.store_id = st.store_id
where st.country = 'United States' and s.SALE_DATE >= DATEADD(YEAR, -3, GETDATE())
group by FORMAT(SALE_DATE, 'MM-yyyy') 
having SUM(s.quantity) > 5000

-- COMPLEX PROBLEMS

-- 15. THE PERCENTAGE CHANCE OF RECEIVING WARRANTY CLAIMS AFTER EACH PURCHASE FOR EACH COUNTRY

SELECT 
    st.country,
    SUM(s.quantity) AS total_unit_sold,
    COUNT(w.claim_id) AS total_warranty_claims,
    COALESCE(ROUND((COUNT(w.claim_id) * 1.0 / SUM(s.quantity)) * 100, 2), 0) AS warranty_claim_percentage
FROM sale AS s
JOIN stores AS st
    ON s.store_id = st.store_id
LEFT JOIN warrantys AS w
    ON s.sale_id = w.sale_id
GROUP BY st.country;

-- 16. ANALYZE THE YEAR-BY-YEAR GROWTH RATIO FOR EACH STORE
WITH Yearly_Sales AS (
    SELECT 
        s.store_id,
        st.store_name,
        YEAR(s.sale_date) AS year,
        SUM(s.quantity * p.price) AS total_sale
    FROM sale AS s
    JOIN product AS p 
        ON s.product_id = p.product_id
    JOIN stores AS st
        ON st.store_id = s.store_id
    GROUP BY s.store_id, st.store_name, YEAR(s.sale_date)
),
Radio_Growth AS(
SELECT 
    store_name, 
    year,
    LAG(total_sale, 1) OVER (PARTITION BY store_name ORDER BY year) AS last_year_sale,
    total_sale AS current_year_sale
FROM Yearly_Sales)

select store_name, year, last_year_sale, current_year_sale,
(current_year_sale - last_year_sale) / last_year_sale * 100
from Radio_Growth

-- 17. Query to calculate the monthly running total of sale for each store over the past four year and compare trends during this period
WITH monthly_sale as (
select s.store_id,
YEAR(s.sale_date) as year, MONTH(s.sale_date) as month,
SUM(p.price * s.quantity) as total_revenue
from sale as s
join product as p
on s.product_id = p.product_id
group by s.store_id,YEAR(s.sale_date), MONTH(s.sale_date)

)

select  store_id, year,  month, total_revenue, 
SUM(total_revenue) OVER(PARTITION BY store_ID ORDER BY year, month) as running_total
from monthly_sale

--18. 
SELECT 
    p.product_name,
    CASE 
        WHEN s.sale_date BETWEEN p.launch_date AND DATEADD(MONTH, 6, p.launch_date) THEN '0-6 Month'
        WHEN s.sale_date BETWEEN DATEADD(MONTH, 6, p.launch_date) AND DATEADD(MONTH, 12, p.launch_date) THEN '6-12 Month'
        WHEN s.sale_date BETWEEN DATEADD(MONTH, 12, p.launch_date) AND DATEADD(MONTH, 18, p.launch_date) THEN '12-18 Month'
        ELSE '18+'
    END AS plc, 
	SUM(s.quantity) as total_qty_sale
FROM sale AS s
JOIN product AS p
    ON s.product_id = p.product_id
GROUP BY p.product_name,SUM(s.quantity)
