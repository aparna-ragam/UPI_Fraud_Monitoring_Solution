SELECT   MERCHANT_ID,
    MERCHANT_NAME,
    MERCHANT_CATEGORY,
    CASE
        WHEN MERCHANT_CATEGORY='GROCERY'
             THEN '5411'
        WHEN MERCHANT_CATEGORY='FUEL'
             THEN '5541'
        WHEN MERCHANT_CATEGORY='RESTAURANT'
             THEN '5812'
    END AS MCC_CODE,
    RISK_RATING
FROM BR_MERCHANT;

CASE
    WHEN MCC_CODE IN
    (
        '6051',
        '7995'
    )
    THEN 'HIGH_RISK_MERCHANT'
END

-----------------------------------
Transaction Pattern Monitoring -

Customer usually spends at:

5411 Grocery
5541 Fuel

Suddenly spends:

6051 Crypto

Merchant risk scoring
------------------------------
CASE
    WHEN MCC_CODE='6051' THEN 'HIGH'
    WHEN MCC_CODE='7995' THEN 'HIGH'
    WHEN MCC_CODE='5411' THEN 'LOW'
END
----------------------------------------------
CASE
    WHEN MERCHANT_STATUS IN
    (
      'BLOCKED',
      'SUSPENDED'
    )
    THEN 'HIGH_RISK_MERCHANT'
END