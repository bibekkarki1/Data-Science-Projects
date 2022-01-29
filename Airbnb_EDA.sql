-- AIRBNB LISTINGS (2021/10/18) Exploratory Data Analysis for Ashville, NC
-- Data Cleaned: listings with missing data excluded
-- Data Source: insideairbnb.com

SELECT * FROM airbnb.listings;

-- Lowest rated listing for each property type where the host is a superhost
SELECT id, property_type, host_acceptance_rate, review_scores_rating,
MIN(review_scores_rating) OVER (PARTITION BY property_type) AS min_rating
FROM airbnb.listings
WHERE host_is_superhost = 't'
ORDER BY 2;


-- Displaying if the overall rating of a listing is higher, lower, or equal to the previous listing
SELECT id, review_scores_rating, number_of_reviews, room_type,
LAG(review_scores_rating) OVER (PARTITION BY room_type ORDER BY id) AS prev_rev_score,
CASE WHEN review_scores_rating > LAG(review_scores_rating) OVER (PARTITION BY room_type ORDER BY id) THEN 'Higher'
	WHEN review_scores_rating < LAG(review_scores_rating) OVER (PARTITION BY room_type ORDER BY id) THEN 'Lower'
	WHEN review_scores_rating = LAG(review_scores_rating) OVER (PARTITION BY room_type ORDER BY id) THEN 'Same'
	END AS rating_range
FROM airbnb.listings;

-- Most expensive, 2nd most expensive, and the least expensive listing for each room type
SELECT id, host_id, property_type, room_type, price,
FIRST_VALUE(id) OVER W AS most_expensive_listing,
LAST_VALUE(id) OVER W AS least_expensive_listing,
NTH_VALUE(id, 2) OVER W AS second_most_expensive_listing
FROM airbnb.listings
WINDOW W AS (PARTITION BY room_type ORDER BY price DESC
			RANGE BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING);

-- Categorizing all listings into 3 cleanliness classifications (very clean, clean, dirty)
SELECT c.id, host_id, price, review_scores_cleanliness,
CASE WHEN c.BUCKETS = 1 THEN 'Very Clean'
	WHEN c.BUCKETS = 2 THEN 'Clean'
    WHEN c.BUCKETS = 3 THEN 'Dirty'
    END AS cleanliness_category
FROM (
SELECT*,
NTILE(3) OVER (ORDER BY review_scores_cleanliness desc) AS BUCKETS
FROM airbnb.listings )c;

-- Stored procedure to return host bio/information by calling the listing id
DELIMITER $$
CREATE PROCEDURE host_info(id INT)
BEGIN
SELECT id, host_id, host_since, host_response_time, host_response_rate,
	host_acceptance_rate, host_is_superhost, host_identity_verified
FROM airbnb.listings;
END$$

DELIMITER ;

-- Bias in data:
-- Show the property types with more beds than the average number of beds for all property types
-- Total count of each property type in the listings is provided to show the bias in the data

WITH total_beds(property_type, total_beds_per_ptype, num_of_prop) AS
  (SELECT ls.property_type, SUM(ls.beds) AS total_beds_per_ptype, COUNT(ls.property_type) AS num_of_prop
  FROM airbnb.listings AS ls
  GROUP BY property_type),
 avg_beds (avg_beds_all) AS
   (SELECT AVG(total_beds_per_ptype) AS avg_beds_all
   FROM total_beds)
SELECT*
FROM total_beds tb
JOIN avg_beds ab
ON tb.total_beds_per_ptype > avg_beds_all
ORDER BY total_beds_per_ptype DESC;







