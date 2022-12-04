#建测试表
drop table if exists t;
CREATE TABLE t (
                id int NOT NULL AUTO_INCREMENT PRIMARY KEY comment '自增主键',
                dept tinyint not null comment '部门id',
                age tinyint not null comment '年龄',
                name varchar(30) comment '用户名称',
                create_time datetime not null comment '注册时间',
                last_login_time datetime comment '最后登录时间'
               ) comment '测试表';

#手工插入第一条测试数据，后面数据会根据这条数据作为基础生成
insert into t values(1,1, 25, 'user_1', '2018-01-01 00:00:00', '2018-03-01 12:00:00');
#初始化序列变量
set @i=1;


#==================此处拷贝反复执行，直接符合预想的数据量===================
#执行20次即2的20次方=1048576 条记录
#执行23次即2的23次方=8388608 条记录
#执行24次即2的24次方=16777216 条记录
#......
insert into t(dept, age, name, create_time, last_login_time)
select left(rand()*10,1) as dept,               #随机生成1~10的整数
       FLOOR(20+RAND() *(50 - 20 + 1)) as age,  #随机生成20~50的整数
        concat('user_',@i:=@i+1),               #按序列生成不同的name
        date_add(create_time,interval +@i*cast(rand()*100 as signed) SECOND), #生成有时间大顺序随机注册时间
        date_add(date_add(create_time,interval +@i*cast(rand()*100 as signed) SECOND), interval + cast(rand()*1000000 as signed) SECOND) #生成有时间大顺序的随机的最后登录时间
from t;
select count(1) from t;
#==================此处结束反复执行=====================


#创建索引(视情况执行)
create index idx_dept on t(dept);
create index idx_create_time on t(create_time);
create index idx_last_login_time on t(last_login_time);































/*
按照今天的测试 没有优化的思路了  必须做sql cache的能力
    大表 基本上  2000w 少列情况 已经 特别慢了  14s
    内存表 占的内存太大  只适合单表 优化
    buffer pool 加大 也拦不住 全表扫描


*/



select count(*) from t where t.name  like '%t%'; -- 52s

select count(*) from t_500w tw where tw.name  like '%t%' -- 2s

select count(*) from t_2000w tw where tw.name  like '%t%' -- 14s

explain select count(*) from t where t.name  like '%t%';

select * from t limit 15000000,10 -- 默认配置  12s

CREATE TABLE t_memory AS (SELECT * FROM t where 0=1);
delete  FROM  t_memory
INSERT INTO t_memory  SELECT * FROM t

INSERT INTO t_500w  SELECT * FROM t limit 0,5000000

INSERT INTO t_2000w  SELECT * FROM t limit 0,20000000

select count(*) from t_500w tw
select count(1) from t_memory tm


select
table_schema as '数据库',
table_name as '表名',
table_rows as '记录数',
truncate(data_length/1024/1024, 2) as '数据容量(MB)',
truncate(index_length/1024/1024, 2) as '索引容量(MB)'
from information_schema.tables
where table_schema='sqlcache'
order by data_length desc, index_length desc;


select *
from information_schema.TABLES ta
where 1=1
and ta.table_schema not in (
'information_schema',
'mysql',
'sys',
'performance_schema'
)
order by ta.table_schema,ta.table_name


SHOW VARIABLES LIKE '%innodb_buffer%'


-- 系统默认内存引擎是是16M
--  tmp_table_size = 256M

-- max_heap_table_size = 256M


select @@max_heap_table_size;

-- 查看不同存储引擎占用内存情况
SELECT SUBSTRING_INDEX(event_name,'/',2) AS
code_area, sys.format_bytes(SUM(current_alloc))
AS current_alloc
FROM sys.x$memory_global_by_current_bytes
GROUP BY SUBSTRING_INDEX(event_name,'/',2)
ORDER BY SUM(current_alloc) DESC;


 show global variables like "innodb_buffer_pool%"

 SET GLOBAL innodb_buffer_pool_size=402653184;






