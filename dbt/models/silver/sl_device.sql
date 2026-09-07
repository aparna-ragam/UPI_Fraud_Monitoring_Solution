Step 1: Calculate Individual Risk Components
------------------------------------------------------------
SELECT
    DEVICE_ID,
    CASE   WHEN TRUSTED_FLAG = 'N' THEN 40  ELSE 0  END AS TRUST_SCORE,
    CASE   WHEN DEVICE_AGE_DAYS < 7 THEN 30


    END AS AGE_SCORE,
    CASE  WHEN DEVICE_OS IN ('ANDROID_8','ANDROID_9')  THEN 15 ELSE 0 END AS OS_SCORE
FROM BR_DEVICE;


Step 2: Compute Device Risk Score
------------------------------------------------
SELECT
    DEVICE_ID,

        +
     CASE
            WHEN DEVICE_AGE_DAYS < 7 THEN 30
            WHEN DEVICE_AGE_DAYS BETWEEN 7 AND 30 THEN 15
            ELSE 0
     END
        +
    CASE
            WHEN DEVICE_OS IN ('ANDROID_8','ANDROID_9')
            THEN 15
            ELSE 0
    END
    ) AS DEVICE_RISK_SCORE
FROM STG_DEVICE;

Derive Risk Category
-----------------------------
CASE
    WHEN DEVICE_RISK_SCORE >= 80 THEN 'HIGH'
    WHEN DEVICE_RISK_SCORE >= 40 THEN 'MEDIUM'
    ELSE 'LOW'
END AS DEVICE_RISK_LEVEL
