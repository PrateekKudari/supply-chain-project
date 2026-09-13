CREATE DATABASE home;
USE home;
-- Overview of data 
SELECT * FROM supplychain
LIMIT 10;

-- Total number of orders
SELECT COUNT(DISTINCT `Order Id`) AS total_orders
FROM supplychain; 

-- Total sales
SELECT 
    ROUND(SUM(Sales), 2) AS total_sales
FROM supplychain;

-- Sales by product category

SELECT
    `Category Name`,
    ROUND(SUM(Sales), 2) AS total_sales
FROM supplychain
GROUP BY `Category Name`
ORDER BY total_sales DESC;

-- Orders by shipping mode
SELECT
    `Shipping Mode`,
    COUNT(DISTINCT `Order Id`) AS total_orders
FROM supplychain
GROUP BY `Shipping Mode`
ORDER BY total_orders DESC;

-- Monthly sales
SELECT
    DATE_FORMAT(`order date (DateOrders)`, '%Y-%m') AS month,
    ROUND(SUM(Sales), 2) AS total_sales
FROM supplychain
GROUP BY DATE_FORMAT(`order date (DateOrders)`, '%Y-%m')
ORDER BY month;

-- Top 10 products by sales
SELECT
    `Product Name`,
    ROUND(SUM(Sales), 2) AS total_sales
FROM supplychain
GROUP BY `Product Name`
ORDER BY total_sales DESC
LIMIT 10;

-- Profit by category
SELECT
    `Category Name`,
    ROUND(SUM(`Order Profit Per Order`), 2) AS total_profit
FROM supplychain
GROUP BY `Category Name`
ORDER BY total_profit DESC;

-- Average order value
SELECT
    ROUND(
        SUM(Sales) / COUNT(DISTINCT `Order Id`),
        2
    ) AS average_order_value
FROM supplychain;

-- Customer segment performance
SELECT
    `Customer Segment`,
    COUNT(DISTINCT `Order Id`) AS total_orders,
    ROUND(SUM(Sales), 2) AS total_sales,
    ROUND(SUM(`Order Profit Per Order`), 2) AS total_profit
FROM supplychain
GROUP BY `Customer Segment`
ORDER BY total_sales DESC;

-- Regional sales performance
SELECT
    `Order Region`,
    COUNT(DISTINCT `Order Id`) AS total_orders,
    ROUND(SUM(Sales), 2) AS total_sales,
    ROUND(SUM(`Order Profit Per Order`), 2) AS total_profit
FROM supplychain
GROUP BY `Order Region`
ORDER BY total_sales DESC;

-- Late delivery analysis
SELECT
    `Delivery Status`,
    COUNT(DISTINCT `Order Id`) AS total_orders,
    ROUND(
        COUNT(DISTINCT `Order Id`) * 100.0 /
        (SELECT COUNT(DISTINCT `Order Id`) FROM supplychain),
        2
    ) AS order_percentage
FROM supplychain
GROUP BY `Delivery Status`;

-- Average shipping time
SELECT
    `Shipping Mode`,
    ROUND(AVG(`Days for shipping (real)`), 2) AS avg_shipping_days
FROM supplychain
GROUP BY `Shipping Mode`
ORDER BY avg_shipping_days;

-- Products with high discount
SELECT
    `Product Name`,
    ROUND(AVG(`Order Item Discount Rate`) * 100, 2) AS avg_discount_percentage,
    ROUND(SUM(Sales), 2) AS total_sales
FROM supplychain
GROUP BY `Product Name`
HAVING AVG(`Order Item Discount Rate`) > 0.20
ORDER BY avg_discount_percentage DESC;

-- High-risk delivery orders
SELECT
    COUNT(DISTINCT `Order Id`) AS high_risk_orders
FROM supplychain
WHERE Late_delivery_risk = 1;

-- Rank products by sales
SELECT
    `Product Name`,
    ROUND(SUM(Sales), 2) AS total_sales,
    RANK() OVER (
        ORDER BY SUM(Sales) DESC
    ) AS sales_rank
FROM supplychain
GROUP BY `Product Name`;

-- Top 3 products in each category
WITH product_sales AS (
    SELECT
        `Category Name`,
        `Product Name`,
        SUM(Sales) AS total_sales
    FROM supplychain
    GROUP BY
        `Category Name`,
        `Product Name`
),
ranked_products AS (
    SELECT
        *,
        DENSE_RANK() OVER (
            PARTITION BY `Category Name`
            ORDER BY total_sales DESC
        ) AS product_rank
    FROM product_sales
)
SELECT
    `Category Name`,
    `Product Name`,
    ROUND(total_sales, 2) AS total_sales,
    product_rank
FROM ranked_products
WHERE product_rank <= 3
ORDER BY `Category Name`, product_rank;

-- Monthly sales growth
WITH monthly_sales AS (
    SELECT
        DATE_FORMAT(`order date (DateOrders)`, '%Y-%m') AS month,
        SUM(Sales) AS total_sales
    FROM supplychain
    GROUP BY DATE_FORMAT(`order date (DateOrders)`, '%Y-%m')
),
sales_with_previous AS (
    SELECT
        month,
        total_sales,
        LAG(total_sales) OVER (
            ORDER BY month
        ) AS previous_month_sales
    FROM monthly_sales
)
SELECT
    month,
    ROUND(total_sales, 2) AS total_sales,
    ROUND(previous_month_sales, 2) AS previous_month_sales,
    ROUND(
        (total_sales - previous_month_sales)
        / previous_month_sales * 100,
        2
    ) AS growth_percentage
FROM sales_with_previous
ORDER BY month;

-- Running total of sales
WITH monthly_sales AS (
    SELECT
        DATE_FORMAT(`order date (DateOrders)`, '%Y-%m') AS month,
        SUM(Sales) AS total_sales
    FROM supplychain
    GROUP BY DATE_FORMAT(`order date (DateOrders)`, '%Y-%m')
)
SELECT
    month,
    ROUND(total_sales, 2) AS monthly_sales,
    ROUND(
        SUM(total_sales) OVER (
            ORDER BY month
        ),
        2
    ) AS cumulative_sales
FROM monthly_sales
ORDER BY month;

-- Category contribution to total sales
WITH category_sales AS (
    SELECT
        `Category Name`,
        SUM(Sales) AS category_sales
    FROM supplychain
    GROUP BY `Category Name`
)
SELECT
    `Category Name`,
    ROUND(category_sales, 2) AS category_sales,
    ROUND(
        category_sales * 100.0 /
        SUM(category_sales) OVER (),
        2
    ) AS sales_percentage
FROM category_sales
ORDER BY category_sales DESC;

-- Customer revenue ranking
WITH customer_sales AS (
    SELECT
        `Customer Id`,
        SUM(Sales) AS total_sales
    FROM supplychain
    GROUP BY `Customer Id`
)
SELECT
    `Customer Id`,
    ROUND(total_sales, 2) AS total_sales,
    RANK() OVER (
        ORDER BY total_sales DESC
    ) AS customer_rank
FROM customer_sales
ORDER BY customer_rank;

-- High-value customers
WITH customer_sales AS (
    SELECT
        `Customer Id`,
        SUM(Sales) AS total_sales
    FROM supplychain
    GROUP BY `Customer Id`
)
SELECT
    `Customer Id`,
    ROUND(total_sales, 2) AS total_sales
FROM customer_sales
WHERE total_sales > (
    SELECT AVG(total_sales)
    FROM customer_sales
)
ORDER BY total_sales DESC;

-- Repeat customers
SELECT
    `Customer Id`,
    COUNT(DISTINCT `Order Id`) AS total_orders,
    ROUND(SUM(Sales), 2) AS total_sales
FROM supplychain
GROUP BY `Customer Id`
HAVING COUNT(DISTINCT `Order Id`) > 1
ORDER BY total_orders DESC;

-- Average delivery delay
SELECT
    `Shipping Mode`,
    ROUND(
        AVG(
            `Days for shipping (real)`
            - `Days for shipment (scheduled)`
        ),
        2
    ) AS avg_delivery_delay
FROM supplychain
GROUP BY `Shipping Mode`
ORDER BY avg_delivery_delay DESC;

-- Delivery performance by region
SELECT
    `Order Region`,
    COUNT(DISTINCT `Order Id`) AS total_orders,
    SUM(
        CASE
            WHEN Late_delivery_risk = 1 THEN 1
            ELSE 0
        END
    ) AS high_risk_orders,
    ROUND(
        SUM(
            CASE
                WHEN Late_delivery_risk = 1 THEN 1
                ELSE 0
            END
        ) * 100.0 /
        COUNT(DISTINCT `Order Id`),
        2
    ) AS risk_percentage
FROM supplychain
GROUP BY `Order Region`
ORDER BY risk_percentage DESC;

-- Product profitability
SELECT
    `Product Name`,
    ROUND(SUM(Sales), 2) AS total_sales,
    ROUND(SUM(`Order Profit Per Order`), 2) AS total_profit,
    ROUND(
        SUM(`Order Profit Per Order`) * 100.0 /
        SUM(Sales),
        2
    ) AS profit_margin_percentage
FROM supplychain
GROUP BY `Product Name`
HAVING SUM(Sales) > 0
ORDER BY profit_margin_percentage DESC;

-- 3-month moving average of sales
WITH monthly_sales AS (
    SELECT
        DATE_FORMAT(`order date (DateOrders)`, '%Y-%m') AS month,
        SUM(Sales) AS total_sales
    FROM supplychain
    GROUP BY DATE_FORMAT(`order date (DateOrders)`, '%Y-%m')
)
SELECT
    month,
    ROUND(total_sales, 2) AS monthly_sales,
    ROUND(
        AVG(total_sales) OVER (
            ORDER BY month
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ),
        2
    ) AS three_month_moving_average
FROM monthly_sales
ORDER BY month;

-- ABC-style product classification
WITH product_sales AS (
    SELECT
        `Product Name`,
        SUM(Sales) AS total_sales
    FROM supplychain
    GROUP BY `Product Name`
),
ranked_products AS (
    SELECT
        *,
        SUM(total_sales) OVER (
            ORDER BY total_sales DESC
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS cumulative_sales,
        SUM(total_sales) OVER () AS overall_sales
    FROM product_sales
)
SELECT
    `Product Name`,
    ROUND(total_sales, 2) AS total_sales,
    ROUND(
        cumulative_sales * 100.0 / overall_sales,
        2
    ) AS cumulative_percentage,
    CASE
        WHEN cumulative_sales / overall_sales <= 0.80
            THEN 'A'
        WHEN cumulative_sales / overall_sales <= 0.95
            THEN 'B'
        ELSE 'C'
    END AS product_class
FROM ranked_products
ORDER BY total_sales DESC;

-- Identify products with high sales but low profit
WITH product_performance AS (
    SELECT
        `Product Name`,
        SUM(Sales) AS total_sales,
        SUM(`Order Profit Per Order`) AS total_profit
    FROM supplychain
    GROUP BY `Product Name`
)
SELECT
    `Product Name`,
    ROUND(total_sales, 2) AS total_sales,
    ROUND(total_profit, 2) AS total_profit
FROM product_performance
WHERE total_sales > (
    SELECT AVG(total_sales)
    FROM product_performance
)
AND total_profit < (
    SELECT AVG(total_profit)
    FROM product_performance
)
ORDER BY total_sales DESC;

-- Regional monthly sales ranking
WITH regional_monthly_sales AS (
    SELECT
        `Order Region`,
        DATE_FORMAT(`order date (DateOrders)`, '%Y-%m') AS month,
        SUM(Sales) AS total_sales
    FROM supplychain
    GROUP BY
        `Order Region`,
        DATE_FORMAT(`order date (DateOrders)`, '%Y-%m')
)
SELECT
    `Order Region`,
    month,
    ROUND(total_sales, 2) AS total_sales,
    RANK() OVER (
        PARTITION BY month
        ORDER BY total_sales DESC
    ) AS regional_rank
FROM regional_monthly_sales
ORDER BY month, regional_rank;
