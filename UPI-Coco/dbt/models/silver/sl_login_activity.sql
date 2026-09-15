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
                 SELECT LOGIN_ID, MAX(CREATED_LOAD_ID) as LATEST_LOAD_ID
                 FROM {{ this }}
                 WHERE IS_CURRENT = 'Y'
                 GROUP BY LOGIN_ID
                 HAVING COUNT(*) > 1
             ) dup
             WHERE t.LOGIN_ID = dup.LOGIN_ID
               AND t.IS_CURRENT = 'Y'
               AND t.CREATED_LOAD_ID < dup.LATEST_LOAD_ID"
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
        cast(CREATED_LOAD_ID as NUMBER) as CREATED_LOAD_ID,
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
        'Y' as IS_CURRENT,
        NULL::TIMESTAMP_NTZ as UPDATED_DATE_TIME,
        NULL::NUMBER as UPDATED_LOAD_ID
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
