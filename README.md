# TAXFIX: DBT ASSESSMENT
## _Part 1: Fixing the conversation_

### Task 1
#### _Please use models/operations/schema.yml to create a stakeholder facing documentation._

 ***For a technical stakeholder***, please clone the [dbt-taxfix](https://github.com/WithKottary/dbt-taxfix) repository to your local machine. 
If you have dbt-core set up locally then execute the following commands
```sh
dbt docs generate
dbt docs serve
```
If you are using dbt cloud, then intialize the project and type the following command in the command bar
```sh
dbt docs generate
```
Generated documentation can be accessed by clicking on **_"page-like"_** icon present in the upper left corner of the dbt cloud browser IDE

***For a Business stakeholder***, documentation is hosted on github. One can access the documentation [here](https://withkottary.github.io/dbt-taxfix/#!/model/model.home_assignment.fact_conversations)

### Task 2
#### _Change the current data loading mechanism for fact_conversations table from full load to incremental load._

Repository: [dbt-taxfix](https://github.com/WithKottary/dbt-taxfix/blob/main/models/operations/fact_conversations_incremental.sql)

Incremental model is implemented as a sperate model under _models/operations/fact_conversations_incremental.sql_ & documentation can be found [here](https://withkottary.github.io/dbt-taxfix/#!/model/model.home_assignment.fact_conversations_incremental)

fact_conversations_incremental.sql 
```sh
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
```

## _Part 2: Fixing stakeholders needs_
### Task 2
#### _Which questions for clarification would you ask that stakeholder?_
- How do you define "contact reasons" in the context of these conversation events?   
_This question aims to clarify how the tags in the conversation events relate to contact reasons, as it seems there might be a mapping or categorization process involved._

- What specific metrics or insights are you looking to extract from the conversation events?  
_The specification of the particular metrics or insights required will steer the design of the new model and the queries needed to extract this information._

- Are there any other metrics or KPIs you are looking to calculate?  
_For example, the average duration of conversations for each tag or the frequency of tags per user._

- Are there any specific dimensions or attributes outside of the current model that should be included in the analysis?  
_It's possible that additional contextual information could enhance the analysis, such as user demographics, agent details, or other event types not currently captured._

- Over what time period would you like to track the change in contact reasons? Do you want to analyze the tags on a daily, weekly, monthly, or yearly basis? Do you need historical data to be considered?  
_Knowing whether you need historical data or just snapshots at certain times & details of the timeframe will influence the granularity of the model._

- How often would you need this data refreshed or updated?  
_The frequency of access will impact the performance considerations of the model, especially if real-time or near-real-time analytics are required._

- How would you like the results to be presented? For example, as dashboards on our BI tool, or as tables? (depending if the stakeholder/end-user is technial or buisness related) 
_This will allow us to plan efficiently & let us know if the ticket needs to be handed over to the Business Intelligence/Reporting team for visualization tasks_

### Task 2
#### _Create tickets/ epics for the task above. You may base the ticket specification on reasonable responses from your clarifying questions above._

***Assumption:*** 
- Assuming that the requirement is to enrich the fact_conversations model & maintain it's structural integrity (due to downstream impact on production data)
- Contact reason is the same as tags assigned (1 to 1 mapping). No categorization such as payments = finance & app_question, login = technical
- For dimension tables certain columns are assumed to be available
- Stakeholder requested the data to be presented as a dashboard in company BI tool
- BI/Reporting team has a separate ticketing board 

I would create one epic & assign all tickets related to this task under this epic 

***Epic: Propose a structure for dimensional modelling and enhancement for Contact Reason Analysis***  
Description: This epic covers the scoping & sparring sessions to assess a potential upgrade of existing model structure and technical implementation of a comprehensive analysis framework for understanding the reasons for customer contacts over time using contact reasons/tags.

    Ticket 1: Scoping - Define Metrics and Insights on Contact Reason Analysis
        Tasks:
            - Consult with stakeholder/s to gather requirements & answers to the questions from task 1
            - Determine time period granularity for tracking changes in tags.
            - Identify any missing data or transformations needed that is not accounted for.
                
    Ticket 2: Define an updgrade to exisiting database structure
        Tasks:
            - Think of dimensional modelling that is flexible and scalable
            - Sparring sessions with one or two team members to check for viability of the proposed structure.

    Ticket 3: Dimensional modeling 
        SubTask 1: Create & test a date dimension table 
            Description: Introduce a dim_date table, consisting of columns date, year, month, day, day_of_week & week_of_year

        SubTask 2: Create & test a user dimension table
            Description: Introduce a dim_user table consisting of columns id, first_name, last_name, email, phone, email, country

        SubTask 3: Create & test a agent dimension table
            Description: Introduce a dim_agent table consisting of columns id, first_name, last_name, email, phone, supervisor_id, department

        SubTask 4: Create & test a fact_conversations lifecycle table
            Description: Introduce a fact_conversations_lifecycle table consisting of columns id, user_id, status, opened_at, closed_at, number_involved_agents, number_tags_assigned, interaction_between_customer, hours_to_resolve, payments_related, app_related, login_related

        SubTask 5: Documentation 

    Ticket 5: Contact reason driver analysis dashboard   
        Description: This is a placeholder ticket that will be linked to corresponding ticket under BI/Reporting team's board 

### Task 3
#### _Taking dimensional modeling into account, propose modifications to the existing dbt model that can be consumed by standard self-service reporting tools. Support your explanation of the model with an ERD._

Based on that data in RAW_CONVERSATIONS_EVENTS, i would introduce dim_date, dim_users & dim_agent as dimensions & enrich fact_conversations model. 

***Assumption:*** 
- Assuming that the requirement is to enrich the fact_conversations model & maintain it's structural integrity (due to downstream impact on production data)
- Assuming that reporting task handled by the BI/reporting team or analytics team, fact & dimension tables will be created and made available for them to further answer the business questions.
- Contact reason is the same as tags assigned (1 to 1 mapping). No categorization such as payments = finance & app_question, login = technical
- For dimension tables certain columns are assumed to be available
- Although dim_agent has no relation to fact_conversations table, it is assumed that there are other tables outside the scope of the data presented in this case study to which agent as a relation to. Hence we will proceed to create dim_agent
- Provided data is not sufficient to assume that there is a  ***tags*** source. In the event that ***tags*** are defined say in a CRM tool like salesforce then we can have dim_tags as a dimension. In this scenario, the microservice that logs conversation_events will need to incorporate tag_id 

***IMPORTANT*** 
**- fact_conversations is renamed to fact_conversation_lifecycle in order to avoid conflict with fact_conversations model provided at the start of the case study.**

To maintain uniformity & strucuture, staging table is created from the seed file.
>stg_conversation_events is to be implemented under models/staging/operations/stg_conversation_events.sql [see in repo](https://github.com/WithKottary/dbt-taxfix/blob/main/models/staging/operations/stg_conversation_events.sql)
```sh
{{ config(materialized='table') }}
SELECT
event_timestamp
,   conversation_id
,   user_id
,   agent_id
,   event
,   event_value
FROM {{ ref('raw_conversation_events') }}
```

>dim_date is to be implemented under models/marts/operations/dim_date.sql [see in repo](https://github.com/WithKottary/dbt-taxfix/blob/main/models/marts/operations/dim_date.sql)
```sh
{{ config(materialized='table') }}
WITH date_generation AS (
SELECT
        DATE(DATEADD(DAY, SEQ4(), '2016-01-01')) AS date, 
FROM TABLE(GENERATOR(ROWCOUNT => 30681))
)
SELECT
    date,
    EXTRACT(YEAR FROM date) AS year,
    EXTRACT(MONTH FROM date) AS month,
    EXTRACT(DAY FROM date) AS day,
    DAYOFWEEK(date) AS day_of_week,
    WEEKOFYEAR(date) AS week_of_year
FROM date_generation
```

>dim_user is to be implemented under models/marts/operations/dim_user.sql [see in repo](https://github.com/WithKottary/dbt-taxfix/blob/main/models/marts/operations/dim_user.sql)
```sh
{{ config(materialized='table') }}
SELECT DISTINCT
    user_id as id,
    'TO_BE_CONUSMED_FROM_SOURCE' AS first_name,  -- Placeholder, replace with actual first name field
    'TO_BE_CONUSMED_FROM_SOURCE' AS last_name,   -- Placeholder, replace with actual last name field
    'TO_BE_CONUSMED_FROM_SOURCE' AS email,       -- Placeholder, replace with actual email field
    'TO_BE_CONUSMED_FROM_SOURCE' AS phone,       -- Placeholder, replace with actual phone field
    'TO_BE_CONUSMED_FROM_SOURCE' AS country      -- Placeholder, replace with actual country field
FROM {{ ref('stg_conversation_events') }}  
```

>dim_agent is to be implemented under models/marts/operations/dim_agent.sql [see in repo](https://github.com/WithKottary/dbt-taxfix/blob/main/models/marts/operations/dim_agent.sql)
```sh
{{ config(materialized='table') }}
SELECT DISTINCT
    agent_id as id,                                 
    'TO_BE_CONUSMED_FROM_SOURCE' AS first_name,      -- Placeholder, replace with actual first name field
    'TO_BE_CONUSMED_FROM_SOURCE' AS last_name,       -- Placeholder, replace with actual last name field
    'TO_BE_CONUSMED_FROM_SOURCE' AS email,           -- Placeholder, replace with actual email field
    'TO_BE_CONUSMED_FROM_SOURCE' AS phone,           -- Placeholder, replace with actual phone field
    'TO_BE_CONUSMED_FROM_SOURCE' AS supervisor_id,   -- Placeholder, replace with actual supervisor id field
    'TO_BE_CONUSMED_FROM_SOURCE' AS department,      -- Placeholder, replace with actual department field
FROM {{ ref('stg_conversation_events') }} 
WHERE agent_id IS NOT NULL  
```


>fact_conversation_lifecycle is to be implemented under models/marts/operations/fact_conversation_lifecycle.sql [see in repo](https://github.com/WithKottary/dbt-taxfix/blob/main/models/marts/operations/fact_conversation_lifecycle.sql)
```sh
{{ config(materialized='table') }}
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
        ,count(case when event in('hour','customer_message_received','message_sent_to_customer') then event_value end) as interaction_between_customer
        ,case when status = 'CLOSED' then TIMESTAMPDIFF(minute,  min(event_timestamp), max(event_timestamp))/60 else null end as hours_to_resolve
        , sum(payments) as payments_related
        , sum(app_question) as app_related
        , sum(login) as login_related
    FROM source_data
    GROUP BY 1,2,3
)
SELECT * 
FROM conversation_agg
```
Please find ERD to the proposed dimensional modelling [ERD_TAXFIX](https://drive.google.com/file/d/1BLCTF_jT9t8ZJED95tzhotgKs5wVIaJO/view?usp=sharing) & the supporting code is present under ***models/marts/*** & ***models/staging/*** in the [dbt-taxfix](https://github.com/WithKottary/dbt-taxfix) repository

> Alternatively, i would like to propose another approach where we can retain data from  **raw_conversation_events** as a [***factless***](https://www.kimballgroup.com/data-warehouse-business-intelligence-resources/kimball-techniques/dimensional-modeling-techniques/factless-fact-table/) fact table i.e. fact_conversation_events 
> - Events and Transactions: Each row in the table represents an event or transaction (e.g., customer messages received, status changes, agent assignments) that has occurred within a conversation.
> - Measures and Facts: Although there are no traditional numeric measures, the events themselves are the facts being recorded. The EVENT_TIMESTAMP is a measure of when each event occurred.
> - Granular Data: The data is very granular, capturing individual events as they happen.

> As the case study presents a very small subset of data, it is not possible to fully understand how these data interact. For example: Are there more tags? How will new tags be introduced? What if we decide to upgrade the app as Taxfix grows and incorporate new types of events?

> Considering these questions and the need for adaptability, this approach provides room for flexibility and scalability. The factless fact table would also assist data analysts in their analysis, as it provides granular event data and offers them the opportunity to answer various business questions.

> In an ideal work scenario, this is where we would discuss with the rest of the team to assess the viability of this approach and decide on an outcome.

> **Please find the ERD [here](https://drive.google.com/file/d/1GVWb7WxdcdrpzLCnocuERFhoP6vxm3Nk/view?usp=sharing)**


## _Part 3: Fixing the deployment process_

### Task 1
#### _Please outline challenges that you see with this approach._

 - The only testing environment is the Snowflake Sandbox, which might not accurately reflect the production environment's data volume, schema, or performance characteristics. The current approach only ensures that code is reviewed but not thoroughly tested in a production-like environment before being merged into the master branch. 

 - The process jumps directly from development (feature branches) to production (master branch) without an intermediate staging environment. This can lead to untested changes being deployed to production, increasing the risk of errors, downtime, and data inconsistencies.

 - Relying only on manual approval for merging PRs into the master branch can slow down the deployment process, especially in teams with high volumes of changes or limited reviewers. This leads to delays in merging and deploying critical fixes or features.

 - The current process lacks integration with CI/CD tools (jenkins) that could automatically run dbt tests and checks before code is merged.

 - Once changes are merged into the master branch and deployed, rolling back bugs or failure might be challenging without a robust version control and rollback strategy. This increases risk and potential downtime during recovery from failed deployments.

 - The process does not explicitly mention how dependencies between dbt models or external data sources are managed and tested. Unresolved dependencies can lead to build failures or incorrect data transformations in production.

 - The process lacks mention of monitoring deployed models and alerting mechanisms for failures or bugs. This can lead to delay in identifying and addressing issues post-deployment.


### Task 2
#### _Suggest improvements to the deployment process. List specific details on how you would increase confidence in correctness of deployments._

 - Before deploying to production, introduce a staging environment that mirrors the production setup. This allows for testing dbt models with production-like data and configurations. This reduces the risk of deploying untested changes to production

 - Leverage dbt's built-in testing capabilities and assertion scripts to automatically validate data transformations and model outputs against expected results. This helps indentifying errors early and prevents downstream impacts

 - Integrate Continuous Integration/Continuous Deployment (CI/CD) tools  to automatically run dbt tests (e.g., dbt test, dbt run) on feature branches before merging

 - Regularly review and optimize dbt job configurations, environment settings, and dbt commands to ensure relevance, optimal performance and scalability. 

 - Configure dbt deploy jobs to run on schedules or in response to specific events (CRON), ensuring consistent execution of data transformations. This automates deployment processes, improves pipeline efficiency and primarily ensures that the data is provided to the business at expected intervals

 - Set up monitoring and alerting for dbt jobs in production. Use Snowflake's query Monitor and dbt Cloud’s job monitoring to track performance, detect anomalies & notify the team on failures. This provides an opportunity to act early on failures.

 - Provide training on best practices for writing dbt code and conducting code reviews. 
 
 - Maintain comprehensive documentation of the deployment process, testing strategies, and rollback procedures. Encourage pair or mob programming & sparring sessions for complex changes/tasks.

 - Explore the possibilty of dbt Assist in your development process, an AI-powered tool to generate documentation and tests automatically, boosting productivity and enhancing data quality.
 



By introducing a staging environment, automating testing and deployment processes through CI/CD integration, leveraging advanced tools for data quality checks, optimizing deploy jobs, scheduling regular deployments & proactive monitoring of failures, organizations can significantly increase confidence in the correctness of dbt deployments. These improvements not only enhance the reliability and efficiency of data transformation workflows but also contribute to better data quality and decision-making capabilities.