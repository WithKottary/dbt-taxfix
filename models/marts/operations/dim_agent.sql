{{ config(materialized='table') }}
SELECT DISTINCT
    agent_id as id,                                  
    'TO_BE_CONUSMED_FROM_SOURCE' AS first_name,      -- Placeholder, replace with actual agent email field
    'TO_BE_CONUSMED_FROM_SOURCE' AS last_name,       -- Placeholder, replace with actual agent email field
    'TO_BE_CONUSMED_FROM_SOURCE' AS email,           -- Placeholder, replace with actual agent email field
    'TO_BE_CONUSMED_FROM_SOURCE' AS phone,           -- Placeholder, replace with actual agent email field
    'TO_BE_CONUSMED_FROM_SOURCE' AS supervisor_id,   -- Placeholder, replace with actual agent email field
    'TO_BE_CONUSMED_FROM_SOURCE' AS department,      -- Placeholder, replace with actual agent email field
FROM {{ ref('stg_conversation_events') }}
WHERE agent_id IS NOT NULL  