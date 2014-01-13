alter table dbo.nation 
      add constraint nation_pk primary key (n_nationkey);
-- HAMMERORA GO
alter table dbo.region 
      add constraint region_pk primary key (r_regionkey);
-- HAMMERORA GO
alter table dbo.customer 
      add constraint customer_pk primary key (c_custkey) 
      with (maxdop=$maxdop);
-- HAMMERORA GO
alter table dbo.part 
      add constraint part_pk primary key (p_partkey) 
      with (maxdop=$maxdop);
-- HAMMERORA GO
alter table dbo.partsupp 
      add constraint partsupp_pk primary key (ps_partkey, ps_suppkey) 
      with (maxdop=$maxdop);
-- HAMMERORA GO
alter table dbo.supplier 
      add constraint supplier_pk primary key (s_suppkey) 
      with (maxdop=$maxdop);
-- HAMMERORA GO
create clustered index o_orderdate_ind 
                 on orders(o_orderdate) 
		 with (fillfactor=95, sort_in_tempdb=on, maxdop=$maxdop);
-- HAMMERORA GO
alter table dbo.orders 
      add constraint orders_pk primary key (o_orderkey) 
      with (fillfactor = 95, maxdop=$maxdop);
-- HAMMERORA GO
create index n_regionkey_ind 
       on dbo.nation(n_regionkey) 
       with (fillfactor=100, sort_in_tempdb=on, maxdop=$maxdop);
-- HAMMERORA GO
create index ps_suppkey_ind 
       on dbo.partsupp(ps_suppkey) 
       with(fillfactor=100, sort_in_tempdb=on, maxdop=$maxdop);
-- HAMMERORA GO
create index s_nationkey_ind 
       on dbo.supplier(s_nationkey) 
       with (fillfactor=100, sort_in_tempdb=on, maxdop=$maxdop);
-- HAMMERORA GO
create clustered index l_shipdate_ind 
                 on dbo.lineitem(l_shipdate) 
		 with (fillfactor=95, sort_in_tempdb=off, maxdop=$maxdop);
-- HAMMERORA GO
create index l_orderkey_ind 
       on dbo.lineitem(l_orderkey) 
       with ( fillfactor=95, sort_in_tempdb=on, maxdop=$maxdop);
-- HAMMERORA GO
create index l_partkey_ind 
       on dbo.lineitem(l_partkey) 
       with (fillfactor=95, sort_in_tempdb=on, maxdop=$maxdop);
-- HAMMERORA GO
alter table dbo.customer 
      with nocheck 
      add  constraint customer_nation_fk foreign key(c_nationkey) references dbo.nation (n_nationkey);
-- HAMMERORA GO
alter table dbo.lineitem 
      with nocheck add  constraint lineitem_order_fk foreign key(l_orderkey) references dbo.orders (o_orderkey);
-- HAMMERORA GO
alter table dbo.lineitem 
      with nocheck 
      add constraint lineitem_partkey_fk foreign key (l_partkey) references dbo.part(p_partkey);
-- HAMMERORA GO
alter table dbo.lineitem 
      with nocheck 
      add constraint lineitem_suppkey_fk foreign key (l_suppkey) references dbo.supplier(s_suppkey);
-- HAMMERORA GO
alter table dbo.lineitem 
      with nocheck 
      add  constraint lineitem_partsupp_fk foreign key(l_partkey,l_suppkey) references partsupp(ps_partkey, ps_suppkey);
-- HAMMERORA GO
alter table dbo.nation  
      with nocheck 
      add  constraint nation_region_fk foreign key(n_regionkey) references dbo.region (r_regionkey);
-- HAMMERORA GO
alter table dbo.partsupp  
      with nocheck 
      add  constraint partsupp_part_fk foreign key(ps_partkey) references dbo.part (p_partkey);
-- HAMMERORA GO
alter table dbo.partsupp  
      with nocheck 
      add  constraint partsupp_supplier_fk foreign key(ps_suppkey) references dbo.supplier (s_suppkey);
-- HAMMERORA GO
alter table dbo.supplier  
      with nocheck 
      add  constraint supplier_nation_fk foreign key(s_nationkey) references dbo.nation (n_nationkey);
-- HAMMERORA GO
alter table dbo.orders  
      with nocheck 
      add  constraint order_customer_fk foreign key(o_custkey) references dbo.customer (c_custkey);
-- HAMMERORA GO
alter table dbo.customer 
      check constraint customer_nation_fk;
-- HAMMERORA GO
alter table dbo.lineitem 
      check constraint lineitem_order_fk;
-- HAMMERORA GO
alter table dbo.lineitem 
      check constraint lineitem_partkey_fk;
-- HAMMERORA GO
alter table dbo.lineitem 
      check constraint lineitem_suppkey_fk;
-- HAMMERORA GO
alter table dbo.lineitem 
      check constraint lineitem_partsupp_fk;
-- HAMMERORA GO
alter table dbo.nation 
      check constraint nation_region_fk;
-- HAMMERORA GO
alter table dbo.partsupp 
      check constraint partsupp_part_fk;
-- HAMMERORA GO
alter table dbo.partsupp 
      check constraint partsupp_part_fk;
-- HAMMERORA GO
alter table dbo.supplier 
      check constraint supplier_nation_fk;
-- HAMMERORA GO
alter table dbo.orders 
      check constraint order_customer_fk;
-- HAMMERORA GO
