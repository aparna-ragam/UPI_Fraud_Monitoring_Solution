Derive BENEFICIARY RISK_RATING
Rule 1: Watchlist Match
-------------------------------
CASE WHEN EXISTS  (SELECT 1 FROM SL_WATCHLIST W  WHERE W.ENTITY_TYPE = 'BENEFICIARY' AND W.ENTITY_ID = B.BENEFICIARY_ID) 
THEN 'HIGH'
END

Rule 2: New Beneficiary (Recently added beneficiary)
------------------------------------------------------------------------
DATEDIFF(DAY, BENEFICIARY_CREATED_DATE, CURRENT_DATE)

Rule 3: High Transaction Volume(Beneficiary receives unusually high transactions)
------------------------------------------------------------------------------------------------------------------
SELECT  BENEFICIARY_ID,SUM(TXN_AMOUNT)  FROM SL_TRANSACTION
GROUP BY BENEFICIARY_ID;

> SUM(TXN_AMOUNT) > 10 Lakhs/day  THEN HIGH RISK

Rule 4: Multiple Customers Sending to Same Beneficiary(Common mule-account indicator)
---------------------------------------------------------------------------------------------------------------------------
SELECT  BENEFICIARY_ID, COUNT(DISTINCT CUSTOMER_ID) FROM SL_TRANSACTION
GROUP BY BENEFICIARY_ID;
> 10 customers THEN RISK_RATING = HIGH



---------------------------------------
Assign  Points :
Watchlist Match                 50
High Incoming Value             20
Multiple Customers              20
Previously Flagged              30
New Beneficiary                 10

WATCHLIST_SCORE
+
VOLUME_SCORE
+
CUSTOMER_COUNT_SCORE
+
FRAUD_HISTORY_SCORE
+
NEW_BENEFICIARY_SCORE
=
BENEFICIARY_RISK_SCORE

Final Rating
-----------------
CASE
    WHEN BENEFICIARY_RISK_SCORE >= 70
         THEN 'HIGH'

    WHEN BENEFICIARY_RISK_SCORE >= 40
         THEN 'MEDIUM'

    ELSE 'LOW'
END