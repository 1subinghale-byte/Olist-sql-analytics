;WITH oi AS (
    SELECT
        order_id      = LTRIM(RTRIM(REPLACE(order_id, '"',''))),
        order_item_id = TRY_CAST(REPLACE(order_item_id, '"','') AS INT),

        product_id    = NULLIF(LTRIM(RTRIM(REPLACE(product_id, '"',''))), ''),
        seller_id     = NULLIF(LTRIM(RTRIM(REPLACE(seller_id, '"',''))), ''),

        shipping_limit_ts =
            TRY_CAST(REPLACE(shipping_limit_date, '"','') AS DATETIME2),

        price         =
            TRY_CAST(REPLACE(price, '"','') AS DECIMAL(18,2)),

        freight_value =
            TRY_CAST(REPLACE(freight_value, '"','') AS DECIMAL(18,2))
    FROM STG.dbo.Order_ItemLine
)
INSERT INTO Fact.ItemLine
(
    order_id,
    order_item_id,
    product_id,
    seller_id,
    SKProductId,
    SKSellerId,
    shipping_limit_ts,
    price,
    freight_value
)
SELECT
    oi.order_id,
    oi.order_item_id,
    oi.product_id,
    oi.seller_id,

    p.SKProductId,
    s.SKSellerId,

    oi.shipping_limit_ts,
    oi.price,
    oi.freight_value
FROM oi
LEFT JOIN Dim.Products p
    ON p.product_id = oi.product_id
LEFT JOIN Dim.Sellers s
    ON s.seller_id = oi.seller_id
WHERE oi.order_id IS NOT NULL
  AND oi.order_item_id IS NOT NULL;

