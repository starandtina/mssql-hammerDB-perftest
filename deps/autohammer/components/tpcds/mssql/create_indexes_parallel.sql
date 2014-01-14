-- clustered indexes
CREATE INDEX cs_item_order_number_idx 
ON catalog_sales ( cs_item_sk, cs_order_number)
WITH (FILLFACTOR = 95, SORT_IN_TEMPDB=ON, MAXDOP=$setdop);
-- HAMMERORA GO
CREATE INDEX cr_item_order_number_idx 
ON catalog_returns ( cr_item_sk, cr_order_number)
WITH (FILLFACTOR = 95, SORT_IN_TEMPDB=ON, MAXDOP=$setdop);
-- HAMMERORA GO
CREATE CLUSTERED INDEX inv_date_item_warehouse_cluidx 
ON inventory ( inv_date_sk, inv_item_sk, inv_warehouse_sk )
WITH (FILLFACTOR = 95, SORT_IN_TEMPDB=ON, MAXDOP=$setdop);
-- HAMMERORA GO
CREATE INDEX ss_item_ticket_number_idx 
ON store_sales (ss_item_sk, ss_ticket_number)
WITH (FILLFACTOR = 95, SORT_IN_TEMPDB=ON, MAXDOP=$setdop);
-- HAMMERORA GO
CREATE INDEX sr_item_ticket_number_idx 
ON store_returns (sr_item_sk, sr_ticket_number)
WITH (FILLFACTOR = 95, SORT_IN_TEMPDB=ON, MAXDOP=$setdop);
-- HAMMERORA GO
CREATE INDEX ws_item_order_number_idx 
ON web_sales ( ws_item_sk, ws_order_number)
WITH (FILLFACTOR = 95, SORT_IN_TEMPDB=ON, MAXDOP=$setdop);
-- HAMMERORA GO
CREATE INDEX wr_item_order_number_idx 
ON web_returns ( wr_item_sk, wr_order_number)
WITH (FILLFACTOR = 95, SORT_IN_TEMPDB=ON, MAXDOP=$setdop);
-- HAMMERORA GO
-- additional clustered indexes for performance
CREATE CLUSTERED INDEX cs_sold_date_sk_cluidx 
ON catalog_sales(cs_sold_date_sk) 
WITH (FILLFACTOR = 95, SORT_IN_TEMPDB=ON, MAXDOP=$setdop);
-- HAMMERORA GO
CREATE CLUSTERED INDEX cr_returned_date_cluidx
ON catalog_returns(cr_returned_date_sk) 
WITH (FILLFACTOR = 95, SORT_IN_TEMPDB=ON, MAXDOP=$setdop);
-- HAMMERORA GO
CREATE CLUSTERED INDEX ss_sold_date_sk_cluidx 
ON store_sales(ss_sold_date_sk) 
WITH (FILLFACTOR = 95, SORT_IN_TEMPDB=ON, MAXDOP=$setdop);
-- HAMMERORA GO
CREATE CLUSTERED INDEX sr_returned_date_cluidx
ON store_returns(sr_returned_date_sk) 
WITH (FILLFACTOR = 95, SORT_IN_TEMPDB=ON, MAXDOP=$setdop);
-- HAMMERORA GO
CREATE CLUSTERED INDEX ws_sold_date_sk_cluidx 
ON web_sales(ws_sold_date_sk) 
WITH (FILLFACTOR = 95, SORT_IN_TEMPDB=ON, MAXDOP=$setdop);
-- HAMMERORA GO
CREATE CLUSTERED INDEX wr_returnd_date_cluidx
ON web_returns(wr_returned_date_sk) 
WITH (FILLFACTOR = 95, SORT_IN_TEMPDB=ON, MAXDOP=$setdop);
-- HAMMERORA GO

-- primary keys
alter table dbo.store add constraint pk_s_store_sk
primary key ( s_store_sk )
WITH (FILLFACTOR = 95, SORT_IN_TEMPDB = ON, MAXDOP=$setdop);
-- HAMMERORA GO
alter table dbo.call_center add constraint pk_cc_call_center_sk
primary key ( cc_call_center_sk )
WITH (FILLFACTOR = 95, SORT_IN_TEMPDB = ON, MAXDOP=$setdop);
-- HAMMERORA GO
alter table dbo.catalog_page add constraint pk_cp_catalog_page_sk
primary key ( cp_catalog_page_sk )
WITH (FILLFACTOR = 95, SORT_IN_TEMPDB = ON, MAXDOP=$setdop);
-- HAMMERORA GO
alter table dbo.web_site add constraint pk_web_site_sk
primary key ( web_site_sk )
WITH (FILLFACTOR = 95, SORT_IN_TEMPDB = ON, MAXDOP=$setdop);
-- HAMMERORA GO
alter table dbo.web_page add constraint pk_wp_web_page_sk
primary key ( wp_web_page_sk )
WITH (FILLFACTOR = 95, SORT_IN_TEMPDB = ON, MAXDOP=$setdop);
-- HAMMERORA GO
alter table dbo.warehouse add constraint pk_w_warehouse_sk
primary key ( w_warehouse_sk )
WITH (FILLFACTOR = 95, SORT_IN_TEMPDB = ON, MAXDOP=$setdop);
-- HAMMERORA GO
alter table dbo.customer add constraint pk_c_customer_sk
primary key ( c_customer_sk )
WITH (FILLFACTOR = 95, SORT_IN_TEMPDB = ON, MAXDOP=$setdop);
-- HAMMERORA GO
alter table dbo.customer_address add constraint pk_ca_address_sk
primary key ( ca_address_sk )
WITH (FILLFACTOR = 95, SORT_IN_TEMPDB = ON, MAXDOP=$setdop);
-- HAMMERORA GO
alter table dbo.customer_demographics add constraint pk_cd_demo_sk 
primary key ( cd_demo_sk )
WITH (FILLFACTOR = 95, SORT_IN_TEMPDB = ON, MAXDOP=$setdop);
-- HAMMERORA GO
alter table dbo.date_dim add constraint pk_d_date_sk
primary key ( d_date_sk )
WITH (FILLFACTOR = 95, SORT_IN_TEMPDB = ON, MAXDOP=$setdop);
-- HAMMERORA GO
alter table dbo.household_demographics add constraint pk_hd_demo_sk
primary key ( hd_demo_sk )
WITH (FILLFACTOR = 95, SORT_IN_TEMPDB = ON, MAXDOP=$setdop);
-- HAMMERORA GO
alter table dbo.item add constraint pk_i_item_sk
primary key ( i_item_sk )
WITH (FILLFACTOR = 95, SORT_IN_TEMPDB = ON, MAXDOP=$setdop);
-- HAMMERORA GO
alter table dbo.income_band add constraint pk_ib_income_band_sk
primary key ( ib_income_band_sk )
WITH (FILLFACTOR = 95, SORT_IN_TEMPDB = ON, MAXDOP=$setdop);
-- HAMMERORA GO
alter table dbo.promotion add constraint pk_p_promo_sk
primary key ( p_promo_sk )
WITH (FILLFACTOR = 95, SORT_IN_TEMPDB = ON, MAXDOP=$setdop);
-- HAMMERORA GO
alter table dbo.reason add constraint pk_r_reason_sk
primary key ( r_reason_sk )
WITH (FILLFACTOR = 95, SORT_IN_TEMPDB = ON, MAXDOP=$setdop);
-- HAMMERORA GO
alter table dbo.ship_mode add constraint pk_sm_ship_mode_sk
primary key ( sm_ship_mode_sk )
WITH (FILLFACTOR = 95, SORT_IN_TEMPDB = ON, MAXDOP=$setdop);
-- HAMMERORA GO
alter table dbo.time_dim add constraint pk_t_time_sk
primary key ( t_time_sk )
WITH (FILLFACTOR = 95, SORT_IN_TEMPDB = ON, MAXDOP=$setdop);
-- HAMMERORA GO
