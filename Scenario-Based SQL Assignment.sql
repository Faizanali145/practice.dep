                                   -- Task 1 — 

SELECT
    o.order_id,
    o.order_date,


    c.first_name + ' ' + c.last_name AS customer_name,

    s.store_name,

    st.first_name + ' ' + st.last_name AS staff_name,

    p.product_name,

    cat.category_name,

    b.brand_name,

    oi.quantity,
    oi.list_price,
    oi.discount,

    oi.quantity * oi.list_price * (1 - oi.discount)
        AS net_line_revenue

FROM sales.orders AS o

    INNER JOIN sales.customers AS c
    ON o.customer_id = c.customer_id


INNER JOIN sales.stores AS s
    ON o.store_id = s.store_id

INNER JOIN sales.staffs AS st
    ON o.staff_id = st.staff_id

INNER JOIN sales.order_items AS oi
    ON o.order_id = oi.order_id



INNER JOIN production.products AS p
       ON oi.product_id = p.product_id

INNER JOIN production.categories AS cat
       ON p.category_id = cat.category_id

INNER JOIN production.brands AS b
    ON p.brand_id = b.brand_id



WHERE o.order_status = 4
    

ORDER BY o.order_date DESC;


                                   -- Task 2 — 

SELECT
    s.store_name,

    COUNT(DISTINCT o.order_id) AS number_of_orders,

    SUM(oi.quantity) AS total_units_sold,

    SUM(
        oi.quantity * oi.list_price * (1 - oi.discount)
    ) AS total_net_revenue,

    SUM(
        oi.quantity * oi.list_price * (1 - oi.discount)
    ) / COUNT(DISTINCT o.order_id) AS average_order_value

FROM sales.orders AS o

INNER JOIN sales.stores AS s
    ON o.store_id = s.store_id

INNER JOIN sales.order_items AS oi
    ON o.order_id = oi.order_id

WHERE o.order_status = 4

GROUP BY s.store_id, s.store_name

ORDER BY total_net_revenue DESC;

                            
                                   -- Task 3 --
SELECT
    c.customer_id,

    c.first_name + ' ' + c.last_name AS customer_name,

    COUNT(DISTINCT o.order_id) AS completed_order_count,

    SUM(
        oi.quantity * oi.list_price * (1 - oi.discount)
    ) AS total_spending

FROM sales.customers AS c

INNER JOIN sales.orders AS o
    ON c.customer_id = o.customer_id

INNER JOIN sales.order_items AS oi
    ON o.order_id = oi.order_id

WHERE o.order_status = 4

GROUP BY
    c.customer_id,
    c.first_name,
    c.last_name

HAVING
    SUM(
        oi.quantity * oi.list_price * (1 - oi.discount)
    ) >
    (
        SELECT AVG(customer_total)
        FROM
        (
            SELECT
                o2.customer_id,
                SUM(
                    oi2.quantity * oi2.list_price * (1 - oi2.discount)
                ) AS customer_total
            FROM sales.orders AS o2

            INNER JOIN sales.order_items AS oi2
                ON o2.order_id = oi2.order_id

            WHERE o2.order_status = 4

            GROUP BY o2.customer_id
        ) AS customer_spending
    )

ORDER BY total_spending DESC;



                                   -- Task 4 — 

SELECT
    p.product_name,
    s.store_name,
    st.quantity AS current_quantity,
    c.category_name,
    b.brand_name

FROM production.stocks AS st

INNER JOIN production.products AS p
    ON st.product_id = p.product_id

INNER JOIN sales.stores AS s
    ON st.store_id = s.store_id

INNER JOIN production.categories AS c
    ON p.category_id = c.category_id

INNER JOIN production.brands AS b
    ON p.brand_id = b.brand_id

WHERE st.quantity < 5

ORDER BY
    st.quantity ASC;


                                    --   Task 5 —--

WITH ProductRevenue AS
(
    SELECT
        c.category_name,
        p.product_name,

        SUM(oi.quantity) AS total_units_sold,

        SUM(
            oi.quantity * oi.list_price * (1 - oi.discount)
        ) AS total_net_revenue

    FROM sales.order_items AS oi

    INNER JOIN sales.orders AS o
        ON oi.order_id = o.order_id

    INNER JOIN production.products AS p
        ON oi.product_id = p.product_id

    INNER JOIN production.categories AS c
        ON p.category_id = c.category_id

    WHERE o.order_status = 4   -- Completed orders

    GROUP BY
        c.category_name,
        p.product_name
),

RankedProducts AS
(
    SELECT
        category_name,
        product_name,
        total_units_sold,
        total_net_revenue,

        DENSE_RANK() OVER
        (
            PARTITION BY category_name
            ORDER BY total_net_revenue DESC
        ) AS product_position

    FROM ProductRevenue
)

SELECT
    category_name,
    product_name,
    total_units_sold,
    total_net_revenue,
    product_position
FROM RankedProducts
WHERE product_position <= 3
ORDER BY
    category_name,
    product_position

                                    -- Task 6 — 
WITH MonthlySales AS
(
    SELECT
        YEAR(o.order_date) AS year,
        MONTH(o.order_date) AS month,

        SUM(
            oi.quantity * oi.list_price * (1 - oi.discount)
        ) AS total_net_revenue

    FROM sales.orders AS o

    INNER JOIN sales.order_items AS oi
        ON o.order_id = oi.order_id

    WHERE o.order_status = 4   

    GROUP BY
        YEAR(o.order_date),
        MONTH(o.order_date)
),

SalesWithPrevious AS
(
    SELECT
        year,
        month,
        total_net_revenue,

        LAG(total_net_revenue) OVER
        (
            ORDER BY year, month
        ) AS previous_month_revenue

    FROM MonthlySales
)

SELECT
    year,
    month,
    total_net_revenue,
    previous_month_revenue,

    total_net_revenue - previous_month_revenue
        AS revenue_change

FROM SalesWithPrevious

ORDER BY
    year,
    month;
    select product_name

    from production.products

    


                                   -- Task 7 — 
CREATE VIEW sales.vw_customer_sales_summary
AS
SELECT
    c.customer_id,

    CONCAT(c.first_name, ' ', c.last_name) AS customer_full_name,

    COUNT(DISTINCT o.order_id) AS total_completed_orders,

    COALESCE(SUM(oi.quantity), 0) AS total_units_purchased,

    COALESCE(
        SUM(
            oi.quantity * oi.list_price * (1 - oi.discount)
        ), 0
    ) AS total_net_revenue,

    MAX(o.order_date) AS most_recent_completed_order_date

FROM sales.customers AS c

LEFT JOIN sales.orders AS o
    ON c.customer_id = o.customer_id
    AND o.order_status = 4       

LEFT JOIN sales.order_items AS oi
    ON o.order_id = oi.order_id

GROUP BY
    c.customer_id,
    c.first_name,
    c.last_name;


    SELECT *
FROM sales.vw_customer_sales_summary;


                                    -- Task 8 — 
BEGIN TRANSACTION;

-- Update customer's phone number
UPDATE sales.customers
SET phone = '(999) 555-0101'
WHERE customer_id = 1;

-- Validation query
SELECT
    customer_id,
    first_name,
    last_name,
    phone
FROM sales.customers
WHERE customer_id = 1;

-- Testing only:
-- Undo the change so the database is not permanently modified
ROLLBACK TRANSACTION;   

                                   -- Task 9 — 

CREATE PROCEDURE sales.usp_store_sales_report
    @store_id INT,
    @start_date DATE,
    @end_date DATE
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY

      
        IF @start_date > @end_date
        BEGIN
            THROW 50001, 'Invalid date range: start date cannot be later than end date.', 1;
        END;

       
        SELECT
            p.product_name,

            SUM(oi.quantity) AS total_units_sold,

            SUM(
                oi.quantity * oi.list_price * (1 - oi.discount)
            ) AS total_net_revenue




            

        FROM sales.orders AS o

        INNER JOIN sales.order_items AS oi
            ON o.order_id = oi.order_id

        INNER JOIN production.products AS p
            ON oi.product_id = p.product_id

        WHERE o.store_id = @store_id
          AND o.order_status = 4
          AND o.order_date >= @start_date
          AND o.order_date < DATEADD(DAY, 1, @end_date)

        GROUP BY
            p.product_id,
            p.product_name

        ORDER BY
            total_net_revenue DESC;

    END TRY

    BEGIN CATCH

        SELECT
            ERROR_MESSAGE() AS error_message;

    END CATCH;
END;







                                   -- Task 10: 

SELECT 
    c.customer_id,
    c.first_name + ' ' + c.last_name AS customer_name,
    COUNT(DISTINCT o.order_id) AS total_orders,
    SUM(oi.quantity * oi.list_price * (1 - oi.discount)) AS total_spending
FROM sales.customers AS c
INNER JOIN sales.orders AS o
    ON c.customer_id = o.customer_id
INNER JOIN sales.order_items AS oi
    ON o.order_id = oi.order_id
GROUP BY 
    c.customer_id,
    c.first_name,
    c.last_name
ORDER BY total_spending DESC;
