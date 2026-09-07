CHANGE_HOUR(Useful for detecting unusual password change activity)
--------------------------------------------------------------------------------------------------
EXTRACT(HOUR FROM CHANGE_TIME)


--------------------------------------------------------------------------------------------------
CHANGE_DAY_OF_WEEK
--------------------------------------------------------------------------------------------------
DAYNAME(CHANGE_TIME)

--------------------------------------------------------------------------------------------------
DEVICE_RISK_SCORE
--------------------------------------------------------------------------------------------------
SELECT
    P.*,
    D.DEVICE_RISK_SCORE
FROM BR_PASSWORD_CHANGE P
LEFT JOIN SL_DEVICE D
ON P.DEVICE_ID = D.DEVICE_ID;

--------------------------------------------------
PASSWORD_CHANGE_RISK(Derived risk based on fraud indicators.)
-----------------------------------------------
CASE
    WHEN DEVICE_RISK_SCORE >= 80
         THEN 'HIGH'

    WHEN EXTRACT(HOUR FROM CHANGE_TIME)
         BETWEEN 0 AND 4
         THEN 'MEDIUM'

    ELSE 'LOW'
END



CASE
    WHEN DEVICE_RISK_SCORE >= 80
    THEN 'Y'
    ELSE 'N'
END AS HIGH_RISK_DEVICE_FLAG



CASE
    WHEN EXTRACT(HOUR FROM CHANGE_TIME)
         BETWEEN 0 AND 4
    THEN 'Y'
    ELSE 'N'
END AS ODD_HOUR_CHANGE_FLAG
