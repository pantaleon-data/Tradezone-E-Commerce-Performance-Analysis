-- Question 2
-- Top 10 products by total revenue in 2024

CREATE VIEW product_performance AS
SELECT
	p.product_name,
	p.category,
	ROUND(
		SUM(oi.quantity * oi.unit_price), 2) AS total_revenue,
	COUNT(DISTINCT oi.order_id) AS total_orders
FROM products p
LEFT JOIN order_items oi
	ON p.product_id = oi.product_id
JOIN orders o
	ON oi.order_id = o.order_id
WHERE o.order_date >= '2024-01-01'
	AND o.order_date <= '2024-12-31'
GROUP BY p.product_id, p.product_name, p.category
HAVING SUM(oi.quantity * oi.unit_price) > 0
ORDER BY total_revenue DESC
LIMIT 10;
