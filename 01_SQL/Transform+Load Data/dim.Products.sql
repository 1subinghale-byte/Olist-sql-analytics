;WITH p AS (
    SELECT
        product_id = LTRIM(RTRIM(REPLACE(product_id, '"',''))),

        product_category_name_pt =
            NULLIF(LTRIM(RTRIM(REPLACE(product_category_name, '"',''))), ''),

        product_name_lenght =
            TRY_CAST(REPLACE(product_name_lenght, '"','') AS INT),

        product_description_lenght =
            TRY_CAST(REPLACE(product_description_lenght, '"','') AS INT),

        product_photos_qty =
            TRY_CAST(REPLACE(product_photos_qty, '"','') AS INT),

        product_weight_g =
            TRY_CAST(REPLACE(product_weight_g, '"','') AS INT),

        product_length_cm =
            TRY_CAST(REPLACE(product_length_cm, '"','') AS INT),

        product_height_cm =
            TRY_CAST(REPLACE(product_height_cm, '"','') AS INT),

        product_width_cm =
            TRY_CAST(REPLACE(product_width_cm, '"','') AS INT)
    FROM STG.dbo.Products
),
t AS (
    SELECT
        product_category_name_pt =
            NULLIF(LTRIM(RTRIM(REPLACE(product_category_name, '"',''))), ''),
        product_category_name_en =
            NULLIF(LTRIM(RTRIM(REPLACE(product_category_name_english, '"',''))), '')
    FROM STG.dbo.ProductNameTranslation
)
INSERT INTO Olist.Dim.Products
(
    product_id,
    product_category_name_pt,
    product_category_name_en,
    product_name_lenght,
    product_description_lenght,
    product_photos_qty,
    product_weight_g,
    product_length_cm,
    product_height_cm,
    product_width_cm
)
SELECT
    p.product_id,
    p.product_category_name_pt,
    t.product_category_name_en,
    p.product_name_lenght,
    p.product_description_lenght,
    p.product_photos_qty,
    p.product_weight_g,
    p.product_length_cm,
    p.product_height_cm,
    p.product_width_cm
FROM p
LEFT JOIN t
    ON t.product_category_name_pt = p.product_category_name_pt;
