
/*
    Welcome to your first dbt model!
    Did you know that you can also configure models directly within SQL files?
    This will override configurations stated in dbt_project.yml

    Try changing "table" to "view" below
*/

{{ config(materialized='table') }}

with source_data as (
    select
        event_timestamp
        ,conversation_id
        ,user_id
        ,agent_id
        ,event
        ,event_value
        ,upper(coalesce(last_value(case when lower(event) = 'status_changed_to' then event_value end) over (partition by conversation_id order by event_timestamp), 'open')) as conversation_status
    from {{ ref('raw_conversation_events') }}
), conversation_agg as (
    select 
        conversation_id
        ,user_id
        ,conversation_status
        ,min(event_timestamp) as conversation_started_at
        ,count(distinct agent_id) as number_involved_agents
    from source_data
    group by 1,2,3
)
select *
from conversation_agg
