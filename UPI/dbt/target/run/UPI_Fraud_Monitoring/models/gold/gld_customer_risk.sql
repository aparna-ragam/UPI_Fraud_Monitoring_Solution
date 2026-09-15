
  
    

create or replace transient table UPI_FRAUD_MONITORING_DB.analytics.gld_customer_risk
    
    
    
    
    

    as (Step 1: Aggregate Alert Statistics
-------------------------------------------
CREATE OR REPLACE TEMP TABLE TMP_CUSTOMER_ALERTS AS
SELECT
    CUSTOMER_ID,
    COUNT(*) AS TOTAL_ALERTS,
    SUM(
        CASE
            WHEN SEVERITY IN ('HIGH','CRITICAL')
            THEN 1
            ELSE 0
        END
    ) AS HIGH_RISK_ALERTS,
    SUM(
        CASE
            WHEN SEVERITY='CRITICAL'
            THEN 1
            ELSE 0
        END
    ) AS CRITICAL_ALERTS,
    AVG(RISK_SCORE) AS AVG_RISK_SCORE,
    MAX(RISK_SCORE) AS MAX_RISK_SCORE,
    MAX(CREATED_TS) AS LAST_ALERT_DATE
FROM GLD_FRAUD_ALERT
GROUP BY CUSTOMER_ID;

Step 2: Calculate Customer Risk Score
----------------------------------------------------
CUSTOMER_RISK_SCORE =
(
    HIGH_RISK_ALERTS * 10
)
+
(
    CRITICAL_ALERTS * 20
)
+
(
    AVG_RISK_SCORE * 0.50
)

Step 3: Assign Risk Band
----------------------------------
CASE
    WHEN CUSTOMER_RISK_SCORE >= 120
        THEN 'CRITICAL'
    WHEN CUSTOMER_RISK_SCORE >= 80
        THEN 'HIGH'
    WHEN CUSTOMER_RISK_SCORE >= 40
        THEN 'MEDIUM'
    ELSE 'LOW'
END

Step 4: Load GLD_CUSTOMER_RISK
----------------------------------------------------
INSERT INTO GLD_CUSTOMER_RISK
(
    CUSTOMER_ID,
    TOTAL_ALERTS,
    HIGH_RISK_ALERTS,
    CRITICAL_ALERTS,
    AVG_RISK_SCORE,
    MAX_RISK_SCORE,
    CUSTOMER_RISK_SCORE,
    RISK_BAND,
    LAST_ALERT_DATE,
    LAST_UPDATED_TS
)
SELECT
    CUSTOMER_ID,
    TOTAL_ALERTS,
    HIGH_RISK_ALERTS,
    CRITICAL_ALERTS,
    AVG_RISK_SCORE,
    MAX_RISK_SCORE,
    (
        (HIGH_RISK_ALERTS * 10)
        +
        (CRITICAL_ALERTS * 20)
        +
        (AVG_RISK_SCORE * 0.5)
    ) AS CUSTOMER_RISK_SCORE,
    CASE
        WHEN (
                (HIGH_RISK_ALERTS * 10)
                +
                (CRITICAL_ALERTS * 20)
                +
                (AVG_RISK_SCORE * 0.5)
             ) >= 120
        THEN 'CRITICAL'
        WHEN (
                (HIGH_RISK_ALERTS * 10)
                +
                (CRITICAL_ALERTS * 20)
                +
                (AVG_RISK_SCORE * 0.5)
             ) >= 80
        THEN 'HIGH'
        WHEN (
                (HIGH_RISK_ALERTS * 10)
                +
                (CRITICAL_ALERTS * 20)
                +
                (AVG_RISK_SCORE * 0.5)
             ) >= 40
        THEN 'MEDIUM'
        ELSE 'LOW'
    END,
    LAST_ALERT_DATE,
    CURRENT_TIMESTAMP()
FROM TMP_CUSTOMER_ALERTS;
    )
;


  