{{ config(materialized='table') }}
SELECT DISTINCT
    user_id as id,
    'TO_BE_CONUSMED_FROM_SOURCE' AS first_name,  -- Placeholder, replace with actual user name field
    'TO_BE_CONUSMED_FROM_SOURCE' AS last_name,   -- Placeholder, replace with actual user name field
    'TO_BE_CONUSMED_FROM_SOURCE' AS email,       -- Placeholder, replace with actual user email field
    'TO_BE_CONUSMED_FROM_SOURCE' AS phone,       -- Placeholder, replace with actual user email field
    'TO_BE_CONUSMED_FROM_SOURCE' AS country      -- Placeholder, replace with actual user email field
FROM {{ ref('stg_conversation_events') }}