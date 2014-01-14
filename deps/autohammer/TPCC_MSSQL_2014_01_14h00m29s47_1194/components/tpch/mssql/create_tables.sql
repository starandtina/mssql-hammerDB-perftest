create table dbo.customer ( 
                c_custkey int not null, 
                c_mktsegment char(10) null, 
			    c_nationkey int null, 
			    c_name varchar(25) null, 
			    c_address varchar(40) null, 
			    c_phone char(15) null, 
			    c_acctbal money null, 
			    c_comment varchar(118) null) ;

create table dbo.lineitem ( 
                l_shipdate date null, 
	            l_orderkey int not null, 
			    l_discount int not null, 
			    l_extendedprice money not null, 
			    l_suppkey int not null, 
			    l_quantity bigint not null, 
			    l_returnflag char(1) null, 
			    l_partkey int not null, 
			    l_linestatus char(1) null, 
			    l_tax int not null, 
			    l_commitdate date null, 
			    l_receiptdate date null, 
			    l_shipmode char(10) null, 
			    l_linenumber int not null, 
			    l_shipinstruct char(25) null, 
			    l_comment varchar(44) null);

create table dbo.nation( 
             n_nationkey int not null, 
	         n_name char(25) null, 
			 n_regionkey int null, 
			 n_comment varchar(152) null);

create table dbo.part( 
               p_partkey int not null, 
	           p_type varchar(25) null, 
		       p_size int null, 
		       p_brand char(10) null, 
		       p_name varchar(55) null, 
		       p_container char(10) null, 
		       p_mfgr char(25) null, 
		       p_retailprice money null, 
		       p_comment varchar(23) null)

create table dbo.partsupp( 
               ps_partkey int not null, 
	           ps_suppkey int not null, 
			   ps_supplycost money not null, 
			   ps_availqty int null, 
			   ps_comment varchar(199) null);

create table dbo.region( 
             r_regionkey int not null, 
	         r_name char(25) null, 
			 r_comment varchar(152) null);

create table dbo.supplier( 
               s_suppkey int not null, 
	           s_nationkey int null, 
			   s_comment varchar(102) null, 
			   s_name char(25) null, 
			   s_address varchar(40) null, 
			   s_phone char(15) null, 
			   s_acctbal money null);

create table dbo.orders( 
             o_orderdate date null, 
	         o_orderkey int not null, 
		     o_custkey int not null, 
			 o_orderpriority char(15) null, 
			 o_shippriority int null, 
			 o_clerk char(15) null, 
			 o_orderstatus char(1) null, 
			 o_totalprice money null, 
			 o_comment varchar(79) null);
