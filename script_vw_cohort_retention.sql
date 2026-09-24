CREATE VIEW vw_cohort_retention AS
WITH first_purchase AS (
    SELECT DISTINCT ON (o.customer_id)
        o.customer_id,
        DATE_TRUNC('month', o.order_date)::DATE AS cohort_month,
        c.acquisition_channel,
        c.country,
        o.category
    FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
    WHERE o.order_status = 'Delivered' AND o.returned = 0
    ORDER BY o.customer_id, o.order_date ASC
),
customer_activities AS (
    SELECT 
        o.customer_id,
        fp.cohort_month,
        fp.acquisition_channel,
        fp.country,
        fp.category,
        DATE_TRUNC('month', o.order_date)::DATE AS order_month,
        COUNT(DISTINCT o.order_id) AS monthly_orders, -- <--- Contagem única de pedidos no mês
        SUM(o.total_amount_usd) AS monthly_revenue
    FROM orders o
    JOIN first_purchase fp ON o.customer_id = fp.customer_id
    WHERE o.order_status = 'Delivered' AND o.returned = 0
    GROUP BY o.customer_id, fp.cohort_month, fp.acquisition_channel, fp.country, fp.category, DATE_TRUNC('month', o.order_date)::DATE
),
cohort_size AS (
    SELECT 
        cohort_month,
        acquisition_channel,
        country,
        category,
        COUNT(DISTINCT customer_id) AS total_customers
    FROM first_purchase
    GROUP BY cohort_month, acquisition_channel, country, category
),
cohort_index_calc AS (
    SELECT 
        ca.cohort_month,
        ca.acquisition_channel,
        ca.country,
        ca.category,
        ca.order_month,
        (EXTRACT(YEAR FROM ca.order_month) - EXTRACT(YEAR FROM ca.cohort_month)) * 12 +
        (EXTRACT(MONTH FROM ca.order_month) - EXTRACT(MONTH FROM ca.cohort_month)) AS cohort_index,
        COUNT(DISTINCT ca.customer_id) AS active_customers,
        SUM(ca.monthly_orders) AS cohort_orders, -- <--- Soma dos pedidos da safra
        SUM(ca.monthly_revenue) AS cohort_revenue
    FROM customer_activities ca
    GROUP BY ca.cohort_month, ca.acquisition_channel, ca.country, ca.category, ca.order_month
)
SELECT 
    c.cohort_month,
    c.acquisition_channel,
    c.country,
    c.category,
    c.cohort_index,
    s.total_customers AS cohort_size,
    c.active_customers,
    c.cohort_orders, -- <--- Nova coluna disponível
    ROUND((c.active_customers::NUMERIC / s.total_customers::NUMERIC) * 100, 2) AS retention_rate_pct,
    ROUND(c.cohort_revenue::NUMERIC, 2) AS cohort_revenue
FROM cohort_index_calc c
JOIN cohort_size s 
  ON c.cohort_month = s.cohort_month 
 AND c.acquisition_channel = s.acquisition_channel 
 AND c.country = s.country 
 AND c.category = s.category
ORDER BY c.cohort_month, c.cohort_index;