{{
    config(
        materialized='incremental',
        unique_key='ACCOUNT_ID',
        incremental_strategy='merge',
        post_hook=[
            "UPDATE {{ this }} t
             SET t.IS_CURRENT = 'N'
             WHERE t.IS_CURRENT = 'Y'
               AND t.ACCOUNT_ID IN (
                   SELECT s.ACCOUNT_ID FROM {{ this }} s
                   WHERE s.IS_CURRENT = 'Y'
                   GROUP BY s.ACCOUNT_ID HAVING COUNT(*) > 1
               )
               AND t.CREATED_DATE_TIME < (
                   SELECT MAX(s2.CREATED_DATE_TIME) FROM {{ this }} s2
                   WHERE s2.ACCOUNT_ID = t.ACCOUNT_ID AND s2.IS_CURRENT = 'Y'
               )"
        ]
    )
}}

with source as (
    select
        cast(ACCOUNT_ID as VARCHAR(50)) as ACCOUNT_ID,
        cast(CUSTOMER_ID as VARCHAR(50)) as CUSTOMER_ID,
        cast(ACCOUNT_TYPE as VARCHAR(30)) as ACCOUNT_TYPE,
        cast(ACCOUNT_STATUS as VARCHAR(30)) as ACCOUNT_STATUS,
        cast(CURRENT_BALANCE as NUMBER(18,2)) as CURRENT_BALANCE,
        cast(AVAILABLE_BALANCE as NUMBER(18,2)) as AVAILABLE_BALANCE,
        cast(OPEN_DATE as DATE) as OPEN_DATE,
        DATEDIFF(DAY, cast(OPEN_DATE as DATE), CURRENT_DATE) as ACCOUNT_AGE_DAYS,
        CREATED_LOAD_ID,
        CREATED_DATE_TIME
    from {{ ref('v_account') }}
),

enriched as (
    select
        ACCOUNT_ID,
        CUSTOMER_ID,
        ACCOUNT_TYPE,
        ACCOUNT_STATUS,
        CURRENT_BALANCE,
        AVAILABLE_BALANCE,
        OPEN_DATE,
        ACCOUNT_AGE_DAYS,
        CASE
            WHEN ACCOUNT_AGE_DAYS < 30 THEN 'HIGH'
            WHEN CURRENT_BALANCE > 1000000 THEN 'MEDIUM'
            ELSE 'LOW'
        END as ACCOUNT_RISK_RATING,
        CREATED_LOAD_ID,
        CREATED_DATE_TIME
    from source
),

hashed as (
    select
        *,
        md5(
            coalesce(ACCOUNT_ID, '^') || '|' ||
            coalesce(CUSTOMER_ID, '^') || '|' ||
            coalesce(ACCOUNT_TYPE, '^') || '|' ||
            coalesce(ACCOUNT_STATUS, '^') || '|' ||
            coalesce(cast(CURRENT_BALANCE as VARCHAR), '^') || '|' ||
            coalesce(cast(AVAILABLE_BALANCE as VARCHAR), '^') || '|' ||
            coalesce(cast(OPEN_DATE as VARCHAR), '^') || '|' ||
            coalesce(ACCOUNT_RISK_RATING, '^')
        ) as HASH_DIFF,
        'Y' as IS_CURRENT
    from enriched
)

{% if is_incremental() %}

    select h.*
    from hashed h
    left join {{ this }} t
        on h.ACCOUNT_ID = t.ACCOUNT_ID and t.IS_CURRENT = 'Y'
    where t.ACCOUNT_ID is null or h.HASH_DIFF != t.HASH_DIFF

{% else %}

    select * from hashed

{% endif %}
