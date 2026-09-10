{{ config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key=['watchlist_id','hash_diff'],
    on_schema_change='append_new_columns',
    pre_hook=[
        "
        update {{ this }} as tgt
        set is_current = false,
            updated_date_time = current_timestamp()
        where exists (
            select 1
            from {{ ref('v_watchlist') }} src
            where src.watchlist_id = tgt.watchlist_id
              and src.hash_diff <> tgt.hash_diff
              and tgt.is_current = true
        )
        "
    ]
) }}


with source as (
select
    watchlist_id,
    entity_type,
    entity_id,
    entity_name,
    risk_level,
    created_load_id,
md5(
        coalesce(watchlist_id,'^') || '|' ||
        coalesce(entity_type,'^') || '|' ||
	coalesce(entity_id,'^') || '|' ||
	coalesce(entity_name,'^') || '|' ||
        coalesce(risk_level,'^')
    ) as hash_diff
from  {{ ref('v_watchlist') }}
)

select
    watchlist_id,
    entity_type,
    entity_id,
    entity_name,
    risk_level,
    hash_diff,
    created_load_id,
    current_timestamp() as created_date_time,
    null as updated_date_time,
    true as is_current
    from source