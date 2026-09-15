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
                 SELECT PASSWORD_CHANGE_ID, MAX(CREATED_LOAD_ID) as LATEST_LOAD_ID
                 FROM {{ this }}
                 WHERE IS_CURRENT = 'Y'
                 GROUP BY PASSWORD_CHANGE_ID
                 HAVING COUNT(*) > 1
             ) dup
             WHERE t.PASSWORD_CHANGE_ID = dup.PASSWORD_CHANGE_ID
               AND t.IS_CURRENT = 'Y'
               AND t.CREATED_LOAD_ID < dup.LATEST_LOAD_ID"
        ]
    )
}}

with source as (
    select
        cast(v.PASSWORD_CHANGE_ID as VARCHAR(100)) as PASSWORD_CHANGE_ID,
        cast(v.CUSTOMER_ID as VARCHAR(50)) as CUSTOMER_ID,
        cast(v.CHANGE_TIME as TIMESTAMP) as CHANGE_TIME,
        cast(v.CHANGE_CHANNEL as VARCHAR(50)) as CHANGE_CHANNEL,
        cast(v.DEVICE_ID as VARCHAR(100)) as DEVICE_ID,
        extract(hour from cast(v.CHANGE_TIME as TIMESTAMP)) as CHANGE_HOUR,
        dayname(cast(v.CHANGE_TIME as TIMESTAMP)) as CHANGE_DAY_OF_WEEK,
        d.DEVICE_RISK_SCORE as DEVICE_RISK_SCORE,
        CASE
            WHEN d.DEVICE_RISK_SCORE >= 80 THEN 'HIGH'
            WHEN extract(hour from cast(v.CHANGE_TIME as TIMESTAMP)) between 0 and 4 THEN 'MEDIUM'
            ELSE 'LOW'
        END as PASSWORD_CHANGE_RISK,
        cast(v.CREATED_LOAD_ID as NUMBER) as CREATED_LOAD_ID,
        v.CREATED_DATE_TIME
    from {{ ref('v_password_change') }} v
    left join {{ ref('sl_device') }} d
        on v.DEVICE_ID = d.DEVICE_ID and d.IS_CURRENT = 'Y'
),

hashed as (
    select
        *,
        md5(
            coalesce(PASSWORD_CHANGE_ID, '^') || '|' ||
            coalesce(CUSTOMER_ID, '^') || '|' ||
            coalesce(cast(CHANGE_TIME as VARCHAR), '^') || '|' ||
            coalesce(CHANGE_CHANNEL, '^') || '|' ||
            coalesce(DEVICE_ID, '^') || '|' ||
            coalesce(cast(DEVICE_RISK_SCORE as VARCHAR), '^') || '|' ||
            coalesce(PASSWORD_CHANGE_RISK, '^')
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
        on h.PASSWORD_CHANGE_ID = t.PASSWORD_CHANGE_ID and t.IS_CURRENT = 'Y'
    where t.PASSWORD_CHANGE_ID is null or h.HASH_DIFF != t.HASH_DIFF

{% else %}

    select * from hashed

{% endif %}
