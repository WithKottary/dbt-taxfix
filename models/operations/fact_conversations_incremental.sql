{{ config(
    materialized='incremental',
    unique_key='conversation_id'
) }}

with source_data as (
        select
            event_timestamp,
            conversation_id,
            current_timestamp as updated_at,
            user_id,
            agent_id,
            event,
            event_value,
            upper(coalesce(last_value(case when lower(event) = 'status_changed_to' then event_value end) 
                over (partition by conversation_id order by event_timestamp), 'open')) as conversation_status
        from {{ ref('raw_conversation_events') }}
    {% if is_incremental() %}
        where event_timestamp > (select coalesce(max(updated_at),'2016-01-01') from {{ this }})
    {% endif %}

)
, conversation_agg as (
    select 
        conversation_id,
        user_id,
        conversation_status,
        updated_at,
        min(event_timestamp) as conversation_started_at,
        count(distinct agent_id) as number_involved_agents
    from source_data s 
    group by 1, 2, 3, 4 
)

select *
from conversation_agg