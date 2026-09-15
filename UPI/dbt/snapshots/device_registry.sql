{% snapshot sl_device_registry %}

{{
    config(
        target_schema='transform',
        unique_key='device_id',
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
    device_id,
    customer_id,
    device_fingerprint,
    device_os,
    trusted_flag,
    datediff(day,DEVICE_REGISTRATION_DATE,current_date) as device_age_days,
    case when trusted_flag = 'N' then 40
         when device_age_days < 30 then 30 
	 else 0 
     end as device_risk_score,
        created_load_id    
from {{ ref('v_device_registry') }}

{% endsnapshot %}