WITH tokens AS (
SELECT 
contract_address,
symbol
FROM tokens_ethereum.erc20
WHERE symbol = '{{Token Symbol}}'
LIMIT 1),

current AS (SELECT
minute,
price,
1 AS "Key"
FROM prices."usd"
    INNER JOIN (SELECT MAX(minute) AS "Current",
    d.contract_address AS "c"
    FROM prices."usd" d
    INNER JOIN tokens t ON t.contract_address = d.contract_address
    GROUP BY d.contract_address
    ) AS p ON "Current" = minute AND "c" = contract_address
),
ath AS (SELECT 
DATE(minute) AS "ATH Day",
price AS "Max Price",
1 AS "Key"
FROM prices."usd"
INNER JOIN (SELECT
    MAX(price) AS "Max Price",
    d.contract_address AS "c"
    FROM prices."usd" d
    INNER JOIN tokens t ON t.contract_address = d.contract_address
    GROUP BY d.contract_address
) p ON "Max Price" = price AND "c" = contract_address
ORDER BY minute DESC),

past_30 AS (
SELECT
MAX(price) AS "Past 30 Price",
1 AS "Key"
FROM prices."usd" d
INNER JOIN tokens t ON t.contract_address = d.contract_address
WHERE DATE(minute) = CURRENT_DATE - INTERVAL '30' DAY
),
past_365 AS (
SELECT
MAX(price) AS "Past 365 Price",
1 AS "Key"
FROM prices."usd" d
INNER JOIN tokens t ON t.contract_address = d.contract_address
WHERE DATE(minute) = CURRENT_DATE - INTERVAL '365' DAY
),

ytd AS (
SELECT
price AS "YTD",
1 AS "Key"
FROM prices."usd"
INNER JOIN (SELECT MIN(minute) AS "ytd",
    d.contract_address AS "c"
    FROM prices."usd" d
    INNER JOIN tokens t ON t.contract_address = d.contract_address
    WHERE EXTRACT(YEAR FROM minute) = EXTRACT(YEAR FROM CURRENT_DATE)
    GROUP BY d.contract_address
) AS p ON "ytd" = minute AND "c" = contract_address
)
SELECT
minute,
price AS "Current Price",
DATE(minute) - "ATH Day" AS "Days Since All Time High",
"Max Price",
(price - "Max Price") / "Max Price" AS "% From ATH",
"Past 30 Price",
(price - "Past 30 Price") / "Past 30 Price" AS "% From 30 Days Ago",
"Past 365 Price",
(price - "Past 365 Price") / "Past 365 Price" AS "% From 365 Days Ago",
"YTD",
(price - "YTD") / "YTD" AS "% From YTD"
FROM current AS c
LEFT JOIN ath ON ath."Key" = c."Key"
LEFT JOIN past_30 AS p30 ON p30."Key" = c."Key"
LEFT JOIN past_365 AS p365 ON p365."Key" = c."Key"
LEFT JOIN ytd ON ytd."Key" = c."Key"
