-- What are the top 5 brands by receipts scanned for most recent month?
WITH recent_month AS (
  SELECT 
    receiptId, 
    dateScanned, 
    itemBarcode
  FROM receipt_items 
  WHERE dateScanned BETWEEN 
        DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '1 month' AND 
        DATE_TRUNC('month', CURRENT_DATE)
)
SELECT 
  b.name AS brand_name, 
  COUNT(DISTINCT r.receiptId) AS receipts_scanned
FROM recent_month r
JOIN brands b ON r.itemBarcode = b.barcode
GROUP BY b.name
ORDER BY receipts_scanned DESC
LIMIT 5;



-- How does the ranking of the top 5 brands by receipts scanned for the recent month compare to the ranking for the previous month?
WITH recent_month AS (
  SELECT receiptId, dateScanned, itemBarcode
  FROM receipt_items 
  WHERE dateScanned BETWEEN 
        DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '1 month' AND 
        DATE_TRUNC('month', CURRENT_DATE)
),

previous_month AS (
  SELECT receiptId, dateScanned, itemBarcode
  FROM receipt_items 
  WHERE dateScanned BETWEEN 
        DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '2 month' AND 
        DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '1 month'
),

recent_rank AS (
SELECT *
FROM (
  SELECT b.name AS brand_name, 
         COUNT(DISTINCT r.receiptId) AS receipts_scanned, 
         RANK() OVER (ORDER BY COUNT(DISTINCT r.receiptId) DESC) AS recent_rank
  FROM recent_month r
  JOIN brands b ON r.itemBarcode = b.barcode
  GROUP BY b.name
) t
WHERE recent_rank <= 5
),

previous_rank AS (
SELECT *
FROM (
  SELECT b.name AS brand_name, 
         COUNT(DISTINCT r.receiptId) AS receipts_scanned, 
         RANK() OVER (ORDER BY COUNT(DISTINCT r.receiptId) DESC) AS previous_rank
  FROM previous_month r
  JOIN brands b ON r.itemBarcode = b.barcode
  GROUP BY b.name
) t
WHERE previous_rank <= 5
)

SELECT r.brand_name, 
       r.receipts_scanned AS recent_receipts_scanned, 
       p.receipts_scanned AS previous_receipts_scanned, 
       r.recent_rank, 
       p.previous_rank
FROM recent_rank r
FULL OUTER JOIN previous_rank p ON r.brand_name = p.brand_name
ORDER BY r.recent_rank;


-- When considering average spend from receipts with 'rewardsReceiptStatus’ of ‘Accepted’ or ‘Rejected’, which is greater?
-- This query returns the avg spend by status and order by the avg spend in descending order
SELECT 
  rewardsReceiptStatus, 
  AVG(totalSpent) AS avg_spend
FROM receipts
WHERE rewardsReceiptStatus IN ('Accepted', 'Rejected')
GROUP BY rewardsReceiptStatus
ORDER BY avg_spend DESC;


-- When considering total number of items purchased from receipts with 'rewardsReceiptStatus’ of ‘Accepted’ or ‘Rejected’, which is greater?
-- This query returns the total number of items purchased by status and order by the total number of items purchased in descending order
SELECT 
  rewardsReceiptStatus, 
  SUM(purchasedItemCount) AS total_items_purchased
FROM receipts
WHERE rewardsReceiptStatus IN ('Accepted', 'Rejected')
GROUP BY rewardsReceiptStatus
ORDER BY total_items_purchased DESC;


-- Which brand has the most spend among users who were created within the past 6 months?
WITH cte AS (
  SELECT 
    b.name AS brand_name, 
    SUM(r.finalPrice) AS total_spend
  FROM users u
  JOIN receipt_items r ON u.userId = r.userId
  AND u.createdDate >= CURRENT_DATE - INTERVAL '6 months'
  JOIN brands b ON r.itemBarcode = b.barcode
  GROUP BY b.name
)

SELECT *
FROM cte
WHERE total_spend = (SELECT MAX(total_spend) FROM cte);


-- Which brand has the most transactions among users who were created within the past 6 months?
-- note: I'm assuming transactions refer to the number of receipts scanned
WITH cte AS (
  SELECT 
    b.name AS brand_name, 
    COUNT(DISTINCT r.receiptId) AS total_transactions
  FROM users u
  JOIN receipt_items r ON u.userId = r.userId
  AND u.createdDate >= CURRENT_DATE - INTERVAL '6 months'
  JOIN brands b ON r.itemBarcode = b.barcode
  GROUP BY b.name
)

SELECT *
FROM cte
WHERE total_transactions = (SELECT MAX(total_transactions) FROM cte);