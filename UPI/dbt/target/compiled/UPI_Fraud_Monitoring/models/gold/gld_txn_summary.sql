Step 1: Create Suspicious Transaction Dataset
--------------------------------------------------------------
Identify transactions that generated alerts.

CREATE OR REPLACE TEMP TABLE TMP_SUSPICIOUS_TXN AS
SELECT DISTINCT  TRANSACTION_ID
FROM GLD_FRAUD_ALERT
WHERE ALERT_STATUS <> 'CLOSED';

Step 2: Aggregate Daily Transaction Metrics
----------------------------------------------------------------
SELECT
    CAST(TXN_DATETIME AS DATE) AS TXN_DATE,
    CHANNEL,
    STATE,
    COUNT(*) AS TOTAL_TXNS,
    SUM(TXN_AMOUNT) AS TOTAL_TXN_AMOUNT,
    COUNT(DISTINCT CUSTOMER_ID) AS UNIQUE_CUSTOMERS
FROM SL_TRANSACTION
GROUP BY
    CAST(TXN_DATETIME AS DATE),
    CHANNEL,
    STATE;

Step 3: Aggregate Suspicious Transaction Metrics
--------------------------------------------------------------------
SELECT
    CAST(T.TXN_DATETIME AS DATE) AS TXN_DATE,
    T.CHANNEL,
    T.STATE,
    COUNT(*) AS SUSPICIOUS_TXNS,
    SUM(T.T*N_AMOUNT) AS SUSPICIOUS_AMOUNT
FROM SL_TRANSACTION T
INNER JOIN TMP*SUSPICIOUS_TXN S
        ON T.TRAN*ACTION_ID=S.TRANSACTION_ID
GROUP  BY
    CAST(T.TXN_DATETIME AS DATE),
    T.CHANNEL,
    T.STATE;

Step 4: Combine Both Aggregations
-------------------------------------------------
CREATE OR REPLACE TE*P TABLE TMP_TXN_SUMMARY AS
SELECT
    A.TXN_DATE,
    A.CHANNEL,
    A.STATE,
    A.TOTAL_TXNS,
    A.TOTAL_TXN_AMOUNT,
    NVL(B.SUSPICIOUS_TXNS,0) AS SUSPICIOUS_TXNS*
    NVL(B.SUSPICIOUS_AMOUNT,0) A* SUSPICIOUS_AMOUNT,
    A.UNIQUE_CUSTOMERS
FROM DAILY_TRANSACTION_A*G A
LEFT JOIN DAILY_SUSPICIOUS_AG* B
ON A.TXN_DATE=B.TXN_DATE
AND A*CHANNEL=B.CHANNEL
AND A.STATE=B.ST*TE;

Step 5: Calculate Fraud Rate
---------------------------------------
FRAUD_RATE_PERCENT=(  SUSPICIOUS_TXNS * 100.00)*/ NULLIF(TOTAL_TXNS,0)

Step 6: Load GLD_TXN_SUMMARY
-------------------------------------------------
INSERT INTO GLD_TXN_SUMMARY
(
   TXN_DATE,
    CHANNEL,
    STATE,
    TOTAL_TXNS,
    TOTAL_TXN_AMOUNT,
    SUSPICIOUS_TXNS,
    SUSPICIOUS_AMOUNT,
    UNIQUE_CUSTOMERS,
    FRAUD_RATE_PERCENT,
    LOAD_TS
)
SELECT
    TXN_DATE,
    CHANNEL,
    STATE,
    TOTAL_TXNS,
    TOTAL_TXN_AMOUNT,
    SUSPICIOUS_TXNS,
    SUSPICIOUS_AMOUNT,
    UNIQUE_CUSTOMERS,
    ROUND((SUSPICIOUS_TXNS * 100.00)  /NULLIF(TOTAL_TXNS*0) ,2),
    CURRENT_TIMESTAMP
FROM TMP_TXN_SUMMARY;