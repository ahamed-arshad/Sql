-- Project: Retail Sales Analysis (MySQL 8.0+)
-- Notes:
-- - Use DECIMAL for money to avoid floating-point errors.
-- - MySQL 8.0 supports window functions such as RANK() OVER().
-- - Use YEAR(), MONTH(), and EXTRACT() for temporal logic in MySQL.

-- Bootstrap
DROP DATABASE IF EXISTS sql_project_p2;
CREATE DATABASE sql_project_p2 CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE sql_project_p2;

-- Load Data
SET GLOBAL local_infile = 1;

-- Place the file at specific places

SHOW GLOBAL VARIABLES LIKE 'local_infile';

-- Load the Data
LOAD DATA LOCAL INFILE 'C:/data/Retail Sales Analysis.csv' -- Use your file path here. Use forward slashes!
INTO TABLE invoice_summary
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n' -- '\r\n' for Windows files, '\n' for macOS/Linux
IGNORE 1 ROWS; -- This is crucial! It skips your header row (Sno, CompCode, etc.)

-- Schema setup
DROP TABLE IF EXISTS retail_sales;
CREATE TABLE retail_sales ( -- use DECIMAL for currency fields
transaction_id INT PRIMARY KEY,
sale_date DATE NOT NULL,
sale_time TIME NOT NULL,
customer_id INT,
gender VARCHAR(15),
age INT,
category VARCHAR(30),
quantity INT,
price_per_unit DECIMAL(12,2),
cogs DECIMAL(12,2),
total_sale DECIMAL(14,2)
);

-- Quick peek
SELECT *
FROM retail_sales
LIMIT 10;

-- Row count
SELECT COUNT(*) AS row_count
FROM retail_sales;

-- Data quality checks
-- Identify any rows with NULLs in required fields
SELECT COUNT(*) AS null_any_required
FROM retail_sales
WHERE transaction_id IS NULL
OR sale_date IS NULL
OR sale_time IS NULL
OR gender IS NULL
OR category IS NULL
OR quantity IS NULL
OR cogs IS NULL
OR total_sale IS NULL;

-- Optional: list candidate rows for deletion
SELECT transaction_id
FROM retail_sales
WHERE transaction_id IS NULL
OR sale_date IS NULL
OR sale_time IS NULL
OR gender IS NULL
OR category IS NULL
OR quantity IS NULL
OR cogs IS NULL
OR total_sale IS NULL;

-- Enforce cleanliness
DELETE FROM retail_sales
WHERE transaction_id IS NULL
OR sale_date IS NULL
OR sale_time IS NULL
OR gender IS NULL
OR category IS NULL
OR quantity IS NULL
OR cogs IS NULL
OR total_sale IS NULL;

-- Basic exploration
-- 1) Total sales rows
SELECT COUNT(*) AS total_sales_rows
FROM retail_sales;

-- 2) Unique customers
SELECT COUNT(DISTINCT customer_id) AS unique_customers
FROM retail_sales;

-- 3) Categories present
SELECT DISTINCT category
FROM retail_sales
ORDER BY category;

/* Business questions */

-- Q1. All columns for sales on 2022-11-05
SELECT *
FROM retail_sales
WHERE sale_date = DATE '2022-11-05'
ORDER BY sale_time, transaction_id;

-- Q2. Clothing transactions with quantity > 4 in Nov-2022
-- Prefer sargable date bounds over string formatting
SELECT *
FROM retail_sales
WHERE category = 'Clothing'
AND sale_date >= DATE '2022-11-01'
AND sale_date < DATE '2022-12-01'
AND quantity > 4
ORDER BY sale_date, sale_time, transaction_id;

-- Q3. Total sales and order count by category
SELECT
category,
SUM(total_sale) AS total_sales,
COUNT(*) AS order_count
FROM retail_sales
GROUP BY category
ORDER BY total_sales DESC;

-- Q4. Average age of customers who purchased Beauty
SELECT
ROUND(AVG(age), 2) AS avg_age_beauty
FROM retail_sales
WHERE category = 'Beauty';

-- Q5. Transactions where total_sale > 1000
SELECT *
FROM retail_sales
WHERE total_sale > 1000
ORDER BY total_sale DESC, sale_date DESC, sale_time DESC, transaction_id DESC;

-- Q6. Transactions by gender in each category
SELECT
category,
gender,
COUNT(*) AS transactions
FROM retail_sales
GROUP BY category, gender
ORDER BY category, gender;

-- Q7. Average sale per month; best-selling month in each year by average sale
WITH monthly AS (
SELECT
YEAR(sale_date) AS yyyy,
MONTH(sale_date) AS mm,
AVG(total_sale) AS avg_sale
FROM retail_sales
GROUP BY YEAR(sale_date), MONTH(sale_date)
),
ranked AS (
SELECT
yyyy,
mm,
avg_sale,
RANK() OVER (PARTITION BY yyyy ORDER BY avg_sale DESC) AS rnk
FROM monthly
)
SELECT yyyy AS year, mm AS month, avg_sale
FROM ranked
WHERE rnk = 1
ORDER BY year, month;

-- Q8. Top 5 customers by total sales
SELECT
customer_id,
SUM(total_sale) AS total_sales
FROM retail_sales
GROUP BY customer_id
ORDER BY total_sales DESC
LIMIT 5;

-- Q9. Unique customers per category
SELECT
category,
COUNT(DISTINCT customer_id) AS unique_customers
FROM retail_sales
GROUP BY category
ORDER BY unique_customers DESC;

-- Q10. Order count by shift (Morning < 12, Afternoon 12–17, Evening > 17)
WITH classified AS (
SELECT
CASE
WHEN HOUR(sale_time) < 12 THEN 'Morning'
WHEN HOUR(sale_time) BETWEEN 12 AND 17 THEN 'Afternoon'
ELSE 'Evening'
END AS shift_name
FROM retail_sales
)
SELECT
shift_name AS shift,
COUNT(*) AS order_count
FROM classified
GROUP BY shift_name
ORDER BY order_count DESC;

-