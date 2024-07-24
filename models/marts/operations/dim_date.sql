{{ config(materialized='table') }}
WITH date_generation AS (
SELECT
        DATE(DATEADD(DAY, SEQ4(), '2016-01-01')) AS date, 
FROM TABLE(GENERATOR(ROWCOUNT => 30681))
)
SELECT
    date,
    EXTRACT(YEAR FROM date) AS year,
    EXTRACT(MONTH FROM date) AS month,
    EXTRACT(DAY FROM date) AS day,
    DAYOFWEEK(date) AS day_of_week,
    WEEKOFYEAR(date) AS week_of_year
FROM date_generation