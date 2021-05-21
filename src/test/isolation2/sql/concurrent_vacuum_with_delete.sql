create extension if not exists gp_inject_fault;

create table sales_row (id int, date date, amt decimal(10,2))
with (appendonly=true) distributed by (id)
partition by range (date)
( start (date '2008-01-01') inclusive
end (date '2009-01-01') exclusive
every (interval '1 month') );

insert into sales_row values (generate_series(1,1000),'2008-01-01',10);
update sales_row set amt = amt + 1;

select gp_inject_fault('vacuum_hold_lock', 'suspend', dbid) from gp_segment_configuration where role = 'p' and content = -1;

1&: vacuum sales_row_1_prt_1;

select gp_wait_until_triggered_fault('vacuum_hold_lock', 1, dbid) from gp_segment_configuration where role = 'p' and content = -1;

2&: delete from sales_row;

select pg_sleep(2);

select gp_inject_fault('vacuum_hold_lock', 'reset', dbid) from gp_segment_configuration where role = 'p' and content = -1;

1<:
2<:

1q:
2q:

-- cached plan

drop table sales_row;
create table sales_row (id int, date date, amt decimal(10,2))
with (appendonly=true) distributed by (id)
partition by range (date)
( start (date '2008-01-01') inclusive
end (date '2009-01-01') exclusive
every (interval '1 month') );

insert into sales_row values (generate_series(1,1000),'2008-01-01',10);
update sales_row set amt = amt + 1;



1: prepare test as delete from sales_row;

select gp_inject_fault('vacuum_hold_lock', 'suspend', dbid) from gp_segment_configuration where role = 'p' and content = -1;

2&: vacuum sales_row_1_prt_1;

select gp_wait_until_triggered_fault('vacuum_hold_lock', 1, dbid) from gp_segment_configuration where role = 'p' and content = -1;

1&: execute test;

select pg_sleep(2);

select gp_inject_fault('vacuum_hold_lock', 'reset', dbid) from gp_segment_configuration where role = 'p' and content = -1;

1<:
2<:

1q:
2q:

drop table sales_row;