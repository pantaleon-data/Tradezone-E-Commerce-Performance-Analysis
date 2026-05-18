-- ============================================================
-- TRADEZONE DATA CLEANING SCRIPT
-- HNG STAGE 2 - Data Analysis Track
-- PART A: Data Cleaning & Preparation
--
-- Objective
-- This script performs data quality checks and cleaning 
-- operations on the TradeZone e-commerce dataset before
-- anaysis queries are executed.
--
-- Cleaning tasks include:
-- handling missing values
-- detecting duplicate records
-- standardizing text formatting
-- validating numeric and data fields
-- verifying transactional totals
-- ============================================================

-- ============================================================
-- SCHEMA INSPECTION
-- ============================================================

SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'orders';

SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'customers';

SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'sellers';

SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'products';

SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'order_items';

SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'payments';

SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'reviews';

-- ============================================================
					-- DATA INSPECTION --
-- ============================================================

SELECT *
FROM customers;

SELECT *
FROM reviews;

SELECT *
FROM payments;

SELECT *
FROM orders;

SELECT *
FROM order_items;

SELECT *
FROM products;

SELECT *
FROM sellers;

-- ============================================================
				-- CHECK FOR MISSING VALUES --
-- ============================================================
-- Check for nulls in customers
-- ============================================================

SELECT *
FROM customers
WHERE city is NULL
	OR state IS NULL
	OR signup_date IS NULL;

-- ============================================================
-- Check for nulls in sellers
-- ============================================================

SELECT *
FROM sellers
WHERE seller_name IS NULL
	OR city IS NULL
	OR state IS NULL;

-- ============================================================
-- Check for nulls in order_items
-- ============================================================

SELECT *
FROM order_items
WHERE line_total IS NULL
	OR unit_price IS NULL;
-- Result: 97 nulls found
-- Missing price data breaks revenue calculations
-- solution: use matching product.unit_price from products table
-- since only 97 rows out of 6426(<1.5% of the table), the remaining nulls will be dropped.
-- because they cannot contribute to revenue calculations and would distort analysis.
UPDATE order_items oi
SET unit_price = p.unit_price
FROM products p
WHERE oi.product_id = p.product_id
	AND oi.unit_price IS NULL;
	
DELETE FROM order_items
WHERE unit_price IS NULL
	AND line_total IS NULL;

-- ============================================================
-- Check for nulls in payments
-- ============================================================

SELECT *
FROM payments
WHERE amount IS NULL;
-- Solution: aggregate order_items to order level then use it to update payments table
SELECT
	order_id,
	SUM(line_total) AS order_total
FROM order_items
GROUP BY order_id;

UPDATE payments p
SET amount = oi.order_total
FROM(
	SELECT
		order_id,
		SUM(line_total) AS order_total
	FROM order_items 
	GROUP BY order_id
) oi
WHERE p.order_id = oi.order_id
	AND p.amount IS NULL;
-- checking
SELECT 
	p.order_id
FROM payments p
LEFT JOIN order_items oi
	ON p.order_id = oi.order_id
WHERE p.amount IS NULL;
-- 12 records remain null which means they have no value in order_items so they'll be dropped
DELETE FROM payments
WHERE amount IS NULL;

-- ============================================================
-- Check for nulls in orders
-- ============================================================

SELECT *
FROM orders
WHERE delivery_date IS NULL;
-- Result: 1510 nulls
-- this can be seen as "order not yet delivered or delivery not recorded"

SELECT *
FROM orders
WHERE total_amount IS NULL;
-- Result: 150 nulls
-- Solution: reconstructing from order_items table
UPDATE orders o
SET total_amount = oi.order_total
FROM(
	SELECT
		order_id,
		SUM(line_total) AS order_total
	FROM order_items
	GROUP BY order_id
) oi
WHERE o.order_id = oi.order_id
	AND o.total_amount IS NULL;
-- checking
SELECT 
	o.order_id
FROM orders o
LEFT JOIN order_items oi
	ON o.order_id = oi.order_id
WHERE o.total_amount IS NULL;
-- 19 records remain null which means they have no value in order_items so they'll be dropped
DELETE FROM orders
WHERE total_amount IS NULL;
-- ============================================================
					-- CHECK FOR DUPLICATES --
-- ============================================================
-- Check for duplicate customers
-- ============================================================

SELECT customer_id, COUNT(*) AS customer
FROM customers
GROUP BY customer_id
HAVING COUNT(*) > 1;
-- Result: No duplicate records detected

-- ============================================================
-- Check for duplicate sellers
-- ============================================================

SELECT seller_id, COUNT(*) AS seller
FROM sellers
GROUP BY seller_id
HAVING COUNT(*) > 1;
-- Result: No duplicate records detected

-- ============================================================
-- Check for duplicate orders
-- ============================================================

SELECT order_id, COUNT(*) AS order
FROM orders
GROUP BY order_id
HAVING COUNT(*) > 1;
-- Result: No duplicate records detected

-- ============================================================
				-- STANDARDIZING TEXTS --
-- ============================================================
-- inspecting unique states

SELECT DISTINCT state
FROM customers
ORDER BY state;

SELECT DISTINCT state
FROM sellers
ORDER BY state;

-- inspecting unique cities

SELECT DISTINCT city
FROM sellers
ORDER BY city;

SELECT DISTINCT city
FROM customers
ORDER BY city;

SELECT DISTINCT category
FROM products
ORDER BY category;

-- ============================================================
-- updating the columns
-- ============================================================

UPDATE customers
SET state = 'FCT'
WHERE LOWER(TRIM(state)) IN ('fct');

UPDATE sellers
SET state = 'FCT'
WHERE LOWER(TRIM(state)) IN ('fct');

UPDATE customers
SET city = TRIM(INITCAP(city));

UPDATE sellers
SET city = TRIM(INITCAP(city));

UPDATE sellers
SET city = 'Port Harcourt'
WHERE LOWER(city) IN ('portharcourt', 'port harcourt', 'port-harcourt');

UPDATE customers
SET city = 'Port Harcourt'
WHERE LOWER(city) IN ('portharcourt', 'port harcourt', 'port-harcourt');

UPDATE sellers
SET city = 'Lagos'
WHERE city = 'Lago S';

UPDATE customers
SET city = 'Lagos'
WHERE city = 'Lago S';

UPDATE sellers
SET product_category = INITCAP(product_category);

UPDATE products
SET category = INITCAP(LOWER(TRIM(category)));

UPDATE products
SET category = CASE
	WHEN category IN ('Sports & Fitness', 'Sports And Fitness', 'Sports')
		THEN 'Sports & Fitness'
	WHEN category IN ('Home And Garden', 'Home & Garden')
		THEN 'Home & Garden'
	WHEN category IN ('Food And Beverages', 'Food & Beverages', 'Food')
		THEN 'Food & Beverages'
	WHEN category IN ('Fashion', 'Fashon')
		THEN 'Fashion'
	WHEN category IN ('Electronis', 'Electronics')
		THEN 'Electronics'
	WHEN category IN ('Books And Stationery', 'Books & Stationery', 'Books')
		THEN 'Books & Stationery'
	WHEN category IN ('Beauty And Personal Care', 'Beauty & Personal Care', 'Beauty')
		THEN 'Beauty & Personal Care'
	ELSE category
END;

UPDATE sellers
SET product_category = CASE
	WHEN product_category IN ('Sports & Fitness', 'Sports And Fitness', 'Sports')
		THEN 'Sports & Fitness'
	WHEN product_category IN ('Home And Garden', 'Home & Garden')
		THEN 'Home & Garden'
	WHEN product_category IN ('Food And Beverages', 'Food & Beverages', 'Food')
		THEN 'Food & Beverages'
	WHEN product_category IN ('Fashion', 'Fashon')
		THEN 'Fashion'
	WHEN product_category IN ('Electronis', 'Electronics')
		THEN 'Electronics'
	WHEN product_category IN ('Books And Stationery', 'Books & Stationery', 'Books')
		THEN 'Books & Stationery'
	WHEN product_category IN ('Beauty And Personal Care', 'Beauty & Personal Care', 'Beauty')
		THEN 'Beauty & Personal Care'
	ELSE product_category
END;

-- ============================================================
-- Validating review ratings
-- ============================================================

SELECT *
FROM reviews
WHERE rating < 1
	OR rating > 5;
-- Result: 5 rows (4 -lt 1, 1 -gt 5)
-- Decision: removing rows where rating < 1 or > 5
-- Reason: ratings must fall within the valid 1-5 scale.

DELETE FROM reviews
WHERE rating < 1
	OR rating > 5;

-- ============================================================
-- Validating product prices
-- ============================================================

SELECT *
FROM products
WHERE unit_price < 0;
-- Result: None

-- ============================================================
-- Validating order totals
-- ============================================================

SELECT
	o.order_id,
	o.total_amount,
	SUM(oi.quantity * oi.unit_price) AS calculated_total,
	ABS(o.total_amount - SUM(oi.quantity * oi.unit_price)) AS difference
FROM orders o
JOIN order_items oi
ON o.order_id = oi.order_id
GROUP BY o.order_id, o.total_amount
HAVING ABS(o.total_amount - SUM(oi.quantity * oi.unit_price)) > 10;

-- Orders returned by this query have discrepancies grater than 10 naira between
-- recorded orders total and order_item totals.
-- These orders are flagged for further review.