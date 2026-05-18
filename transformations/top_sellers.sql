-- Question 3
-- Top 20 sellers with fasters fulfilment time

CREATE VIEW seller_fulfilment AS
WITH seller_stats AS (
	SELECT
		s.seller_id,
		s.seller_name,
		COUNT(DISTINCT o.order_id) AS total_orders,
		AVG(EXTRACT(EPOCH FROM(
			o.delivery_date::timestamp - o.order_date::timestamp)) / 3600.0) AS avg_hours,
		COALESCE(AVG(r.rating), 0) AS avg_rating
	FROM sellers s
	JOIN orders o
		ON s.seller_id = o.seller_id
	LEFT JOIN reviews r
		ON o.order_id = r.order_id
	WHERE o.delivery_date IS NOT NULL AND o.order_date IS NOT NULL
		AND o.delivery_date > o.order_date
	GROUP BY s.seller_id, s.seller_name
	HAVING COUNT(DISTINCT o.order_id) >= 20
)
SELECT
	seller_name,
	total_orders,
	ROUND(avg_hours, 2) AS avg_fulfilment_hours,
	ROUND(avg_rating, 2) AS avg_rating
FROM seller_stats
ORDER BY avg_hours ASC
LIMIT 20;
