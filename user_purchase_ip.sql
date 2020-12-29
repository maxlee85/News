-- This table determines the ip address when a member successfully purchases a membership.

use role etl;

select current_timestamp, 'Creating Staging Table...';

drop table if exists etl.etl_core.user_purchase_ip_staging;

create table etl.etl_core.user_purchase_ip_staging

as

with purchase_sources as (
     select coalesce(a.user_id, b.user_id) as user_id
          , a.timestamp
          , a.context_ip as ip
          , parse_ip(a.context_ip, 'INET')['ipv4']::int as ipv4
       from segment_events.web_flows.action a
  left join (select distinct email, metadata_id as user_id from aaptiv_core.stripe.customers) b
         on a.email = b.email
      where a.type = 'payment.PURCHASE_PLAN_SUCCESS'
        and a.path <> '/render2'
  union all
     select coalesce(a.user_id, b.user_id)
          , a.timestamp
          , a.context_ip as ip
          , parse_ip(a.context_ip, 'INET')['ipv4']::int as ipv4
       from segment_events.web_flows.wsf_step a
  left join (select distinct email, metadata_id as user_id from aaptiv_core.stripe.customers) b
         on strip_quotes(parse_url(a.context_page_url, 1):parameters:userEmail) = b.email
      where a.step = 'confirmation'
        and a.user_id is null
  union all 
     select user_id
          , timestamp
          , context_ip as ip
          , parse_ip(context_ip, 'INET')['ipv4']::int as ipv4
       from aaptiv_core.segment_ios.subscription_subscribe
      where status = 'success'
  union all
     select user_id
          , timestamp
          , context_ip as ip
          , parse_ip(context_ip, 'INET')['ipv4']::int as ipv4
       from aaptiv_core.segment_android.subscription_subscribe
      where status = 'success'
)

    select distinct p.user_id
         , u.email
         , p.timestamp
         , p.ip
         , p.ipv4
      from purchase_sources p
 left join aaptiv_core.aaptiv.users_raw u on p.user_id = u.user_id
     where p.user_id is not null
;

-- Issue grants before table swap
--
select current_timestamp, 'Issuing Grants...';

use role sysadmin;
grant select on all tables in schema etl.etl_core to role etl;
grant select on all tables in schema etl.etl_core to role aaptiv_core_ro;

-- Swap tables
--
select current_timestamp, 'Swapping tables...';

use role etl;
create table if not exists etl.etl_core.user_purchase_ip like etl.etl_core.user_purchase_ip_staging;
alter table etl.etl_core.user_purchase_ip_staging swap with etl.etl_core.user_purchase_ip;
drop table if exists etl.etl_core.user_purchase_old;
alter table etl.etl_core.user_purchase_ip_staging rename to etl.etl_core.user_purchase_old;

-- Script End
--
select current_timestamp, 'ALL Done.';
