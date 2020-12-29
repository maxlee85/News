-- This query calculates if a users signup ip has the most associated events with that user.
-- SIGNUP_MAJORITY	NOT_SIGNUP_MAJORITY
-- 615564	          180681
-- 77.3% users have the most # of events at the signup ip address.
-- 9.1% of users have an unmapped zip.

with user_purchase_details as (
     select u.user_id
          , u.ip
          , u.ipv4
          , i.postal_code
          , row_number() over (partition by u.user_id order by u.timestamp desc) as row_num
       from etl.etl_core.user_purchase_ip u
 inner join aaptiv_core.geo_ip.ip_location i
         on u.ipv4 between i.network_start_integer and i.network_last_integer
),

test as (
     select a.user_id as user_id
          , a.ip as event_ip
          , a.ipv4 as event_ipv4
          , b.ipv4 as purchase_ipv4
          , case when i.postal_code is null then 'NULL' else i.postal_code end as event_postal_code
          , case when b.postal_code is null then 'NULL' else b.postal_code end as purchase_postal_code
          , a.num_events
          , case when a.ip = b.ip then true end as is_purchase_ip
          , case when is_purchase_ip then a.num_events end as purchase_ip_events
          , case when i.postal_code = b.postal_code then true end as is_same_as_purchase_zip
          , sum(a.num_events) over (partition by a.user_id) as all_events
       from etl.etl_core.user_event_ip_counts_test a
 inner join aaptiv_core.geo_ip.ip_location i
         on a.ipv4 between i.network_start_integer and i.network_last_integer
 inner join user_purchase_details b
         on a.user_id = b.user_id
        and b.row_num = 1
 )

 select count(distinct(case when is_same_as_purchase_zip = true then user_id end)) as same_purchase_signup_zip
      , count(distinct(case when is_same_as_purchase_zip is null then user_id end)) as not_same_purchase_signup_zip
      , count(distinct(case when is_purchase_ip = true then user_id end)) as purchase_majority
      , count(distinct(case when is_purchase_ip is null then user_id end)) as not_purchase_majority
      , count(distinct user_id) as all_users
 from test

 -- This query is similar to ^^ but calculates the users that have 50%+ of events with same ip as signup ip.

with user_signups as (
select user_id
     , ip
     , ipv4
     , row_number() over (partition by user_id order by timestamp desc) as row_num
  from etl.etl_core.user_signup_ip
),

test as (
     select a.user_id
          , a.ip
          , a.ipv4
          , a.num_events
          , case when a.ip = b.ip then true end as is_signup_ip
          , case when is_signup_ip then a.num_events end as signup_ip_events
          , sum(a.num_events) over (partition by a.user_id) as all_events
       from etl.etl_core.user_event_ip_counts a
 inner join user_signups b
         on a.user_id = b.user_id
        and b.row_num = 1
 ),

 metrics as (
   select user_id
        , signup_ip_events/all_events as ratio
     from test
 )

 select count(distinct(case when ratio > .5 then user_id end)) as above_50
      , count(distinct(case when ratio <= .5 then user_id end)) as below_50
   from metrics
