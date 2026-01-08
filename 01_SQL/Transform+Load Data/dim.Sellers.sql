-- Load Sellers 
INSERT INTO Dim.Sellers (seller_id, City, State, Zipcode)
SELECT
    seller_id = LTRIM(RTRIM(REPLACE(seller_id, '"',''))),

    City = UPPER(
            LTRIM(RTRIM(
                REPLACE(seller_city, '"','')
            ))
          ),

    State = UPPER(
        LTRIM(RTRIM(
            CASE
                WHEN CHARINDEX(',', clean_state) > 0
                THEN RIGHT(
                        clean_state,
                        CHARINDEX(',', REVERSE(clean_state)) - 1
                     )
                ELSE clean_state
            END
        ))
    ),

    Zipcode = TRY_CAST(REPLACE(seller_zip_code_prefix, '"','') AS INT)

FROM (
    SELECT
        seller_id,
        seller_city,
        clean_state = LTRIM(RTRIM(REPLACE(seller_state, '"',''))),
        seller_zip_code_prefix
    FROM STG.dbo.Sellers
) s
GROUP BY
    LTRIM(RTRIM(REPLACE(seller_id, '"',''))),
    UPPER(LTRIM(RTRIM(REPLACE(seller_city, '"','')))),
    UPPER(
        LTRIM(RTRIM(
            CASE
                WHEN CHARINDEX(',', clean_state) > 0
                THEN RIGHT(
                        clean_state,
                        CHARINDEX(',', REVERSE(clean_state)) - 1
                     )
                ELSE clean_state
            END
        ))
    ),
    TRY_CAST(REPLACE(seller_zip_code_prefix, '"','') AS INT);
