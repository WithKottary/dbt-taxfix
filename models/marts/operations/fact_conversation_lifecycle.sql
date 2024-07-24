WITH source_data AS (
    SELECT
        event_timestamp
        ,conversation_id
        ,user_id
        ,agent_id
        ,event
        ,event_value
        ,upper(coalesce(last_value(case when lower(event) = 'status_changed_to' then event_value end) over (partition by conversation_id order by event_timestamp), 'open')) as status
        , case when event_value = 'payments' then  1  else 0 end as payments
        , case when event_value = 'app_question' then  1  else 0 end as app_question
        , case when event_value = 'login' then  1 else 0 end as login
    FROM {{ ref('stg_conversation_events') }}
)
, conversation_agg AS (
    SELECT 
        conversation_id as id
        ,user_id
        ,status
        ,min(event_timestamp) as opened_at
        ,case when status = 'CLOSED' then max(event_timestamp) else null end as closed_at
        ,count(distinct agent_id) as number_involved_agents
        ,count(distinct case when event = 'tag_assigned' then event_value end) as number_tags_assigned
        ,count(case when event in('customer_message_received','message_sent_to_customer') then event_value end) as interaction_between_customer
        ,case when status = 'CLOSED' then TIMESTAMPDIFF(minute,  min(event_timestamp), max(event_timestamp))/60 else null end as hours_to_resolve
        , sum(payments) as payments_related
        , sum(app_question) as app_related
        , sum(login) as login_related
    FROM source_data
    GROUP BY 1,2,3
)
SELECT * 
FROM conversation_agg
