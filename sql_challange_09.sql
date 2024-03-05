use retail_events_db;
select * from dim_campaigns;
select * from dim_products;
select * from dim_stores;
select * from fact_events;

-----
/* 1. Provide a list of products with a base price greater than 500 and that are featured in promo type BOGOF("Buy One Get One Free)*/ SELECT DISTINCT(promo_type) from fact_events;

SELECT DISTINCT
    p.product_name AS Product_Name,
    e.promo_type AS Promo_Type,
    e.base_price AS Base_Price
FROM fact_events e
JOIN dim_products p ON e.product_code = p.product_code
WHERE e.base_price > 500
AND e.promo_type = 'BOGOF';
------------------------
/* 2.
Generate a report that provides an overview of the number of stores in each city.
The results will be sorted in descending order of store counts.*/ 

SELECT
    city,
    COUNT(store_id) AS no_of_stores
FROM dim_stores
GROUP BY city
ORDER BY no_of_stores DESC;
--------------------------
/* 3. Generate a report that displays each campaign along with total revenue generated before and after campaign?*/ 
SELECT 
    c.campaign_name,
    CONCAT('$', FORMAT(SUM(e.base_price * e.quantity_sold_before_promo) / 1000000, 2), 'M') AS 'Total_Revenue(Before_Promotion)',
    CONCAT('$', FORMAT(SUM(e.base_price * e.quantity_sold_after_promo) / 1000000, 2), 'M') AS 'Total_Revenue(After_Promotion)'
FROM fact_events e 
JOIN dim_campaigns c 
ON e.campaign_id = c.campaign_id 
GROUP BY c.campaign_name;
----------------------
/*4. Produce a report that calculates the incremental sold quantity (ISU%) for eacl during the diwali campaign.
Provide rankings for the categories based on ISU % */
with ISU as (
    SELECT
        p.category,
        ROUND(((SUM(e.quantity_sold_after_promo) - SUM(e.quantity_sold_before_promo)) 
        / (SUM(e.quantity_sold_before_promo))) * 100,2) 
        AS isu_percent
    FROM fact_events e
    join dim_products p on e.product_code = p.product_code
	join dim_campaigns c on e.campaign_id = c.campaign_id
	WHERE c.campaign_name = 'Diwali'
	GROUP BY p.category
)
SELECT *,
    RANK() OVER (ORDER BY isu_percent DESC) AS rank_order
from ISU;
-----------------------
/* 5. Create a report featuring top products, ranked by Incremental revenue percentage IR% across all campaigns*/

SELECT
    p.product_name,
    p.category,
    ROUND(((SUM((e.base_price) * (e.quantity_sold_after_promo)) 
        - SUM(e.base_price * e.quantity_sold_before_promo)) 
        / (SUM(e.base_price * e.quantity_sold_before_promo))) * 100, 1) AS IR_Percent
FROM fact_events e
JOIN dim_products p ON e.product_code = p.product_code
GROUP BY p.product_name, p.category
ORDER BY IR_Percent DESC
LIMIT 5;
