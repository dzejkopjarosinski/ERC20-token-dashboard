WITH tokens as (
SELECT 
contract_address,
symbol
FROM tokens_ethereum.erc20
WHERE symbol = '{{Token Symbol}}'
LIMIT 1),

price as (
SELECT 
date_trunc('{{Time}}',minute) as "Time",
AVG(price) as "Price"
FROM prices."usd" d
INNER JOIN tokens t ON t.contract_address = d.contract_address
GROUP BY date_trunc('{{Time}}',minute) 
),
flow_from as (
SELECT
date_trunc('{{Time}}',block_time) as "Date",
SUM(token_sold_amount) as "Sold Token",
SUM(amount_usd) as "Sold USD",
COUNT(token_sold_address) as "Active Sellers"
FROM dex.trades
WHERE token_sold_symbol = '{{Token Symbol}}'
GROUP BY date_trunc('{{Time}}',block_time)
),
flow_to as (
SELECT
date_trunc('{{Time}}',block_time) as "Date",
SUM(token_bought_amount) as "Bought Token",
SUM(amount_usd) as "Bought USD",
COUNT(token_bought_address) as "Active Buyers"
FROM dex.trades
WHERE token_bought_symbol = '{{Token Symbol}}'
GROUP BY date_trunc('{{Time}}',block_time)
)

SELECT
t."Date",
"Price",
"Bought USD" - "Sold USD" as "Net Trading USD",
"Bought Token" - "Sold Token" as "Net Trading Token",
"Bought Token",
"Sold Token",
"Bought USD",
"Sold USD",
("Active Buyers" * 1.0) / NULLIF("Active Sellers" * 1.0 ,0) as "Buyer to Seller Ratio",
"Active Buyers",
"Active Sellers"
FROM flow_to as t
LEFT JOIN flow_from as f ON f."Date" = t."Date"
LEFT JOIN price ON "Time" = t."Date"
ORDER BY t."Date" DESC
LIMIT {{Last X Days}}
