-- Question 5
-- Customer spend segmentation 2024

CREATE VIEW customer_segments AS
WITH customer_spend AS(
	SELECT
		c.customer_id,
		SUM(o.total_amount) AS total_spend_2024
	FROM customers c
	JOIN orders o
		ON c.customer_id = o.customer_id
	WHERE o.order_date >= '2024-01-01'
	GROUP BY c.customer_id
)
SELECT
	CASE
		WHEN total_spend_2024 >= 100000 THEN 'High Spenders'
		WHEN total_spend_2024 >= 50000 THEN 'Medium Spenders'
		ELSE 'Low Spenders'
	END AS segment,
	COUNT(customer_id) AS customer_count,
	ROUND(AVG(total_spend_2024), 2) AS avg_spend_per_customer,
	ROUND(SUM(total_spend_2024), 2) AS total_revenue_contribution
FROM customer_spend
GROUP BY 1
ORDER BY total_revenue_contribution DESC;