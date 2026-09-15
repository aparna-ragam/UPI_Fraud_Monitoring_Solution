{{
    config(
        materialized='incremental',
        incremental_strategy='append',
        on_schema_change='append_new_columns',
        post_hook=[
            "UPDATE {{ this }} t
             SET t.IS_CURRENT = 'N',
                 t.UPDATED_DATE_TIME = CURRENT_TIMESTAMP(),
                 t.UPDATED_LOAD_ID = dup.LATEST_LOAD_ID
             FROM (
                 SELECT BENEFICIARY_ID, MAX(CREATED_LOAD_ID) as LATEST_LOAD_ID
                 FROM {{ this }}
                 WHERE IS_CURRENT = 'Y'
                 GROUP BY BENEFICIARY_ID
                 HAVING COUNT(*) > 1
             ) dup
             WHERE t.BENEFICIARY_ID = dup.BENEFICIARY_ID
               AND t.IS_CURRENT = 'Y'
               AND t.CREATED_LOAD_ID < dup.LATEST_LOAD_ID"
        ]
    )
}}

with txn_agg as (
    select
        BENEFICIARY_ID,
        sum(cast(TXN_AMOUNT as NUMBER(18,2))) as TXN_AMOUNT,
        count(distinct CUSTOMER_ID) as CNT
    from {{ ref('sl_transaction') }}
    where IS_CURRENT = 'Y'
    group by BENEFICIARY_ID
),

source as (
    select
        cast(b.BENEFICIARY_ID as VARCHAR(100)) as BENEFICIARY_ID,
        cast(b.CUSTOMER_ID as VARCHAR(50)) as CUSTOMER_ID,
        cast(b.BENEFICIARY_NAME as VARCHAR(255)) as BENEFICIARY_NAME,
        cast(b.BENEFICIARY_VPA as VARCHAR(255)) as BENEFICIARY_VPA,
        cast(b.BANK_NAME as VARCHAR(255)) as BANK_NAME,
        b.BENEFICIARY_CREATED_DATE,
        t.TXN_AMOUNT,
        t.CNT,
        CASE
            WHEN EXISTS (
                SELECT 1 FROM {{ ref('sl_watchlist') }} w
                WHERE w.ENTITY_TYPE = 'BENEFICIARY'
                  AND w.ENTITY_ID = b.BENEFICIARY_ID
                  AND w.IS_CURRENT = 'Y'
            ) THEN 'HIGH'
            WHEN t.TXN_AMOUNT > 1000000 THEN 'HIGH'
            WHEN t.CNT > 10 THEN 'HIGH'
            WHEN DATEDIFF(DAY, cast(b.BENEFICIARY_CREATED_DATE as DATE), CURRENT_DATE) < 30 THEN 'MEDIUM'
            ELSE 'LOW'
        END as RISK_RATING,
        cast(b.CREATED_LOAD_ID as NUMBER) as CREATED_LOAD_ID,
        b.CREATED_DATE_TIME
    from {{ ref('v_beneficiary') }} b
    left join txn_agg t on b.BENEFICIARY_ID = t.BENEFICIARY_ID
),

hashed as (
    select
        BENEFICIARY_ID, CUSTOMER_ID, BENEFICIARY_NAME, BENEFICIARY_VPA,
        BANK_NAME, RISK_RATING,
        md5(
            coalesce(BENEFICIARY_ID, '^') || '|' ||
            coalesce(CUSTOMER_ID, '^') || '|' ||
            coalesce(BENEFICIARY_NAME, '^') || '|' ||
            coalesce(BENEFICIARY_VPA, '^') || '|' ||
            coalesce(BANK_NAME, '^') || '|' ||
            coalesce(RISK_RATING, '^')
        ) as HASH_DIFF,
        'Y' as IS_CURRENT,
        CREATED_LOAD_ID, CREATED_DATE_TIME,
        NULL::TIMESTAMP_NTZ as UPDATED_DATE_TIME,
        NULL::NUMBER as UPDATED_LOAD_ID
    from source
)

{% if is_incremental() %}

    select h.*
    from hashed h
    left join {{ this }} t
        on h.BENEFICIARY_ID = t.BENEFICIARY_ID and t.IS_CURRENT = 'Y'
    where t.BENEFICIARY_ID is null or h.HASH_DIFF != t.HASH_DIFF

{% else %}

    select * from hashed

{% endif %}
