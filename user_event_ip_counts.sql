-- The user_event_ip_counts table calculates the number events that occurred per user per ip address.
-- The _test table shows the ip address with the most events.

use role etl;

select current_timestamp, 'Creating Staging Table...';

drop table if exists etl.etl_core.user_event_ip_counts_staging

create table etl.etl_core.user_event_ip_counts_staging

as

with user_ip_events as (
     select coalesce(a.user_id, b.user_id) as user_id
          , a.context_ip as ip
          , parse_ip(a.context_ip, 'INET')['ipv4']::int as ipv4
          , count(*) as events
       from aaptiv_core.segment_android.tracks a
  left join (select user_id, email from aaptiv_core.aaptiv.users_raw) b
         on a.context_traits_email = b.email
   group by 1,2,3
  union all
     select coalesce(a.user_id, b.user_id)
          , a.context_ip as ip
          , parse_ip(a.context_ip, 'INET')['ipv4']::int as ipv4
          , count(*) as events
       from aaptiv_core.segment_ios.tracks a
  left join (select user_id, email from aaptiv_core.aaptiv.users_raw) b
         on a.context_traits_email = b.email
   group by 1,2,3
)

 select user_id
      , ip
      , ipv4
      , sum(events) as num_events
      , row_number() over (partition by user_id order by num_events desc) as num_events_rank
   from user_ip_events
  where user_id is not null
  group by 1,2,3
;

drop table if exists etl.etl_core.user_event_ip_counts_test_staging

create table etl.etl_core.user_event_ip_counts_test_staging

as

select user_id
     , ip
     , ipv4
     , num_events
  from etl.etl_core.user_event_ip_counts_staging
 where num_events_rank = 1
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
create table if not exists etl.etl_core.user_event_ip_counts like etl.etl_core.user_event_ip_counts_staging;
alter table etl.etl_core.user_event_ip_counts_staging swap with etl.etl_core.user_event_ip_counts;
drop table if exists etl.etl_core.user_event_ip_counts_old;
alter table etl.etl_core.user_event_ip_counts_staging rename to etl.etl_core.user_event_ip_counts_old;
create table if not exists etl.etl_core.user_event_ip_counts_test like etl.etl_core.user_event_ip_counts_test_staging;
alter table etl.etl_core.user_event_ip_counts_test_staging swap with etl.etl_core.user_event_ip_counts_test;
drop table if exists etl.etl_core.user_event_ip_counts_test_old;
alter table etl.etl_core.user_event_ip_counts_test_staging rename to etl.etl_core.user_event_ip_counts_test_old;

-- Script End
--
select current_timestamp, 'ALL Done.';
