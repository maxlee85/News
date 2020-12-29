-- this query grabs email from all current members from nyc metro area
-- the default ip address to use is based off of purchase location, however segment does not capture all purchase events
-- if the purchase event is not captured, the ip used is the one with the most captured events

with user_list as (
        select distinct a.user_id
          from (select user_id from aaptiv_core.aaptiv.subscription_facts_merged where merged_sub_exp_time > current_timestamp) a
    inner join etl.etl_core.user_purchase_ip b
            on a.user_id = b.user_id
    inner join (select * from aaptiv_core.geo_ip.ip_location where postal_code in (
                  select postal_code from aaptiv_core.geo_ip.ny_metro_zipcodes)
               ) c
            on b.ipv4 between c.network_start_integer and c.network_last_integer

    union

       select distinct a.user_id
         from (select user_id from aaptiv_core.aaptiv.subscription_facts_merged where merged_sub_exp_time > current_timestamp) a
   inner join etl.etl_core.user_event_ip_counts_test b
           on a.user_id = b.user_id
   inner join (select * from aaptiv_core.geo_ip.ip_location where postal_code in (
                  select postal_code from aaptiv_core.geo_ip.ny_metro_zipcodes)
              ) c
           on b.ipv4 between c.network_start_integer and c.network_last_integer
)

  select email
         from aaptiv_core.aaptiv.users_raw ur
   inner join user_list ul
           on ur.user_id = ul.user_id
        where ur.email is not null
