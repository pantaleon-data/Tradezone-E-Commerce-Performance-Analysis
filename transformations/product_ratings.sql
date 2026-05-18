-- Question 7
-- Product ratings vs sales performance

CREATE VIEW product_ratings AS
WITH product_ratings AS (
	SELECT
		p.product_id,
		AVG(r.rating) AS avg_rating,
		COUNT(DISTINCT oi.order_id) AS product_count,
		SUM(oi.quantity * oi.unit_price) AS total_revenue,
		AVG(p.unit_price) AS avg_unit_price
	FROM products p
	LEFT JOIN reviews r
		ON p.product_id = r.product_id
	JOIN order_items oi
		ON p.product_id = oi.product_id
	JOIN orders o
		ON oi.order_id = o.order_id
	GROUP BY p.product_id
)
SELECT
	CASE
		WHEN avg_rating >= 4.0 THEN 'High Rated'
		WHEN avg_rating >= 3.0 THEN 'Mid Rated'
		ELSE 'Low Rated'
	END AS rating_category,
	COUNT(product_id) AS product_count,
	ROUND(SUM(total_revenue), 2) AS total_revenue,
	ROUND(AVG(avg_unit_price), 2) AS avg_unit_price
FROM product_ratings
GROUP BY 1
ORDER BY total_revenue DESC;