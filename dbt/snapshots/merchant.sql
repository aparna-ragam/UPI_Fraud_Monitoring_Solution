{% snapshot sl_merchant %}

{{
    config(
        target_schema='transform',
        unique_key='merchant_id',
        strategy='check',
        check_cols = 'all',
        snapshot_meta_column_names={
        "dbt_valid_from": "created_date_time",
        "dbt_valid_to": "updated_date_time",
        "dbt_scd_id": "scd_id",
        "dbt_is_current": "is_current"
        }
    )
}}

select
    merchant_id,
    merchant_name,
    merchant_category,
    case
        when merchant_category='Grocery' then '5411'
        when merchant_category='Fuel' then '5541'
        when merchant_category='Retail' then '6000'
    else 9999
    end as merchant_code,
    merchant_status,
    case 
        when merchant_code in ('5411','5541','5812') then 'LOW'
        when merchant_code in ('6000') then 'MEDIUM'
    else 'HIGH_RISK'
    end as risk_rating,
    created_load_id    
from {{ ref('v_merchant') }}

{% endsnapshot %}