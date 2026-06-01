-- -------------------------------------
-- revision of SQL
SELECT * FROM customer_feedback;

-- SECTION 1 — DATA VALIDATION & CLEANING
-- Find duplicate order_ids in customer_feedback.
SELECT order_id, COUNT(*) AS duplicate_count
FROM customer_feedback
GROUP BY order_id
HAVING COUNT(*) > 1 ;


SELECT * FROM menu_items;
SELECT * FROM operational_metrices;
SELECT * FROM order_details;
SELECT * FROM staffing_metrices;
SELECT COUNT(*) AS total_rows
FROM order_details;

-- Identify orders that exist in order_details but not in operational_metrics.
SELECT * FROM 
order_details  
WHERE order_id  NOT IN (
SELECT order_id 
FROM operational_metrices );
-- or professionally
SELECT od.*
FROM order_details od
LEFT JOIN operational_metrics om
    ON od.order_id = om.order_id
WHERE om.order_id IS NULL;

-- Find menu items with missing or NULL prices.
SELECT * FROM menu_items 
WHERE price IS NULL 
OR price <= 0;

-- Check if any ratings are outside the 1–5 range.
SELECT * FROM customer_feedback
WHERE ratings NOT BETWEEN 1 AND 5;

-- Find orders with negative prep_time or wait_time.
SELECT * FROM operational_metrices
WHERE prep_time < 0 
OR wait_time < 0;

-- Identify menu items with duplicate names but different prices.
SELECT item_name , COUNT(*) AS total_rec ,COUNT(DISTINCT price) AS count_of_df_price
FROM menu_items
GROUP BY item_name
HAVING COUNT(*) > 1
AND COUNT(DISTINCT price) > 1;

-- Find order_ids having more than 3 customer complaints.
SELECT * FROM customer_feedback;
SELECT order_id, COUNT(complaint_type) AS complaints
FROM customer_feedback
GROUP BY order_id
HAVING complaints > 3;

-- Count NULL complaint_type values.
SELECT COUNT(*) FROM customer_feedback
WHERE complaint_type IS NULL ;
-- or
SELECT 
    SUM(CASE WHEN complaint_type IS NULL THEN 1 ELSE 0 END) AS null_complaint_count
FROM customer_feedback;

-- Find orders with unusually high wait times.
SELECT * 
FROM operational_metrices
WHERE wait_time > 
(SELECT AVG(wait_time) + STDDEV(wait_time)
FROM operational_metrices) ;

-- Check whether all shift_ids in operational_metrics exist in staffing_metrics.
SELECT * FROM staffing_metrices;
SELECT * FROM operational_metrices;  -- shift_ids do not exist in opertaional metrices

-- SECTION 2 — JOINS & RELATIONAL THINKING
-- Combine order_details and menu_items to show item name with each order.
SELECT * FROM order_details od
JOIN menu_items mi
ON od.item_id = mi.menu_item_id;

-- Show customer ratings along with wait times for each order.
SELECT om.order_id, om.wait_time , cf.ratings
FROM operational_metrices om
JOIN customer_feedback cf
ON om.order_id = cf.order_id;

-- Join staffing_metrics with operational_metrics to compare staffing and delays.
SELECT * FROM staffing_metrices;
SELECT * FROM operational_metrices; -- These tables cannot be meaningfully joined directly because they do not share a common key. A bridge column such as date, shift_id, store_id, or time period is required to compare staffing levels with wait-time delays.

-- Show all menu items never ordered.
SELECT mi.* FROM menu_items mi
LEFT JOIN order_details od
ON od.item_id = mi.menu_item_id
WHERE od.item_id IS NULL;

-- Find orders without customer feedback.
SELECT od.* FROM order_details od
LEFT JOIN customer_feedback cf
ON od.order_id = cf.order_id
WHERE cf.order_id IS NULL;

-- Find shifts where workload is “Very high” but staffing count exceeds 4.
SELECT * FROM staffing_metrices
WHERE workload_level = "Very high" 
AND staff_count > 4;

-- Display item name, category, prep_time, and wait_time together.
SELECT * FROM operational_metrices;
SELECT * FROM menu_items;
SELECT * FROM order_details;

SELECT mi.item_name, mi.category, op.prep_time, op.wait_time FROM operational_metrices op
LEFT JOIN order_details od
ON op.order_id = od.order_id
LEFT JOIN menu_items mi
ON od.item_id = mi.menu_item_id;

-- Find orders placed during understaffed shifts.
-- no common table provided

-- Find menu categories linked with highest average wait time.
SELECT mi.category, AVG(wait_time) AS avg_wait_time
FROM operational_metrices op
LEFT JOIN order_details od
ON op.order_id = od.order_id
LEFT JOIN menu_items mi
ON od.item_id = mi.menu_item_id
WHERE wait_time > 
(SELECT AVG(wait_time) FROM operational_metrices)
GROUP BY mi.category;

-- Find shifts generating maximum complaints.
-- no common column 

-- SECTION 3 — AGGREGATION & BUSINESS KPIs
-- Calculate total revenue generated per category.
SELECT mi.category, SUM(mi.price) AS total_revenue FROM order_details od
JOIN menu_items mi
ON od.item_id = mi.menu_item_id
GROUP BY mi.category;

-- Find top 5 best-selling menu items.
SELECT mi.item_name, COUNT(od.item_id) AS sales FROM order_details od
JOIN menu_items mi
ON od.item_id = mi.menu_item_id
GROUP BY mi.item_name
ORDER BY sales DESC
LIMIT 5;

-- Find least-selling menu items.
SELECT mi.item_name, COUNT(od.item_id) AS sales FROM order_details od
JOIN menu_items mi
ON od.item_id = mi.menu_item_id
GROUP BY mi.item_name
ORDER BY sales ASC
LIMIT 5;

-- Calculate average order value.

SELECT SUM(mi.price)/COUNT( distinct od.order_id) AS avg_order_value
FROM order_details od
JOIN menu_items mi
ON od.item_id = mi.menu_item_id;

-- Find average prep time by order_type.
SELECT AVG(prep_time), order_type
FROM operational_metrices
GROUP BY order_type;

-- modifying stafiing and operational table so that we can link this table with others easily to find more insights 
-- lets fix staffing metrices
SELECT * FROM staffing_metrices;
SELECT * FROM operational_metrices;
ALTER TABLE operational_metrices ADD COLUMN shift_time VARCHAR (20);
UPDATE operational_metrices SET shift_time =( CONCAT( "S" ,LPAD(FLOOR(1 + RAND()* 9 ),3,"0"))) ;
ALTER TABLE operational_metrices RENAME COLUMN shift_time TO shift_id;
-- checking by join
SELECT sm.workload_level FROM staffing_metrices sm
JOIN operational_metrices op
ON sm.shift_id = op.shift_id;

-- Find average wait time by shift period.
SELECT AVG(op.wait_time), sm.shift_time
FROM operational_metrices op
JOIN staffing_metrices sm
ON sm.shift_id = op.shift_id
GROUP BY shift_time;

-- Calculate complaint percentage for each shift.
SELECT
SUM(CASE WHEN cf.complaint_type != "" THEN 1 ELSE 0 END)* 100 / COUNT(*) AS complaint_percentage,
sm.shift_time FROM customer_feedback cf
JOIN operational_metrices op
ON cf.order_id = op.order_id
JOIN staffing_metrices sm
ON op.shift_id = sm.shift_id
GROUP BY sm.shift_time;

-- Find which experience_level has highest average customer rating.
SELECT
AVG (ratings) AS avg_ratings , sm.experience_level
FROM customer_feedback cf
JOIN operational_metrices op
ON cf.order_id = op.order_id
JOIN staffing_metrices sm
ON op.shift_id = sm.shift_id
GROUP BY sm.experience_level
ORDER BY avg_ratings DESC ;

-- Calculate total orders handled per shift.
SELECT
sm.shift_time, COUNT(op.order_id)
FROM customer_feedback cf
JOIN operational_metrices op
ON cf.order_id = op.order_id
JOIN staffing_metrices sm
ON op.shift_id = sm.shift_id
GROUP BY sm.shift_time;

-- Find which menu category contributes most revenue.
SELECT mi.category , COUNT( od.order_id ) * SUM(mi.price ) AS total_revenue 
FROM order_details od
JOIN menu_items mi
ON od.item_id = mi.menu_item_id
GROUP BY mi.category
ORDER BY total_revenue DESC;

-- SECTION 4 — ADVANCED FILTERING & CONDITIONAL LOGIC
-- Find orders where wait_time exceeded prep_time by more than 10 minutes.
SELECT order_id, prep_time, wait_time FROM operational_metrices
WHERE wait_time - prep_time > 10;

-- Find menu items ordered during “Very high” workload periods only.
SELECT * FROM order_details; --  item_id
SELECT * FROM menu_items; -- item_name, menu_item_id
SELECT * FROM operational_metrices; -- shift_id
SELECT * FROM staffing_metrices; -- shift_id, workload_level - Very high
SELECT mi.item_name, sm.workload_level 
FROM staffing_metrices sm
JOIN operational_metrices op 
ON op.shift_id = sm.shift_id
JOIN order_details od
ON od.order_id = op.order_id
JOIN menu_items mi
ON mi.menu_item_id = od.item_id
WHERE sm.workload_level = "Very high"
GROUP BY mi.item_name;

-- Find customers/orders affected by both: high wait time and negative complaint
SELECT op.order_id, cf.complaint_type, op.wait_time
FROM operational_metrices op 
JOIN customer_feedback cf
ON cf.order_id = op.order_id
WHERE op.wait_time > ( SELECT AVG(wait_time) FROM operational_metrices )
AND cf.complaint_type != "";

-- Find shifts where junior-heavy staffing still achieved good ratings.
SELECT * FROM customer_feedback; -- ratings , order id
SELECT * FROM staffing_metrices; -- experience_level , shift id
SELECT * FROM operational_metrices; -- shift id 
SELECT sm.shift_time, cf.ratings, sm.experience_level FROM customer_feedback cf
JOIN operational_metrices op 
ON op.order_id = cf.order_id
JOIN staffing_metrices sm
ON sm.shift_id = op.shift_id
WHERE sm.experience_level = "Junior-heavy"
AND cf.ratings > 3;

-- Classify wait times into: Low,Medium,High,using CASE WHEN.
SELECT order_id, wait_time ,
CASE WHEN wait_time < 10 THEN "Low"
     WHEN wait_time >=10 AND wait_time <= 20 THEN "Medium"
     ELSE "High"
END AS wait_time_category
FROM operational_metrices;

-- Find menu items whose average prep time exceeds overall average prep time.
SELECT * FROM operational_metrices; -- order id, prep time 
SELECT * FROM menu_items; -- menu item id , item name
SELECT * FROM order_details; -- item id , order id
SELECT mi.item_name, AVG(op.prep_time)  FROM operational_metrices op 
JOIN order_details od
ON op.order_id = od.order_id
JOIN menu_items mi
ON mi.menu_item_id = od.item_id
GROUP BY mi.item_name
HAVING AVG(op.prep_time) >
( SELECT AVG(prep_time) FROM operational_metrices);

-- Find shifts where staffing is low but orders are high.
SELECT * FROM staffing_metrices;
SELECT * FROM operational_metrices;
SELECT sm.shift_time, COUNT(op.order_id) 
FROM staffing_metrices sm
JOIN operational_metrices op
ON sm.shift_id = op.shift_id
WHERE sm.staff_count < 4
GROUP BY sm.shift_time
HAVING COUNT(op.order_id) > 
		(SELECT AVG(COUNT(order_id))
		FROM 
			(SELECT shift_id, COUNT(order_id) AS order_count
			FROM operational_metrices
			GROUP BY shift_id ) AS shift_count);
            
-- Identify operational anomalies: high staffing but still very high workload
SELECT staff_count, workload_level FROM staffing_metrices
WHERE staff_count > 
(SELECT AVG(staff_count) FROM staffing_metrices)
AND workload_level = "Very high"; 

-- Find top complaint category during night shifts.
SELECT cf.complaint_type,
COUNT(cf.complaint_type) AS total_complaints_category
FROM customer_feedback cf
JOIN operational_metrices op
ON op.order_id =cf.order_id
JOIN staffing_metrices sm
ON op.shift_id = sm.shift_id
WHERE sm.shift_time = "Night"
AND cf.complaint_type IS NOT NULL
GROUP BY cf.complaint_type
ORDER BY COUNT(cf.complaint_type) DESC
LIMIT 1;

-- SECTION 5 — WINDOW FUNCTIONS (VERY IMPORTANT)
-- Rank menu items by revenue within each category.
SELECT * FROM menu_items; -- menu item id, category, price
SELECT * FROM order_details; -- item id

SELECT mi.category, mi.item_name, COUNT(od.order_id) AS quantity, ROUND(SUM(mi.price),2) AS total_revenue ,
RANK() OVER (PARTITION BY mi.category ORDER BY SUM(mi.price) DESC) AS revenue_rank
FROM menu_items mi
JOIN order_details od 
ON mi.menu_item_id = od.item_id
GROUP BY mi.category, mi.item_name
ORDER BY mi.category, revenue_rank;

-- Find top-performing shift based on average ratings.
SELECT * FROM staffing_metrices; -- shift id, shift_time
SELECT * FROM customer_feedback; -- ratings, order id
SELECT * FROM operational_metrices; -- order id , shift id

SELECT sm.shift_time, AVG(cf.ratings),
RANK () OVER(ORDER BY AVG(cf.ratings) ) AS avg_ratings_rank 
FROM staffing_metrices sm
JOIN operational_metrices op 
ON sm.shift_id = op.shift_id
JOIN customer_feedback cf
ON op.order_id = cf.order_id
GROUP BY sm.shift_time
ORDER BY avg_ratings_rank DESC;

-- Calculate running total revenue over orders.
SELECT * FROM order_details;
SELECT od.order_id, ROUND(SUM(mi.price),2) as total_revenue,
ROUND(SUM(SUM(mi.price)) OVER( ORDER BY od.order_id),2) AS running_total 
FROM menu_items mi
JOIN order_details od
ON mi.menu_item_id = od.item_id
GROUP BY od.order_id;

-- Find each category’s contribution percentage to total revenue.
SELECT mi.category, ROUND(SUM(mi.price),2) AS category_revenue,
ROUND(SUM(mi.price) * 100 / ( 
(SELECT SUM(m.price) FROM menu_items m 
JOIN order_details o 
ON m.menu_item_id = o.item_id )),2
)
AS total_revenue 
FROM menu_items mi
JOIN order_details od
ON mi.menu_item_id = od.item_id
GROUP BY mi.category;

-- Find the second-highest selling item in every category.
SELECT * FROM (
SELECT mi.category, mi.item_name, COUNT(od.order_id) AS total_orders ,
RANK() OVER(PARTITION BY mi.category ORDER BY COUNT(od.order_id) DESC) AS ranking
FROM menu_items mi
JOIN order_details od
ON mi.menu_item_id = od.item_id
GROUP BY mi.category , mi.item_name
) AS ranked_items 
WHERE ranking = 2;

-- Calculate moving average of wait times across orders.
SELECT od.order_id, 
 AVG(op.wait_time) AS avg_wait_time,
ROUND(
AVG(AVG(op.wait_time)) OVER ( 
ORDER BY od.order_id DESC ROWS BETWEEN 2 PRECEDING AND CURRENT ROW)
,2
) AS moving_average_wait_time
FROM operational_metrices op
JOIN order_details od
ON op.order_id = od.order_id
GROUP BY od.order_id;

-- Assign dense ranks to menu items based on sales.
SELECT mi.item_name, COUNT(od.order_id),
DENSE_RANK() OVER( ORDER BY COUNT(od.order_id) DESC) AS ranks
FROM menu_items mi
JOIN order_details od
ON mi.menu_item_id = od.item_id
GROUP BY mi.item_name;

-- Find orders whose wait_time is above shift average.
SELECT om.order_id, om.shift_id, above_avg.avg_wait_time
FROM operational_metrices om
JOIN 
(
SELECT op.shift_id, AVG(op.wait_time) AS avg_wait_time 
FROM operational_metrices op 
GROUP BY op.shift_id
) AS above_avg 
ON above_avg.shift_id = om.shift_id
WHERE om.wait_time > above_avg.avg_wait_time
; 

-- Compare each shift’s performance against overall performance.
SELECT 
	sm1.shift_id , 
	sm1.shift_time,
	COUNT(op1.order_id) AS total_orders,
	ROUND(AVG(op1.wait_time), 2) AS shift_avg_wait_time,
	ROUND(AVG(cf1.ratings),2) AS shift_avg_ratings,
	ROUND(overall.avg_wait_time) AS overall_avg_wait_time,
	ROUND(overall.avg_rating) AS overall_avg_rating,

	CASE 
		WHEN AVG(op1.wait_time) > overall.avg_wait_time 
		THEN 'Worse than overall'
		ELSE 'Better than overall'
	END AS wait_time_performance,

	CASE 
		WHEN AVG(cf1.ratings) > overall.avg_rating 
		THEN 'Better than overall'
		ELSE 'Worse than overall'
	END AS rating_performance

FROM staffing_metrices sm1
JOIN operational_metrices op1
ON sm1.shift_id = op1.shift_id
JOIN customer_feedback cf1
ON op1.order_id = cf1.order_id
JOIN (
SELECT AVG(op.wait_time) AS avg_wait_time,
AVG(cf.ratings) AS avg_rating
FROM operational_metrices op 
JOIN customer_feedback cf
ON cf.order_id = op.order_id
) AS overall

GROUP BY 
    sm1.shift_id, 
    sm1.shift_time,
    overall.avg_wait_time,
    overall.avg_rating;

-- Find customer feedback trends using cumulative complaint counts.
SELECT 
    od.order_date,
    COUNT(cf.complaint_type) AS daily_complaints,
    SUM(COUNT(cf.complaint_type)) OVER (
        ORDER BY od.order_date
    ) AS cumulative_complaints
FROM customer_feedback cf
JOIN order_details od
    ON cf.order_id = od.order_id
WHERE cf.complaint_type IS NOT NULL
  AND cf.complaint_type <> ''
GROUP BY od.order_date
ORDER BY od.order_date;




















































