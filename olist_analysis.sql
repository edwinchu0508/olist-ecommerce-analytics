-- ============================================================
-- Olist E-commerce Analysis
-- PostgreSQL
-- ============================================================

-- 1. Order status distribution
SELECT
    order_status,
    COUNT(*) AS num_orders
FROM orders
GROUP BY order_status
ORDER BY num_orders DESC;


-- 2. Monthly order volume
SELECT
    DATE_TRUNC('month', order_purchase_timestamp) AS month,
    COUNT(*) AS monthly_orders
FROM orders
GROUP BY DATE_TRUNC('month', order_purchase_timestamp)
ORDER BY month;


-- 3. Top 10 product categories by items sold
SELECT
    p.product_category_name,
    COUNT(*) AS items_sold
FROM order_items AS oi
LEFT JOIN products AS p
    USING (product_id)
GROUP BY p.product_category_name
ORDER BY items_sold DESC
LIMIT 10;


-- 4. Top 10 product categories by merchandise revenue
SELECT
    p.product_category_name,
    SUM(oi.price) AS category_revenue
FROM order_items AS oi
INNER JOIN products AS p
    USING (product_id)
GROUP BY p.product_category_name
ORDER BY category_revenue DESC
LIMIT 10;


-- 5. Top 10 states by customer count
SELECT
    customer_state,
    COUNT(*) AS num_customers
FROM customers
GROUP BY customer_state
ORDER BY num_customers DESC
LIMIT 10;


-- 6. Top 10 states by merchandise revenue
WITH order_item_detail AS (
    SELECT
        o.customer_id,
        oi.order_id,
        oi.price
    FROM orders AS o
    INNER JOIN order_items AS oi
        USING (order_id)
)
SELECT
    c.customer_state,
    SUM(oid.price) AS state_revenue
FROM customers AS c
INNER JOIN order_item_detail AS oid
    USING (customer_id)
GROUP BY c.customer_state
ORDER BY state_revenue DESC
LIMIT 10;


-- 7. Average order value by state
WITH order_totals AS (
    SELECT
        order_id,
        SUM(price) AS order_total
    FROM order_items
    GROUP BY order_id
),
order_customer_totals AS (
    SELECT
        o.customer_id,
        o.order_id,
        ot.order_total
    FROM orders AS o
    INNER JOIN order_totals AS ot
        USING (order_id)
)
SELECT
    c.customer_state,
    AVG(oct.order_total) AS avg_order_value
FROM customers AS c
INNER JOIN order_customer_totals AS oct
    USING (customer_id)
GROUP BY c.customer_state
ORDER BY avg_order_value DESC
LIMIT 10;


-- 8. Delivery status and average review score
WITH delivery_reviews AS (
    SELECT
        o.order_delivered_customer_date,
        o.order_estimated_delivery_date,
        r.review_score
    FROM orders AS o
    INNER JOIN reviews AS r
        USING (order_id)
),
delivery_status AS (
    SELECT
        CASE
            WHEN order_delivered_customer_date IS NULL THEN 'not delivered'
            WHEN order_delivered_customer_date <= order_estimated_delivery_date THEN 'on time'
            ELSE 'late'
        END AS delivery_status,
        review_score
    FROM delivery_reviews
)
SELECT
    delivery_status,
    AVG(review_score) AS avg_review_score,
    COUNT(*) AS num_orders
FROM delivery_status
GROUP BY delivery_status
ORDER BY avg_review_score;


-- 9. Delay severity and average review score
WITH delivery_reviews AS (
    SELECT
        o.order_delivered_customer_date,
        o.order_estimated_delivery_date,
        r.review_score
    FROM orders AS o
    INNER JOIN reviews AS r
        USING (order_id)
),
delay_buckets AS (
    SELECT
        CASE
            WHEN order_delivered_customer_date IS NULL THEN 'not delivered'
            WHEN (order_delivered_customer_date::date - order_estimated_delivery_date::date) <= 0
                THEN 'on time'
            WHEN (order_delivered_customer_date::date - order_estimated_delivery_date::date) <= 3
                THEN '1-3 days late'
            WHEN (order_delivered_customer_date::date - order_estimated_delivery_date::date) <= 7
                THEN '4-7 days late'
            ELSE '8+ days late'
        END AS delay_bucket,
        review_score
    FROM delivery_reviews
)
SELECT
    delay_bucket,
    AVG(review_score) AS avg_review_score,
    COUNT(*) AS num_orders
FROM delay_buckets
GROUP BY delay_bucket
ORDER BY avg_review_score;


-- 10. Monthly revenue and month-over-month growth
WITH monthly_revenue AS (
    SELECT
        DATE_TRUNC('month', o.order_purchase_timestamp) AS month,
        SUM(oi.price) AS monthly_revenue
    FROM orders AS o
    INNER JOIN order_items AS oi
        USING (order_id)
    GROUP BY DATE_TRUNC('month', o.order_purchase_timestamp)
),
revenue_with_lag AS (
    SELECT
        month,
        monthly_revenue,
        LAG(monthly_revenue) OVER (ORDER BY month) AS previous_month_revenue
    FROM monthly_revenue
)
SELECT
    month,
    monthly_revenue,
    previous_month_revenue,
    monthly_revenue - previous_month_revenue AS revenue_change,
    ROUND(
        ((monthly_revenue - previous_month_revenue) / previous_month_revenue) * 100,
        2
    ) AS mom_growth_pct
FROM revenue_with_lag
ORDER BY month;


-- 11. Customer cohort retention analysis
WITH delivered_customer_orders AS (
    SELECT
        c.customer_unique_id,
        o.order_purchase_timestamp
    FROM customers AS c
    INNER JOIN orders AS o
        USING (customer_id)
    WHERE o.order_status = 'delivered'
),
first_purchase AS (
    SELECT
        customer_unique_id,
        DATE_TRUNC('month', MIN(order_purchase_timestamp)) AS cohort_month
    FROM delivered_customer_orders
    GROUP BY customer_unique_id
),
customer_purchase_months AS (
    SELECT
        dco.customer_unique_id,
        fp.cohort_month,
        DATE_TRUNC('month', dco.order_purchase_timestamp) AS purchase_month
    FROM delivered_customer_orders AS dco
    INNER JOIN first_purchase AS fp
        USING (customer_unique_id)
),
cohort_activity AS (
    SELECT
        customer_unique_id,
        cohort_month,
        purchase_month,
        (
            EXTRACT(YEAR FROM purchase_month) - EXTRACT(YEAR FROM cohort_month)
        ) * 12
        +
        (
            EXTRACT(MONTH FROM purchase_month) - EXTRACT(MONTH FROM cohort_month)
        ) AS month_number
    FROM customer_purchase_months
),
active_customers_by_month AS (
    SELECT
        cohort_month,
        month_number,
        COUNT(DISTINCT customer_unique_id) AS active_customers
    FROM cohort_activity
    GROUP BY cohort_month, month_number
),
cohort_sizes AS (
    SELECT
        cohort_month,
        month_number,
        active_customers,
        MAX(
            CASE
                WHEN month_number = 0 THEN active_customers
            END
        ) OVER (PARTITION BY cohort_month) AS cohort_size
    FROM active_customers_by_month
)
SELECT
    cohort_month,
    month_number,
    active_customers,
    cohort_size,
    ROUND(active_customers * 100.0 / cohort_size, 2) AS retention_rate_pct
FROM cohort_sizes
ORDER BY cohort_month, month_number;
