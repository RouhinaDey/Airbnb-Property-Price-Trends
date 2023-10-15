USE airnb_2019;
ALTER TABLE availability RENAME COLUMN square_feet TO sqft;
CREATE TABLE host SELECT a.id, a.name, a.room_type, d.host_id, d.host_response_time, d.host_identity_verified, d.city, d.state, d.property_type, b.accommodates, b.sqft, b.bathrooms, b.bed_type, b.bedrooms, b.beds, m.amenities, a.price, a.room_type, a.number_of_reviews, r.review_scores_rating FROM ab_nyc_2019 AS a INNER JOIN detailed_property AS d ON a.id= d.id INNER JOIN availability AS b ON d.id= b.id INNER JOIN amenities AS m ON d.id= m.id LEFT JOIN reviewrating AS r ON d.id= r.id;
SELECT * FROM host;

-- average price of accommodations in each city
SELECT city, ROUND(AVG(price),2) AS average_price FROM host GROUP BY city ORDER BY city ASC;

-- number of accommodations in each city hosted by hosts with verified identities
SELECT city, COUNT(accommodates) AS accommodations FROM host WHERE host_identity_verified = 't' GROUP BY city;

-- What is the most common property type in each city
WITH property_rank AS (
SELECT city, property_type, COUNT(property_type) AS property_counts, 
ROW_NUMBER() OVER 
(
PARTITION BY city ORDER BY COUNT(property_type) DESC
) 
AS ranked FROM host GROUP BY city, property_type
) SELECT city, property_type,  property_counts FROM property_rank WHERE ranked = 1;

--  average number of bedrooms for accommodations in each city
SELECT city, AVG(bedrooms) AS avg_no_of_bedrooms FROM host GROUP BY city;

-- number of accommodations have a host response time of less than 1 hour
SELECT COUNT(accommodates) AS accommodate_count FROM host WHERE host_response_time = 'within an hour';

-- average price of accommodations based on the type of bed
SELECT bed_type, AVG(price) AS avg_price FROM host GROUP BY bed_type;

-- distribution of accommodations by room type (room_type) in each city
SELECT city, room_type, accommodates, COUNT(accommodates) FROM host GROUP BY city, room_type, accommodates ORDER BY city, room_type, accommodates;

-- average price of accommodations vary with the number of reviews they have received
SELECT number_of_reviews, ROUND(AVG(price),2) AS avg_price FROM host GROUP BY number_of_reviews;

-- number of  accommodations available for each number of beds
SELECT beds, SUM(accommodates) AS number_of_accommodations FROM host GROUP BY beds;

-- distribution of accommodations based on host_identity_verified status
SELECT COUNT(*) AS number_of_accommodation, host_identity_verified FROM host GROUP BY host_identity_verified;

-- average number of reviews for accommodations in each city
SELECT city, ROUND(avg(number_of_reviews),0) AS avg_reviews FROM host GROUP BY city;

--  variation of price of accommodations with the property type
SELECT property_type, ROUND(AVG(price),2) AS avg_price FROM host GROUP BY property_type;

-- number of accommodations that accommodate a specific number of guests
SELECT accommodates AS no_of_guests, COUNT(accommodates) AS no_of_accommodates FROM host GROUP BY accommodates ORDER BY accommodates;

-- average price of accommodations change with the number of bedrooms
SELECT bedrooms, ROUND(AVG(price),2) AS avg_price FROM host GROUP BY bedrooms ORDER BY bedrooms;


-- average price of accommodations that have more than 1 bathroom
SELECT ROUND(bathrooms,0) AS no_of_bathrooms , ROUND(AVG(price),2) AS avg_price FROM host WHERE bathrooms > 1 GROUP BY ROUND(bathrooms,0);

-- average price of accommodations based on their square footage
SELECT CONCAT(start,'-',end) AS sqft_ranges, avg_price AS avg_price FROM (SELECT floor(sqft/100)*100 AS start, (floor(sqft/100) + 1) * 100 AS end, ROUND(AVG(price),2) AS avg_price FROM host WHERE sqft IS NOT NULL GROUP BY start, end ORDER BY start) AS ranging;


-- For each host_response_time category, what is the average number of reviews for accommodations with a review_score_rating above 90
SELECT host_response_time, ROUND(AVG(number_of_reviews),0) AS avg_reviews, ROUND(AVG(review_scores_rating),0) AS avg_rating FROM host WHERE length(host_response_time) <> 0 AND review_scores_rating > 90 GROUP BY host_response_time;

-- average price difference between accommodations with different bed types for each property type
WITH diff AS 
(
SELECT property_type, beds, price AS previous, LEAD(price) OVER (PARTITION BY property_type, beds ORDER BY price) AS next FROM host
) 
SELECT property_type, beds, ROUND(AVG(next - previous),0) AS price_diff FROM diff WHERE next IS NOT NULL GROUP BY property_type, beds;

-- top 5 rents getting highest ratings
SELECT DISTINCT host_id, name, review_scores_rating FROM host ORDER BY review_scores_rating DESC LIMIT 5;

-- price variation for a range of ratings
WITH price_variation AS 
(
SELECT ROUND(AVG(price),2) AS avg_price, floor(review_scores_rating/10)*10 AS lower_value, (floor(review_scores_rating/10) + 1) *10 AS upper_value FROM host WHERE review_scores_rating IS NOT NULL GROUP BY lower_value, upper_value HAVING upper_value <=100
) 
SELECT CONCAT(lower_value,'-',upper_value) AS range_of_ratings, avg_price FROM price_variation;

-- highest and lowest average price of accommodations for each property type
WITH average_price AS 
(
SELECT city, property_type, ROUND(AVG(price),2) AS avg_price FROM host GROUP BY city, property_type ORDER BY city, property_type
)
SELECT property_type, MAX(avg_price), MIN(avg_price) FROM average_price GROUP BY property_type;

-- Price vs. Review Score Rating
SELECT review_scores_rating, price FROM host WHERE review_scores_rating IS NOT NULL ORDER BY review_scores_rating;

-- Most costly Hotels
SELECT name, property_type, price FROM (SELECT  name, property_type, price, ROW_NUMBER() OVER (PARTITION BY property_type ORDER BY price DESC) AS highest_price FROM host) AS sub_query WHERE highest_price = 1 ORDER BY price DESC; 

-- price variation by room type
SELECT room_type, price FROM (SELECT room_type, price, ROW_NUMBER() OVER (PARTITION BY room_type ORDER BY price DESC) AS max_price FROM host) AS room_price WHERE max_price = 1;

-- min max and avg price
WITH average_prices AS 
(
SELECT property_type AS property, AVG(price) as prices FROM host GROUP BY property_type
) 
SELECT property, prices FROM average_prices GROUP BY property;
SELECT property_type, MIN(price), MAX(price), AVG(price) FROM host GROUP BY property_type;

-- price by number of accommodates in each property
SELECT property_type, accommodates, ROUND(AVG(price),2) AS price FROM host WHERE accommodates IS NOT NULL GROUP BY property_type,accommodates;

-- price by square feet for entire house
SELECT CONCAT(start,'-',end) AS sqft_ranges, avg_price AS avg_price FROM (SELECT floor(sqft/100)*100 AS start, (floor(sqft/100) + 1) * 100 AS end, ROUND(AVG(price),2) AS avg_price FROM host WHERE sqft IS NOT NULL AND room_type LIKE "Entire home%" GROUP BY start, end ORDER BY start) AS ranging;

-- price by number of bathrooms
SELECT ROUND(bathrooms,0) AS no_of_bathrooms , ROUND(AVG(price),2) AS price FROM host WHERE bathrooms IS NOT NULL GROUP BY ROUND(bathrooms,0);

-- price by minimum_nights
SELECT p.city, a.minimum_nights, ROUND(AVG(a.price),2) AS price FROM ab_nyc_2019 AS a INNER JOIN host AS p ON a.host_id=p.host_id GROUP BY city, minimum_nights ORDER BY minimum_nights;