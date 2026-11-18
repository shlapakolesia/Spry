-- Compare the prevalence of three names among US Social Security records.
-- Source suppresses infrequent name counts. These counts are not a birth census.
SELECT
  year,
  name,
  SUM(number) AS recorded_count
FROM `bigquery-public-data.usa_names.usa_1910_current`
WHERE year BETWEEN 2000 AND 2020
  AND gender = 'F'
  AND name IN ('Emma', 'Olivia', 'Sophia')
GROUP BY year, name
ORDER BY year, name;
