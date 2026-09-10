{% snapshot sl_account %}

{{
    config(
        target_schema='transform',
        unique_key='account_id',
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
    account_id,
    account_status,
    account_type,
    current_balance,
    available_balance,
    open_date,
    datediff(day, open_date, current_date) as account_age_days,
        case 
            when datediff(day, open_date, current_date) < 30 then 'HIGH'
            when current_balance > 1000000 then 'MEDIUM'
            else 'LOW'
        end as account_risk_rating,
        created_load_id    
from {{ ref('v_account') }}

{% endsnapshot %}