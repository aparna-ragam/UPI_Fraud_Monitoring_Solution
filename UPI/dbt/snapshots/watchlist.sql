{% snapshot sl_watchlist %}

{{
    config(
        target_schema='transform',
        unique_key='watchlist_id',
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
    watchlist_id,
    entity_type,
    entity_id,
    entity_name,
    risk_level,
        created_load_id    
from {{ ref('v_watchlist') }}

{% endsnapshot %}