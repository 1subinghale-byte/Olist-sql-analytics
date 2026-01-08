BEGIN TRANSACTION;

WITH o AS (
    SELECT
        order_id = LTRIM(RTRIM(REPLACE(order_id, '"',''))),
        customer_id = LTRIM(RTRIM(REPLACE(customer_id, '"',''))),
        order_status = LTRIM(RTRIM(REPLACE(order_status, '"',''))),

        purchase_ts = TRY_CAST(NULLIF(REPLACE(order_purchase_timestamp, '"',''), '') AS DATETIME2),
        approved_ts = TRY_CAST(NULLIF(REPLACE(order_approved_at, '"',''), '') AS DATETIME2),
        delivered_carrier_ts = TRY_CAST(NULLIF(REPLACE(order_delivered_carrier_date, '"',''), '') AS DATETIME2),
        delivered_customer_ts = TRY_CAST(NULLIF(REPLACE(order_delivered_customer_date, '"',''), '') AS DATETIME2),
        estimated_delivery_ts = TRY_CAST(NULLIF(REPLACE(order_estimated_delivery_date, '"',''), '') AS DATETIME2)
    FROM STG.dbo.Orders
),
cust_map AS (
    SELECT DISTINCT
        customer_id = LTRIM(RTRIM(REPLACE(customer_id, '"',''))),
        customer_unique_id = LTRIM(RTRIM(REPLACE(customer_unique_id, '"','')))
    FROM STG.dbo.Customer
),
items AS (
    SELECT
        order_id = LTRIM(RTRIM(REPLACE(order_id, '"',''))),
        item_count = COUNT(1),
        items_value = SUM(TRY_CAST(NULLIF(REPLACE(price, '"',''), '') AS DECIMAL(18,2))),
        freight_value = SUM(TRY_CAST(NULLIF(REPLACE(freight_value, '"',''), '') AS DECIMAL(18,2)))
    FROM STG.dbo.Order_Itemline
    GROUP BY LTRIM(RTRIM(REPLACE(order_id, '"','')))
),
pay AS (
    SELECT
        order_id = LTRIM(RTRIM(REPLACE(order_id, '"',''))),
        total_paid = SUM(TRY_CAST(NULLIF(REPLACE(payment_value, '"',''), '') AS DECIMAL(18,2))),
        payment_count = COUNT(1),
        max_installments = MAX(TRY_CAST(NULLIF(REPLACE(payment_installments, '"',''), '') AS INT)),

        paid_credit_card = SUM(CASE WHEN REPLACE(payment_type, '"','') = 'credit_card'
            THEN TRY_CAST(NULLIF(REPLACE(payment_value, '"',''), '') AS DECIMAL(18,2)) ELSE 0 END),

        paid_boleto = SUM(CASE WHEN REPLACE(payment_type, '"','') = 'boleto'
            THEN TRY_CAST(NULLIF(REPLACE(payment_value, '"',''), '') AS DECIMAL(18,2)) ELSE 0 END),

        paid_voucher = SUM(CASE WHEN REPLACE(payment_type, '"','') = 'voucher'
            THEN TRY_CAST(NULLIF(REPLACE(payment_value, '"',''), '') AS DECIMAL(18,2)) ELSE 0 END),

        paid_debit_card = SUM(CASE WHEN REPLACE(payment_type, '"','') = 'debit_card'
            THEN TRY_CAST(NULLIF(REPLACE(payment_value, '"',''), '') AS DECIMAL(18,2)) ELSE 0 END)
    FROM STG.dbo.Payment
    GROUP BY LTRIM(RTRIM(REPLACE(order_id, '"','')))
),
rev AS (
    SELECT
        order_id,
        review_score,
        has_review_comment
    FROM (
        SELECT
            order_id = LTRIM(RTRIM(REPLACE(order_id, '"',''))),
            review_score = TRY_CAST(NULLIF(REPLACE(review_score, '"',''), '') AS INT),
            has_review_comment =
                CASE
                    WHEN NULLIF(LTRIM(RTRIM(REPLACE(review_comment_message, '"',''))), '') IS NULL THEN 0
                    ELSE 1
                END,
            review_creation_ts = TRY_CAST(NULLIF(REPLACE(review_creation_date, '"',''), '') AS DATETIME2),
            rn = ROW_NUMBER() OVER (
                PARTITION BY LTRIM(RTRIM(REPLACE(order_id, '"','')))
                ORDER BY TRY_CAST(NULLIF(REPLACE(review_creation_date, '"',''), '') AS DATETIME2) DESC
            )
        FROM STG.dbo.Review
    ) x
    WHERE rn = 1
)
INSERT INTO Olist.Fact.Orders
(
    order_id, customer_id, customer_unique_id,
    order_status,
    purchase_ts, approved_ts, delivered_carrier_ts, delivered_customer_ts, estimated_delivery_ts,
    purchase_date, delivered_date,
    delivery_days, delivery_delay_days, is_late_delivery,
    item_count, items_value, freight_value,
    total_paid, payment_count, max_installments,
    paid_credit_card, paid_boleto, paid_voucher, paid_debit_card,
    review_score, has_review_comment,
    created_at
)
SELECT
    o.order_id,
    o.customer_id,
    cm.customer_unique_id,

    o.order_status,
    o.purchase_ts,
    o.approved_ts,
    o.delivered_carrier_ts,
    o.delivered_customer_ts,
    o.estimated_delivery_ts,

    CASE WHEN o.purchase_ts IS NULL THEN NULL ELSE CAST(o.purchase_ts AS DATE) END,
    CASE WHEN o.delivered_customer_ts IS NULL THEN NULL ELSE CAST(o.delivered_customer_ts AS DATE) END,

    CASE
        WHEN o.purchase_ts IS NULL OR o.delivered_customer_ts IS NULL
        THEN NULL
        ELSE DATEDIFF(DAY, o.purchase_ts, o.delivered_customer_ts)
    END,

    CASE
        WHEN o.delivered_customer_ts IS NULL OR o.estimated_delivery_ts IS NULL
        THEN NULL
        ELSE DATEDIFF(DAY, o.estimated_delivery_ts, o.delivered_customer_ts)
    END,

    CASE
        WHEN o.delivered_customer_ts IS NULL OR o.estimated_delivery_ts IS NULL
        THEN NULL
        WHEN o.delivered_customer_ts > o.estimated_delivery_ts THEN 1 ELSE 0
    END,

    it.item_count,
    it.items_value,
    it.freight_value,

    p.total_paid,
    p.payment_count,
    p.max_installments,

    p.paid_credit_card,
    p.paid_boleto,
    p.paid_voucher,
    p.paid_debit_card,

    r.review_score,
    r.has_review_comment,

    SYSDATETIME()
FROM o
LEFT JOIN cust_map cm ON cm.customer_id = o.customer_id
LEFT JOIN items it    ON it.order_id = o.order_id
LEFT JOIN pay p       ON p.order_id = o.order_id
LEFT JOIN rev r       ON r.order_id = o.order_id;

COMMIT;


