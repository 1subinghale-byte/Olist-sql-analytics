DECLARE @StartDate DATE, @EndDate DATE;

SELECT
    @StartDate = MIN(d),
    @EndDate   = MAX(d)
FROM (
    SELECT MIN(purchase_date)  AS d FROM Fact.Orders
    UNION ALL
    SELECT MAX(purchase_date)  AS d FROM Fact.Orders
    UNION ALL
    SELECT MIN(delivered_date) AS d FROM Fact.Orders
    UNION ALL
    SELECT MAX(delivered_date) AS d FROM Fact.Orders
) x;




IF @StartDate IS NULL SET @StartDate = '2016-01-01';
IF @EndDate   IS NULL SET @EndDate   = '2019-12-31';

;WITH n AS (
    SELECT TOP (DATEDIFF(DAY, @StartDate, @EndDate) + 1)
           ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1 AS i
    FROM sys.all_objects
)
,
d AS (
    SELECT DATEADD(DAY, i, @StartDate) AS [Date]
    FROM n
)
INSERT INTO Dim.Dates
(
    DateSK, [Date],
    [Year], [Quarter], [Month], [MonthName],
    [DayOfMonth], [DayOfWeek], [DayName],
    [WeekOfYear], [IsWeekend]
)
SELECT
    CONVERT(INT, FORMAT([Date], 'yyyyMMdd')) AS DateSK,
    [Date],
    YEAR([Date])        AS [Year],
    DATEPART(QUARTER, [Date]) AS [Quarter],
    MONTH([Date])       AS [Month],
    DATENAME(MONTH, [Date]) AS [MonthName],
    DAY([Date])         AS [DayOfMonth],

    DATEPART(WEEKDAY, [Date]) AS [DayOfWeek],     -- ISO-like due to DATEFIRST=1
    DATENAME(WEEKDAY, [Date]) AS [DayName],

    DATEPART(ISO_WEEK, [Date]) AS [WeekOfYear],

    CASE WHEN DATEPART(WEEKDAY, [Date]) IN (6,7) THEN 1 ELSE 0 END AS [IsWeekend]
FROM d;




