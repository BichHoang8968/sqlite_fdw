--
-- AGGREGATES
--
CREATE EXTENSION sqlite_fdw;
CREATE SERVER sqlite_svr FOREIGN DATA WRAPPER sqlite_fdw
OPTIONS (database '/tmp/sqlitefdw_test_core.db');
CREATE FOREIGN TABLE onek(
  unique1   int4 OPTIONS (key 'true'),
  unique2   int4,
  two     int4,
  four    int4,
  ten     int4,
  twenty    int4,
  hundred   int4,
  thousand  int4,
  twothousand int4,
  fivethous int4,
  tenthous  int4,
  odd     int4,
  even    int4,
  stringu1  name,
  stringu2  name,
  string4   name
) SERVER sqlite_svr;

CREATE FOREIGN TABLE aggtest (
  a       int2,
  b     float4
) SERVER sqlite_svr;

CREATE FOREIGN TABLE student (
  name    text,
  age     int4,
  location  point,
  gpa     float8
) SERVER sqlite_svr;

CREATE FOREIGN TABLE tenk1 (
  unique1   int4,
  unique2   int4,
  two     int4,
  four    int4,
  ten     int4,
  twenty    int4,
  hundred   int4,
  thousand  int4,
  twothousand int4,
  fivethous int4,
  tenthous  int4,
  odd     int4,
  even    int4,
  stringu1  name,
  stringu2  name,
  string4   name
) SERVER sqlite_svr;

CREATE FOREIGN TABLE INT8_TBL(
  q1 int8 OPTIONS (key 'true'),
  q2 int8 OPTIONS (key 'true')
) SERVER sqlite_svr;

CREATE FOREIGN TABLE INT4_TBL(f1 int4 OPTIONS (key 'true')) SERVER sqlite_svr; 

CREATE FOREIGN TABLE multi_arg_agg (a int OPTIONS (key 'true'), b int, c text) SERVER sqlite_svr;

CREATE FOREIGN TABLE VARCHAR_TBL(f1 varchar(4) OPTIONS (key 'true')) SERVER sqlite_svr;

CREATE FOREIGN TABLE FLOAT8_TBL(f1 float8 OPTIONS (key 'true')) SERVER sqlite_svr;

--Testcase 1:
SELECT avg(four) AS avg_1 FROM onek;

--Testcase 2:
SELECT avg(a) AS avg_32 FROM aggtest WHERE a < 100;

-- In 7.1, avg(float4) is computed using float8 arithmetic.
-- Round the result to 3 digits to avoid platform-specific results.

--Testcase 3:
SELECT avg(b)::numeric(10,3) AS avg_107_943 FROM aggtest;

--Testcase 4:
SELECT avg(gpa) AS avg_3_4 FROM ONLY student;


--Testcase 5:
SELECT sum(four) AS sum_1500 FROM onek;
--Testcase 6:
SELECT sum(a) AS sum_198 FROM aggtest;
--Testcase 7:
SELECT sum(b) AS avg_431_773 FROM aggtest;
--Testcase 8:
SELECT sum(gpa) AS avg_6_8 FROM ONLY student;

--Testcase 9:
SELECT max(four) AS max_3 FROM onek;
--Testcase 10:
SELECT max(a) AS max_100 FROM aggtest;
--Testcase 11:
SELECT max(aggtest.b) AS max_324_78 FROM aggtest;
--Testcase 12:
SELECT max(student.gpa) AS max_3_7 FROM student;

--Testcase 13:
SELECT stddev_pop(b) FROM aggtest;
--Testcase 14:
SELECT stddev_samp(b) FROM aggtest;
--Testcase 15:
SELECT var_pop(b) FROM aggtest;
--Testcase 16:
SELECT var_samp(b) FROM aggtest;

--Testcase 17:
SELECT stddev_pop(b::numeric) FROM aggtest;
--Testcase 18:
SELECT stddev_samp(b::numeric) FROM aggtest;
--Testcase 19:
SELECT var_pop(b::numeric) FROM aggtest;
--Testcase 20:
SELECT var_samp(b::numeric) FROM aggtest;

-- SQL2003 binary aggregates
--Testcase 21:
SELECT regr_count(b, a) FROM aggtest;
--Testcase 22:
SELECT regr_sxx(b, a) FROM aggtest;
--Testcase 23:
SELECT regr_syy(b, a) FROM aggtest;
--Testcase 24:
SELECT regr_sxy(b, a) FROM aggtest;
--Testcase 25:
SELECT regr_avgx(b, a), regr_avgy(b, a) FROM aggtest;
--Testcase 26:
SELECT regr_r2(b, a) FROM aggtest;
--Testcase 27:
SELECT regr_slope(b, a), regr_intercept(b, a) FROM aggtest;
--Testcase 28:
SELECT covar_pop(b, a), covar_samp(b, a) FROM aggtest;
--Testcase 29:
SELECT corr(b, a) FROM aggtest;

--Testcase 30:
SELECT count(four) AS cnt_1000 FROM onek;
--Testcase 31:
SELECT count(DISTINCT four) AS cnt_4 FROM onek;

--Testcase 32:
select ten, count(*), sum(four) from onek
group by ten order by ten;

--Testcase 33:
select ten, count(four), sum(DISTINCT four) from onek
group by ten order by ten;

-- user-defined aggregates
CREATE AGGREGATE newavg (
   sfunc = int4_avg_accum, basetype = int4, stype = _int8,
   finalfunc = int8_avg,
   initcond1 = '{0,0}'
);

CREATE AGGREGATE newsum (
   sfunc1 = int4pl, basetype = int4, stype1 = int4,
   initcond1 = '0'
);

CREATE AGGREGATE newcnt (*) (
   sfunc = int8inc, stype = int8,
   initcond = '0', parallel = safe
);

CREATE AGGREGATE newcnt ("any") (
   sfunc = int8inc_any, stype = int8,
   initcond = '0'
);

CREATE AGGREGATE oldcnt (
   sfunc = int8inc, basetype = 'ANY', stype = int8,
   initcond = '0'
);

create function sum3(int8,int8,int8) returns int8 as
'select $1 + $2 + $3' language sql strict immutable;

create aggregate sum2(int8,int8) (
   sfunc = sum3, stype = int8,
   initcond = '0'
);

--Testcase 34:
SELECT newavg(four) AS avg_1 FROM onek;
--Testcase 35:
SELECT newsum(four) AS sum_1500 FROM onek;
--Testcase 36:
SELECT newcnt(four) AS cnt_1000 FROM onek;
--Testcase 37:
SELECT newcnt(*) AS cnt_1000 FROM onek;
--Testcase 38:
SELECT oldcnt(*) AS cnt_1000 FROM onek;
--Testcase 39:
SELECT sum2(q1,q2) FROM int8_tbl;

-- test for outer-level aggregates

-- this should work
--Testcase 40:
select ten, sum(distinct four) from onek a
group by ten
having exists (select 1 from onek b where sum(distinct a.four) = b.four);

-- this should fail because subquery has an agg of its own in WHERE
--Testcase 41:
select ten, sum(distinct four) from onek a
group by ten
having exists (select 1 from onek b
               where sum(distinct a.four + b.four) = b.four);

-- Test handling of sublinks within outer-level aggregates.
-- Per bug report from Daniel Grace.
--Testcase 42:
select
  (select max((select i.unique2 from tenk1 i where i.unique1 = o.unique1)))
from tenk1 o;

--
-- test for bitwise integer aggregates
--
CREATE FOREIGN TABLE bitwise_test(
  i2 INT2,
  i4 INT4,
  i8 INT8,
  i INTEGER,
  x INT2
) SERVER sqlite_svr;

-- empty case
--Testcase 43:
SELECT
  BIT_AND(i2) AS "?",
  BIT_OR(i4)  AS "?"
FROM bitwise_test;

--Testcase 44:
INSERT INTO bitwise_test VALUES
  (1, 1, 1, 1, 1),
  (3, 3, 3, null, 2),
  (7, 7, 7, 3, 4);

--Testcase 45:
SELECT
  BIT_AND(i2) AS "1",
  BIT_AND(i4) AS "1",
  BIT_AND(i8) AS "1",
  BIT_AND(i)  AS "?",
  BIT_AND(x)  AS "0",

  BIT_OR(i2)  AS "7",
  BIT_OR(i4)  AS "7",
  BIT_OR(i8)  AS "7",
  BIT_OR(i)   AS "?",
  BIT_OR(x)   AS "7"
FROM bitwise_test;

CREATE FOREIGN TABLE bool_test(
  b1 BOOL,
  b2 BOOL,
  b3 BOOL,
  b4 BOOL
) SERVER sqlite_svr;

-- empty case
--Testcase 46:
SELECT
  BOOL_AND(b1)   AS "n",
  BOOL_OR(b3)    AS "n"
FROM bool_test;

--Testcase 47:
INSERT INTO bool_test VALUES
  (TRUE, null, FALSE, null),
  (FALSE, TRUE, null, null),
  (null, TRUE, FALSE, null);

--Testcase 48:
SELECT
  BOOL_AND(b1)     AS "f",
  BOOL_AND(b2)     AS "t",
  BOOL_AND(b3)     AS "f",
  BOOL_AND(b4)     AS "n",
  BOOL_AND(NOT b2) AS "f",
  BOOL_AND(NOT b3) AS "t"
FROM bool_test;

--Testcase 49:
SELECT
  EVERY(b1)     AS "f",
  EVERY(b2)     AS "t",
  EVERY(b3)     AS "f",
  EVERY(b4)     AS "n",
  EVERY(NOT b2) AS "f",
  EVERY(NOT b3) AS "t"
FROM bool_test;

--Testcase 50:
SELECT
  BOOL_OR(b1)      AS "t",
  BOOL_OR(b2)      AS "t",
  BOOL_OR(b3)      AS "f",
  BOOL_OR(b4)      AS "n",
  BOOL_OR(NOT b2)  AS "f",
  BOOL_OR(NOT b3)  AS "t"
FROM bool_test;

--
-- Test cases that should be optimized into indexscans instead of
-- the generic aggregate implementation.
--

-- Basic cases
--Testcase 51:
explain (costs off)
  select min(unique1) from tenk1;
--Testcase 52:
select min(unique1) from tenk1;
--Testcase 53:
explain (costs off)
  select max(unique1) from tenk1;
--Testcase 54:
select max(unique1) from tenk1;
--Testcase 55:
explain (costs off)
  select max(unique1) from tenk1 where unique1 < 42;
--Testcase 56:
select max(unique1) from tenk1 where unique1 < 42;
--Testcase 57:
explain (costs off)
  select max(unique1) from tenk1 where unique1 > 42;
--Testcase 58:
select max(unique1) from tenk1 where unique1 > 42;

-- the planner may choose a generic aggregate here if parallel query is
-- enabled, since that plan will be parallel safe and the "optimized"
-- plan, which has almost identical cost, will not be.  we want to test
-- the optimized plan, so temporarily disable parallel query.
begin;
set local max_parallel_workers_per_gather = 0;
--Testcase 59:
explain (costs off)
  select max(unique1) from tenk1 where unique1 > 42000;
--Testcase 60:
select max(unique1) from tenk1 where unique1 > 42000;
rollback;

-- multi-column index (uses tenk1_thous_tenthous)
--Testcase 61:
explain (costs off)
  select max(tenthous) from tenk1 where thousand = 33;
--Testcase 62:
select max(tenthous) from tenk1 where thousand = 33;
--Testcase 63:
explain (costs off)
  select min(tenthous) from tenk1 where thousand = 33;
--Testcase 64:
select min(tenthous) from tenk1 where thousand = 33;

-- check parameter propagation into an indexscan subquery
--Testcase 65:
explain (costs off)
  select f1, (select min(unique1) from tenk1 where unique1 > f1) AS gt
    from int4_tbl;
--Testcase 66:
select f1, (select min(unique1) from tenk1 where unique1 > f1) AS gt
  from int4_tbl;

-- check some cases that were handled incorrectly in 8.3.0
--Testcase 67:
explain (costs off)
  select distinct max(unique2) from tenk1;
--Testcase 68:
select distinct max(unique2) from tenk1;
--Testcase 69:
explain (costs off)
  select max(unique2) from tenk1 order by 1;
--Testcase 70:
select max(unique2) from tenk1 order by 1;
--Testcase 71:
explain (costs off)
  select max(unique2) from tenk1 order by max(unique2);
--Testcase 72:
select max(unique2) from tenk1 order by max(unique2);
--Testcase 73:
explain (costs off)
  select max(unique2) from tenk1 order by max(unique2)+1;
--Testcase 74:
select max(unique2) from tenk1 order by max(unique2)+1;
--Testcase 75:
explain (costs off)
  select max(unique2), generate_series(1,3) as g from tenk1 order by g desc;
--Testcase 76:
select max(unique2), generate_series(1,3) as g from tenk1 order by g desc;

-- interesting corner case: constant gets optimized into a seqscan
--Testcase 77:
explain (costs off)
  select max(100) from tenk1;
--Testcase 78:
select max(100) from tenk1;

-- try it on an inheritance tree
create foreign table minmaxtest(f1 int) server sqlite_svr;;
create table minmaxtest1() inherits (minmaxtest);
create table minmaxtest2() inherits (minmaxtest);
create table minmaxtest3() inherits (minmaxtest);
create index minmaxtest1i on minmaxtest1(f1);
create index minmaxtest2i on minmaxtest2(f1 desc);
create index minmaxtest3i on minmaxtest3(f1) where f1 is not null;

--Testcase 79:
insert into minmaxtest values(11), (12);
--Testcase 80:
insert into minmaxtest1 values(13), (14);
--Testcase 81:
insert into minmaxtest2 values(15), (16);
--Testcase 82:
insert into minmaxtest3 values(17), (18);

--Testcase 83:
explain (costs off)
  select min(f1), max(f1) from minmaxtest;
--Testcase 84:
select min(f1), max(f1) from minmaxtest;

-- DISTINCT doesn't do anything useful here, but it shouldn't fail
--Testcase 85:
explain (costs off)
  select distinct min(f1), max(f1) from minmaxtest;
--Testcase 86:
select distinct min(f1), max(f1) from minmaxtest;

-- check for correct detection of nested-aggregate errors
--Testcase 87:
select max(min(unique1)) from tenk1;
--Testcase 88:
select (select max(min(unique1)) from int8_tbl) from tenk1;

--
-- Test removal of redundant GROUP BY columns
--

create foreign table agg_t1 (a int OPTIONS (key 'true'), b int OPTIONS (key 'true'), c int, d int) server sqlite_svr;
create foreign table agg_t2 (x int OPTIONS (key 'true'), y int OPTIONS (key 'true'), z int) server sqlite_svr;

-- Non-primary-key columns can be removed from GROUP BY
--Testcase 89:
explain (costs off) select * from agg_t1 group by a,b,c,d;

-- No removal can happen if the complete PK is not present in GROUP BY
--Testcase 90:
explain (costs off) select a,c from agg_t1 group by a,c,d;

-- Test removal across multiple relations
--Testcase 91:
explain (costs off) select *
from agg_t1 inner join agg_t2 on agg_t1.a = agg_t2.x and agg_t1.b = agg_t2.y
group by agg_t1.a,agg_t1.b,agg_t1.c,agg_t1.d,agg_t2.x,agg_t2.y,agg_t2.z;

-- Test case where agg_t1 can be optimized but not agg_t2
--Testcase 92:
explain (costs off) select agg_t1.*,agg_t2.x,agg_t2.z
from agg_t1 inner join agg_t2 on agg_t1.a = agg_t2.x and agg_t1.b = agg_t2.y
group by agg_t1.a,agg_t1.b,agg_t1.c,agg_t1.d,agg_t2.x,agg_t2.z;

--
-- Test combinations of DISTINCT and/or ORDER BY
--
begin;
--Testcase 93:
delete from INT8_TBL;
--Testcase 94:
insert into INT8_TBL values (1,4),(2,3),(3,1),(4,2);
--Testcase 95:
select array_agg(q1 order by q2)
  from INT8_TBL;
--Testcase 96:
select array_agg(q1 order by q1)
  from INT8_TBL;
--Testcase 97:
select array_agg(q1 order by q1 desc)
  from INT8_TBL;
--Testcase 98:
select array_agg(q2 order by q1 desc)
  from INT8_TBL;

--Testcase 99:
delete from INT4_TBL;
--Testcase 100:
insert into INT4_TBL values (1),(2),(1),(3),(null),(2);
--Testcase 101:
select array_agg(distinct f1)
  from INT4_TBL;
--Testcase 102:
select array_agg(distinct f1 order by f1)
  from INT4_TBL;
--Testcase 103:
select array_agg(distinct f1 order by f1 desc)
  from INT4_TBL;
--Testcase 104:
select array_agg(distinct f1 order by f1 desc nulls last)
  from INT4_TBL;
rollback;

-- multi-arg aggs, strict/nonstrict, distinct/order by
create type aggtype as (a integer, b integer, c text);

create function aggf_trans(aggtype[],integer,integer,text) returns aggtype[]
as 'select array_append($1,ROW($2,$3,$4)::aggtype)'
language sql strict immutable;

create function aggfns_trans(aggtype[],integer,integer,text) returns aggtype[]
as 'select array_append($1,ROW($2,$3,$4)::aggtype)'
language sql immutable;

create aggregate aggfstr(integer,integer,text) (
   sfunc = aggf_trans, stype = aggtype[],
   initcond = '{}'
);

create aggregate aggfns(integer,integer,text) (
   sfunc = aggfns_trans, stype = aggtype[], sspace = 10000,
   initcond = '{}'
);

begin;
--Testcase 105:
insert into multi_arg_agg values (1,3,'foo'),(0,null,null),(2,2,'bar'),(3,1,'baz');
--Testcase 106:
select aggfstr(a,b,c) from multi_arg_agg;
--Testcase 107:
select aggfns(a,b,c) from multi_arg_agg;

--Testcase 108:
select aggfstr(distinct a,b,c) from multi_arg_agg, generate_series(1,3) i;
--Testcase 109:
select aggfns(distinct a,b,c) from multi_arg_agg, generate_series(1,3) i;

--Testcase 110:
select aggfstr(distinct a,b,c order by b) from multi_arg_agg, generate_series(1,3) i;
--Testcase 111:
select aggfns(distinct a,b,c order by b) from multi_arg_agg, generate_series(1,3) i;

-- test specific code paths

--Testcase 112:
select aggfns(distinct a,a,c order by c using ~<~,a) from multi_arg_agg, generate_series(1,2) i;
--Testcase 113:
select aggfns(distinct a,a,c order by c using ~<~) from multi_arg_agg, generate_series(1,2) i;
--Testcase 114:
select aggfns(distinct a,a,c order by a) from multi_arg_agg, generate_series(1,2) i;
--Testcase 115:
select aggfns(distinct a,b,c order by a,c using ~<~,b) from multi_arg_agg, generate_series(1,2) i;

-- check node I/O via view creation and usage, also deparsing logic

create view agg_view1 as
  select aggfns(a,b,c) from multi_arg_agg;

--Testcase 116:
select * from agg_view1;
--Testcase 117:
select pg_get_viewdef('agg_view1'::regclass);

create or replace view agg_view1 as
  select aggfns(distinct a,b,c) from multi_arg_agg, generate_series(1,3) i;

--Testcase 118:
select * from agg_view1;
--Testcase 119:
select pg_get_viewdef('agg_view1'::regclass);

create or replace view agg_view1 as
  select aggfns(distinct a,b,c order by b) from multi_arg_agg, generate_series(1,3) i;

--Testcase 120:
select * from agg_view1;
--Testcase 121:
select pg_get_viewdef('agg_view1'::regclass);

create or replace view agg_view1 as
  select aggfns(a,b,c order by b+1) from multi_arg_agg;

--Testcase 122:
select * from agg_view1;
--Testcase 123:
select pg_get_viewdef('agg_view1'::regclass);

create or replace view agg_view1 as
  select aggfns(a,a,c order by b) from multi_arg_agg;

--Testcase 124:
select * from agg_view1;
--Testcase 125:
select pg_get_viewdef('agg_view1'::regclass);

create or replace view agg_view1 as
  select aggfns(a,b,c order by c using ~<~) from multi_arg_agg;

--Testcase 126:
select * from agg_view1;
--Testcase 127:
select pg_get_viewdef('agg_view1'::regclass);

create or replace view agg_view1 as
  select aggfns(distinct a,b,c order by a,c using ~<~,b) from multi_arg_agg, generate_series(1,2) i;

--Testcase 128:
select * from agg_view1;
--Testcase 129:
select pg_get_viewdef('agg_view1'::regclass);

drop view agg_view1;
rollback;

-- incorrect DISTINCT usage errors
--Testcase 130:
insert into multi_arg_agg values (1,1,'foo');
--Testcase 131:
select aggfns(distinct a,b,c order by i) from multi_arg_agg, generate_series(1,2) i;
--Testcase 132:
select aggfns(distinct a,b,c order by a,b+1) from multi_arg_agg, generate_series(1,2) i;
--Testcase 133:
select aggfns(distinct a,b,c order by a,b,i,c) from multi_arg_agg, generate_series(1,2) i;
--Testcase 134:
select aggfns(distinct a,a,c order by a,b) from multi_arg_agg, generate_series(1,2) i;

-- string_agg tests
begin;
--Testcase 135:
delete from varchar_tbl;
--Testcase 136:
insert into varchar_tbl values ('aaaa'),('bbbb'),('cccc');
--Testcase 137:
select string_agg(f1,',') from varchar_tbl;

--Testcase 138:
delete from varchar_tbl;
--Testcase 139:
insert into varchar_tbl values ('aaaa'),(null),('bbbb'),('cccc');
--Testcase 140:
select string_agg(f1,',') from varchar_tbl;

--Testcase 141:
delete from varchar_tbl;
--Testcase 142:
insert into varchar_tbl values (null),(null),('bbbb'),('cccc');
--Testcase 143:
select string_agg(f1,'AB') from varchar_tbl;

--Testcase 144:
delete from varchar_tbl;
--Testcase 145:
insert into varchar_tbl values (null),(null);
--Testcase 146:
select string_agg(f1,',') from varchar_tbl;
rollback;

-- check some implicit casting cases, as per bug #5564

--Testcase 147:
select string_agg(distinct f1, ',' order by f1) from varchar_tbl;  -- ok
--Testcase 148:
select string_agg(distinct f1::text, ',' order by f1) from varchar_tbl;  -- not ok
--Testcase 149:
select string_agg(distinct f1, ',' order by f1::text) from varchar_tbl;  -- not ok
--Testcase 150:
select string_agg(distinct f1::text, ',' order by f1::text) from varchar_tbl;  -- ok

-- string_agg bytea tests
create foreign table bytea_test_table(v bytea) server sqlite_svr;

--Testcase 151:
select string_agg(v, '') from bytea_test_table;

--Testcase 152:
insert into bytea_test_table values(decode('ff','hex'));

--Testcase 153:
select string_agg(v, '') from bytea_test_table;

--Testcase 154:
insert into bytea_test_table values(decode('aa','hex'));

--Testcase 155:
select string_agg(v, '') from bytea_test_table;
--Testcase 156:
select string_agg(v, NULL) from bytea_test_table;
--Testcase 157:
select string_agg(v, decode('ee', 'hex')) from bytea_test_table;

drop foreign table bytea_test_table;

-- FILTER tests

--Testcase 158:
select min(unique1) filter (where unique1 > 100) from tenk1;

--Testcase 159:
select sum(1/ten) filter (where ten > 0) from tenk1;

--Testcase 160:
select ten, sum(distinct four) filter (where four::text ~ '123') from onek a
group by ten;

--Testcase 161:
select ten, sum(distinct four) filter (where four > 10) from onek a
group by ten
having exists (select 1 from onek b where sum(distinct a.four) = b.four);

--Testcase 162:
select
  (select max((select i.unique2 from tenk1 i where i.unique1 = o.unique1))
     filter (where o.unique1 < 10))
from tenk1 o;					-- outer query is aggregation query

-- subquery in FILTER clause (PostgreSQL extension)
--Testcase 163:
select sum(unique1) FILTER (WHERE
  unique1 IN (SELECT unique1 FROM onek where unique1 < 100)) FROM tenk1;

-- exercise lots of aggregate parts with FILTER
begin;
--Testcase 164:
delete from multi_arg_agg;
--Testcase 165:
insert into multi_arg_agg values (1,3,'foo'),(0,null,null),(2,2,'bar'),(3,1,'baz');
--Testcase 166:
select aggfns(distinct a,b,c order by a,c using ~<~,b) filter (where a > 1) from multi_arg_agg, generate_series(1,2) i;
rollback;

-- ordered-set aggregates

begin;
--Testcase 167:
delete from FLOAT8_TBL;
--Testcase 168:
insert into FLOAT8_TBL values (0::float8),(0.1),(0.25),(0.4),(0.5),(0.6),(0.75),(0.9),(1);
--Testcase 169:
select f1, percentile_cont(f1) within group (order by x::float8)
from generate_series(1,5) x,
     FLOAT8_TBL
group by f1 order by f1;
rollback;

begin;
--Testcase 170:
delete from FLOAT8_TBL;
--Testcase 171:
insert into FLOAT8_TBL values (0::float8),(0.1),(0.25),(0.4),(0.5),(0.6),(0.75),(0.9),(1);
--Testcase 172:
select f1, percentile_cont(f1 order by f1) within group (order by x)  -- error
from generate_series(1,5) x,
     FLOAT8_TBL
group by f1 order by f1;
rollback;

begin;
--Testcase 173:
delete from FLOAT8_TBL;
--Testcase 174:
insert into FLOAT8_TBL values (0::float8),(0.1),(0.25),(0.4),(0.5),(0.6),(0.75),(0.9),(1);
--Testcase 175:
select f1, sum() within group (order by x::float8)  -- error
from generate_series(1,5) x,
     FLOAT8_TBL
group by f1 order by f1;
rollback;

begin;
--Testcase 176:
delete from FLOAT8_TBL;
--Testcase 177:
insert into FLOAT8_TBL values (0::float8),(0.1),(0.25),(0.4),(0.5),(0.6),(0.75),(0.9),(1);
--Testcase 178:
select f1, percentile_cont(f1,f1)  -- error
from generate_series(1,5) x,
     FLOAT8_TBL
group by f1 order by f1;
rollback;

--Testcase 179:
select percentile_cont(0.5) within group (order by b) from aggtest;
--Testcase 180:
select percentile_cont(0.5) within group (order by b), sum(b) from aggtest;
--Testcase 181:
select percentile_cont(0.5) within group (order by thousand) from tenk1;
--Testcase 182:
select percentile_disc(0.5) within group (order by thousand) from tenk1;

begin;
--Testcase 183:
delete from INT4_TBL;
--Testcase 184:
insert into INT4_TBL values (1),(1),(2),(2),(3),(3),(4);
--Testcase 185:
select rank(3) within group (order by f1) from INT4_TBL;
--Testcase 186:
select cume_dist(3) within group (order by f1) from INT4_TBL;
--Testcase 187:
select percent_rank(3) within group (order by f1) from INT4_TBL;
--Testcase 188:
select dense_rank(3) within group (order by f1) from INT4_TBL;
rollback;

--Testcase 189:
select percentile_disc(array[0,0.1,0.25,0.5,0.75,0.9,1]) within group (order by thousand)
from tenk1;
--Testcase 190:
select percentile_cont(array[0,0.25,0.5,0.75,1]) within group (order by thousand)
from tenk1;
--Testcase 191:
select percentile_disc(array[[null,1,0.5],[0.75,0.25,null]]) within group (order by thousand)
from tenk1;

--Testcase 192:
select ten, mode() within group (order by string4) from tenk1 group by ten;

-- ordered-set aggs created with CREATE AGGREGATE
create aggregate my_percentile_disc(float8 ORDER BY anyelement) (
  stype = internal,
  sfunc = ordered_set_transition,
  finalfunc = percentile_disc_final,
  finalfunc_extra = true,
  finalfunc_modify = read_write
);
alter aggregate my_percentile_disc(float8 ORDER BY anyelement)
  rename to test_percentile_disc;
--Testcase 193:
select test_percentile_disc(0.5) within group (order by thousand) from tenk1;

-- hypothetical-set type unification and argument-count failures:
--Testcase 194:
select rank(3) within group (order by stringu1,stringu2) from tenk1;

-- deparse and multiple features:
create view aggordview1 as
--Testcase 195:
select ten,
       percentile_disc(0.5) within group (order by thousand) as p50,
       percentile_disc(0.5) within group (order by thousand) filter (where hundred=1) as px,
       rank(5,'AZZZZ',50) within group (order by hundred, string4 desc, hundred)
  from tenk1
 group by ten order by ten;

--Testcase 196:
select pg_get_viewdef('aggordview1');
--Testcase 197:
select * from aggordview1 order by ten;
drop view aggordview1;

-- variadic aggregates
create function least_accum(anyelement, variadic anyarray)
returns anyelement language sql as
  'select least($1, min($2[i])) from generate_subscripts($2,1) g(i)';

create aggregate least_agg(variadic items anyarray) (
  stype = anyelement, sfunc = least_accum
);
--Testcase 198:
select least_agg(q1,q2) from int8_tbl;
--Testcase 199:
select least_agg(variadic array[q1,q2]) from int8_tbl;

-- test that the aggregate transition logic correctly handles
-- transition / combine functions returning NULL

-- First test the case of a normal transition function returning NULL
BEGIN;
CREATE FUNCTION balkifnull(int8, int4)
RETURNS int8
STRICT
LANGUAGE plpgsql AS $$
BEGIN
    IF $1 IS NULL THEN
       RAISE 'erroneously called with NULL argument';
    END IF;
    RETURN NULL;
END$$;

CREATE AGGREGATE balk(int4)
(
    SFUNC = balkifnull(int8, int4),
    STYPE = int8,
    PARALLEL = SAFE,
    INITCOND = '0'
);

--Testcase 200:
SELECT balk(hundred) FROM tenk1;

ROLLBACK;

DO $d$
declare
  l_rec record;
begin
  for l_rec in (select foreign_table_schema, foreign_table_name 
                from information_schema.foreign_tables) loop
     execute format('drop foreign table %I.%I cascade;', l_rec.foreign_table_schema, l_rec.foreign_table_name);
  end loop;
end;
$d$;
DROP SERVER sqlite_svr;
DROP EXTENSION sqlite_fdw CASCADE;
