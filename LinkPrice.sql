WITH tokens AS (
SELECT 
contract_address,
symbol
FROM tokens_ethereum.erc20
WHERE symbol = '{{Token Symbol}}'
LIMIT 1)

SELECT 
date_trunc('{{Time}}',minute) as "Time",
AVG(price) as "AVG PRICE",
MIN(price) as "MIN PRICE",
MAX(price) as "MAX PRICE",
STDDEV(price) as "Deviation"
FROM prices."usd" d
INNER JOIN tokens t ON t.contract_address = d.contract_address
WHERE date_trunc('{{Time}}',minute) > TIMESTAMP '{{Earliest Date}}'
GROUP BY date_trunc('{{Time}}',minute)
ORDER BY date_trunc('{{Time}}',minute) DESC
