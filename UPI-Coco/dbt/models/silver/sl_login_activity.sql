{{
    config(
        materialized='incremental',
        unique_key='LOGIN_ID',
        incremental_strategy='merge',
        post_hook=[
            "UPDATE {{ this }} t
             SET t.IS_CURRENT = 'N'
             WHERE t.IS_CURRENT = 'Y'
               AND t.LOGIN_ID IN (
                   SELECT s.LOGIN_ID FROM {{ this }} s
                   WHERE s.IS_CURRENT = 'Y'
                   GROUP BY s.LOGIN_ID HAVING COUNT(*) > 1
               )
               AND t.CREATED_DATE_TIME < (
                   SELECT MAX(s2.CREATED_DATE_TIME) FROM {{ this }} s2
                   WHERE s2.LOGIN_ID = t.LOGIN_ID AND s2.IS_CURRENT = 'Y'
               )"
        ]
    )
}}

with source as (
    select
        cast(LOGIN_ID as VARCHAR(100)) as LOGIN_ID,
        cast(CUSTOMER_ID as VARCHAR(50)) as CUSTOMER_ID,
        cast(DEVICE_ID as VARCHAR(100)) as DEVICE_ID,
        cast(LOGIN_TIME as TIMESTAMP) as LOGIN_TIME,
        cast(LOGIN_STATUS as VARCHAR(30)) as LOGIN_STATUS,
        cast(COUNTRY as VARCHAR(100)) as COUNTRY,
        cast(STATE as VARCHAR(100)) as STATE,
        cast(CITY as VARCHAR(100)) as CITY,
        cast(IP_ADDRESS as VARCHAR(100)) as IP_ADDRESS,
        CREATED_LOAD_ID,
        CREATED_DATE_TIME
    from {{ ref('v_login_activity') }}
),

hashed as (
    select
        *,
        md5(
            coalesce(LOGIN_ID, '^') || '|' ||
            coalesce(CUSTOMER_ID, '^') || '|' ||
            coalesce(DEVICE_ID, '^') || '|' ||
            coalesce(cast(LOGIN_TIME as VARCHAR), '^') || '|' ||
            coalesce(LOGIN_STATUS, '^') || '|' ||
            coalesce(COUNTRY, '^') || '|' ||
            coalesce(STATE, '^') || '|' ||
            coalesce(CITY, '^') || '|' ||
            coalesce(IP_ADDRESS, '^')
        ) as HASH_DIFF,
        'Y' as IS_CURRENT
    from source
)

{% if is_incremental() %}

    select h.*
    from hashed h
    left join {{ this }} t
        on h.LOGIN_ID = t.LOGIN_ID and t.IS_CURRENT = 'Y'
    where t.LOGIN_ID is null or h.HASH_DIFF != t.HASH_DIFF

{% else %}

    select * from hashed

{% endif %}
