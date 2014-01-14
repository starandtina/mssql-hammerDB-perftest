-- clustered indexes
DROP INDEX cs_item_order_number_idx ON catalog_sales;
-- HAMMERORA GO
DROP INDEX cr_item_order_number_idx ON catalog_returns;
-- HAMMERORA GO
DROP INDEX inv_date_item_warehouse_cluidx ON inventory;
-- HAMMERORA GO
DROP INDEX ss_item_ticket_number_idx ON store_sales;
-- HAMMERORA GO
DROP INDEX sr_item_ticket_number_idx ON store_returns;
-- HAMMERORA GO
DROP INDEX ws_item_order_number_idx ON web_sales;
-- HAMMERORA GO
DROP INDEX wr_item_order_number_idx ON web_returns;
-- HAMMERORA GO
-- additional clustered indexes for performance
DROP INDEX cs_sold_date_sk_cluidx ON catalog_sales;
-- HAMMERORA GO
DROP INDEX cr_returned_date_cluidx ON catalog_returns;
-- HAMMERORA GO
DROP INDEX ss_sold_date_sk_cluidx ON store_sales;
-- HAMMERORA GO
DROP INDEX sr_returned_date_cluidx ON store_returns;
-- HAMMERORA GO
DROP INDEX ws_sold_date_sk_cluidx ON web_sales;
-- HAMMERORA GO
DROP INDEX wr_returnd_date_cluidx ON web_returns;
-- HAMMERORA GO

-- primary keys
alter table store drop constraint pk_s_store_sk;
-- HAMMERORA GO
alter table dbo.call_center drop constraint pk_cc_call_center_sk;
-- HAMMERORA GO
alter table dbo.catalog_page drop constraint pk_cp_catalog_page_sk;
-- HAMMERORA GO
alter table dbo.web_site drop constraint pk_web_site_sk;
-- HAMMERORA GO
alter table dbo.web_page drop constraint pk_wp_web_page_sk;
-- HAMMERORA GO
alter table dbo.warehouse drop constraint pk_w_warehouse_sk;
-- HAMMERORA GO
alter table dbo.customer drop constraint pk_c_customer_sk;
-- HAMMERORA GO
alter table dbo.customer_address drop constraint pk_ca_address_sk;
-- HAMMERORA GO
alter table dbo.customer_demographics drop constraint pk_cd_demo_sk ;
-- HAMMERORA GO
alter table dbo.date_dim drop constraint pk_d_date_sk;
-- HAMMERORA GO
alter table dbo.household_demographics drop constraint pk_hd_demo_sk;
-- HAMMERORA GO
alter table dbo.item drop constraint pk_i_item_sk;
-- HAMMERORA GO
alter table dbo.income_band drop constraint pk_ib_income_band_sk;
-- HAMMERORA GO
alter table dbo.promotion drop constraint pk_p_promo_sk;
-- HAMMERORA GO
alter table dbo.reason drop constraint pk_r_reason_sk;
-- HAMMERORA GO
alter table dbo.ship_mode drop constraint pk_sm_ship_mode_sk;
-- HAMMERORA GO
alter table dbo.time_dim drop constraint pk_t_time_sk;
-- HAMMERORA GO
