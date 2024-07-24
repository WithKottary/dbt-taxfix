{{ config(materialized='table') }}
SELECT
event_timestamp
,   conversation_id
,   user_id
,   agent_id
,   event
,   event_value
FROM {{ ref('raw_conversation_events') }}