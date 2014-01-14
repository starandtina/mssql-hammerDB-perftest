-- store_sales
alter table store_sales  add constraint fk_ss_sold_date_sk
foreign key (ss_sold_date_sk) references date_dim(d_date_sk);
-- HAMMERORA GO
alter table store_sales  add constraint fk_ss_sold_time_sk
foreign key (ss_sold_time_sk) references time_dim(t_time_sk);
-- HAMMERORA GO
alter table store_sales  add constraint fk_ss_item_sk_1
foreign key (ss_item_sk) references item(i_item_sk);
-- HAMMERORA GO
-- alter table store_sales  add constraint fk_ss_item_sk_2
-- foreign key (ss_item_sk) references store_returns(sr_item_sk);
-- -- HAMMERORA GO
alter table store_sales  add constraint fk_ss_customer_sk
foreign key (ss_customer_sk) references customer(c_customer_sk);
-- HAMMERORA GO
alter table store_sales  add constraint fk_ss_demo_sk_1
foreign key (ss_cdemo_sk) references customer_demographics(cd_demo_sk);
-- HAMMERORA GO
alter table store_sales  add constraint fk_ss_demo_sk_2
foreign key (ss_hdemo_sk) references household_demographics(hd_demo_sk);
-- HAMMERORA GO
alter table store_sales  add constraint fk_ss_addr_sk
foreign key (ss_addr_sk) references customer_address(ca_address_sk);
-- HAMMERORA GO
alter table store_sales  add constraint fk_ss_store_sk
foreign key (ss_store_sk) references store(s_store_sk);
-- HAMMERORA GO
alter table store_sales  add constraint fk_ss_promo_sk
foreign key (ss_promo_sk) references promotion(p_promo_sk);
-- HAMMERORA GO
-- alter table store_sales  add constraint fk_ss_ticket_number
-- foreign key (ss_ticket_number) references store_returns(sr_ticket_number);
-- -- HAMMERORA GO
--
-- store_returns
-- 
alter table store_returns  add constraint fk_sr_returned_date_sk
foreign key (sr_returned_date_sk) references date_dim(d_date_sk);
-- HAMMERORA GO
alter table store_returns  add constraint fk_sr_return_time_sk
foreign key (sr_return_time_sk) references time_dim(t_time_sk);
-- HAMMERORA GO
alter table store_returns  add constraint fk_sr_item_sk
foreign key (sr_item_sk) references item(i_item_sk);
-- HAMMERORA GO
-- alter table store_returns  add constraint fk_sr_item_sk_2
-- foreign key (sr_item_sk) references store_sales(ss_item_sk);
-- -- HAMMERORA GO
alter table store_returns  add constraint fk_sr_customer_sk
foreign key (sr_customer_sk) references customer(c_customer_sk);
-- HAMMERORA GO
alter table store_returns  add constraint fk_sr_cdemo_sk
foreign key (sr_cdemo_sk) references customer_demographics(cd_demo_sk);
-- HAMMERORA GO
alter table store_returns  add constraint fk_sr_hdemo_sk
foreign key (sr_hdemo_sk) references household_demographics(hd_demo_sk);
-- HAMMERORA GO
alter table store_returns  add constraint fk_sr_addr_sk
foreign key (sr_addr_sk) references customer_address(ca_address_sk);
-- HAMMERORA GO
alter table store_returns  add constraint fk_sr_store_sk
foreign key (sr_store_sk) references store(s_store_sk);
-- HAMMERORA GO
alter table store_returns  add constraint fk_sr_reason_sk
foreign key (sr_reason_sk) references reason(r_reason_sk);
-- HAMMERORA GO
-- alter table store_returns  add constraint fk_sr_ticket_number
-- foreign key (sr_ticket_number) references store_sales(ss_ticket_number);
-- -- HAMMERORA GO
--
-- catalog_sales
-- 
alter table catalog_sales  add constraint fk_cs_sold_date_sk
foreign key (cs_sold_date_sk) references date_dim(d_date_sk);
-- HAMMERORA GO
alter table catalog_sales  add constraint fk_cs_sold_time_sk
foreign key (cs_sold_time_sk) references time_dim(t_time_sk);
-- HAMMERORA GO
alter table catalog_sales  add constraint fk_cs_ship_date_sk
foreign key (cs_ship_date_sk) references date_dim(d_date_sk);
-- HAMMERORA GO
alter table catalog_sales  add constraint fk_cs_bill_customer_sk
foreign key (cs_bill_customer_sk) references customer(c_customer_sk);
-- HAMMERORA GO
alter table catalog_sales  add constraint fk_cs_bill_cdemo_sk
foreign key (cs_bill_cdemo_sk) references customer_demographics(cd_demo_sk);
-- HAMMERORA GO
alter table catalog_sales  add constraint fk_cs_bill_hdemo_sk
foreign key (cs_bill_hdemo_sk) references household_demographics(hd_demo_sk);
-- HAMMERORA GO
alter table catalog_sales  add constraint fk_cs_bill_addr_sk
foreign key (cs_bill_addr_sk) references customer_address(ca_address_sk);
-- HAMMERORA GO
alter table catalog_sales  add constraint fk_cs_ship_customer_sk
foreign key (cs_ship_customer_sk) references customer(c_customer_sk);
-- HAMMERORA GO
alter table catalog_sales  add constraint fk_cs_ship_cdemo_sk
foreign key (cs_ship_cdemo_sk) references customer_demographics(cd_demo_sk);
-- HAMMERORA GO
alter table catalog_sales  add constraint fk_cs_ship_hdemo_sk
foreign key (cs_ship_hdemo_sk) references household_demographics(hd_demo_sk);
-- HAMMERORA GO
alter table catalog_sales  add constraint fk_cs_ship_addr_sk
foreign key (cs_ship_addr_sk) references customer_address(ca_address_sk);
-- HAMMERORA GO
alter table catalog_sales  add constraint fk_cs_call_center_sk
foreign key (cs_call_center_sk) references call_center(cc_call_center_sk);
-- HAMMERORA GO
alter table catalog_sales  add constraint fk_cs_catalog_page_sk
foreign key (cs_catalog_page_sk) references catalog_page(cp_catalog_page_sk);
-- HAMMERORA GO
alter table catalog_sales  add constraint fk_cs_ship_mode_sk
foreign key (cs_ship_mode_sk) references ship_mode(sm_ship_mode_sk);
-- HAMMERORA GO
alter table catalog_sales  add constraint fk_cs_warehouse_sk
foreign key (cs_warehouse_sk) references warehouse(w_warehouse_sk);
-- HAMMERORA GO
alter table catalog_sales  add constraint fk_cs_item_sk_1
foreign key (cs_item_sk) references item(i_item_sk);
-- HAMMERORA GO
-- alter table catalog_sales  add constraint fk_cs_item_sk_2
-- foreign key (cs_item_sk) references catalog_returns(cr_item_sk);
-- -- HAMMERORA GO
alter table catalog_sales  add constraint fk_cs_promo_sk
foreign key (cs_promo_sk) references promotion(p_promo_sk);
-- HAMMERORA GO
-- alter table catalog_sales  add constraint fk_cs_order_number
-- foreign key (cs_order_number) references catalog_returns(cr_order_number);
-- HAMMERORA GO
--
-- catalog_returns
alter table catalog_returns  add constraint fk_cr_returned_date_sk
foreign key (cr_returned_date_sk) references date_dim(d_date_sk);
-- HAMMERORA GO
alter table catalog_returns  add constraint fk_cr_return_time_sk
foreign key (cr_return_time_sk) references time_dim(t_time_sk);
-- HAMMERORA GO
alter table catalog_returns  add constraint fk_cr_item_sk_1
foreign key (cr_item_sk) references item(i_item_sk);
-- HAMMERORA GO
-- alter table catalog_returns  add constraint fk_cr_item_sk_2
-- foreign key (cr_item_sk) references catalog_sales(cs_item_sk);
-- -- HAMMERORA GO
alter table catalog_returns  add constraint fk_cr_refunded_customer_sk
foreign key (cr_refunded_customer_sk) references customer(c_customer_sk);
-- HAMMERORA GO
alter table catalog_returns  add constraint fk_cr_refunded_cdemo_sk
foreign key (cr_refunded_cdemo_sk) references customer_demographics(cd_demo_sk);
-- HAMMERORA GO
alter table catalog_returns  add constraint fk_cr_refunded_hdemo_sk
foreign key (cr_refunded_hdemo_sk) references household_demographics(hd_demo_sk);
-- HAMMERORA GO
alter table catalog_returns  add constraint fk_cr_refunded_addr_sk
foreign key (cr_refunded_addr_sk) references customer_address(ca_address_sk);
-- HAMMERORA GO
alter table catalog_returns  add constraint fk_cr_returning_customer_sk
foreign key (cr_returning_customer_sk) references customer(c_customer_sk);
-- HAMMERORA GO
alter table catalog_returns  add constraint fk_cr_returning_cdemo_sk
foreign key (cr_returning_cdemo_sk) references customer_demographics(cd_demo_sk);
-- HAMMERORA GO
alter table catalog_returns  add constraint fk_cr_return_hdemo_sk
foreign key (cr_returning_hdemo_sk) references household_demographics(hd_demo_sk);
-- HAMMERORA GO
alter table catalog_returns  add constraint fk_cr_returning_addr_sk
foreign key (cr_returning_addr_sk) references customer_address(ca_address_sk);
-- HAMMERORA GO
alter table catalog_returns  add constraint fk_cr_call_center_sk
foreign key (cr_call_center_sk) references call_center(cc_call_center_sk);
-- HAMMERORA GO
alter table catalog_returns  add constraint fk_cr_catalog_page_sk
foreign key (cr_catalog_page_sk) references catalog_page(cp_catalog_page_sk);
-- HAMMERORA GO
alter table catalog_returns  add constraint fk_cr_ship_mode_sk
foreign key (cr_ship_mode_sk) references ship_mode(sm_ship_mode_sk);
-- HAMMERORA GO
alter table catalog_returns  add constraint fk_cr_warehouse_sk
foreign key (cr_warehouse_sk) references warehouse(w_warehouse_sk);
-- HAMMERORA GO
alter table catalog_returns  add constraint fk_cr_reason_sk
foreign key (cr_reason_sk) references reason(r_reason_sk);
-- HAMMERORA GO
-- alter table catalog_returns  add constraint fk_cr_order_number_sk
-- foreign key (cr_order_number_sk) references customer_sales(cs_order_number);
-- -- HAMMERORA GO
--
-- web_sales
-- 

alter table web_sales  add constraint fk_ws_sold_date_sk
foreign key (ws_sold_date_sk) references date_dim(d_date_sk);
-- HAMMERORA GO
alter table web_sales  add constraint fk_ws_sold_time_sk
foreign key (ws_sold_time_sk) references time_dim(t_time_sk);
-- HAMMERORA GO
alter table web_sales  add constraint fk_ws_ship_date_sk
foreign key (ws_ship_date_sk) references date_dim(d_date_sk);
-- HAMMERORA GO
alter table web_sales  add constraint fk_ws_item_sk_1
foreign key (ws_item_sk) references item(i_item_sk);
-- HAMMERORA GO
alter table web_sales  add constraint fk_ws_bill_customer_sk
foreign key (ws_bill_customer_sk) references customer(c_customer_sk);
-- HAMMERORA GO
alter table web_sales  add constraint fk_ws_bill_cdemo_sk
foreign key (ws_bill_cdemo_sk) references customer_demographics(cd_demo_sk);
-- HAMMERORA GO
alter table web_sales  add constraint fk_ws_bill_hdemo_sk
foreign key (ws_bill_hdemo_sk) references household_demographics(hd_demo_sk);
-- HAMMERORA GO
alter table web_sales  add constraint fk_ws_bill_addr_sk
foreign key (ws_bill_addr_sk) references customer_address(ca_address_sk);
-- HAMMERORA GO
alter table web_sales  add constraint fk_ws_ship_customer_sk
foreign key (ws_ship_customer_sk) references customer(c_customer_sk);
-- HAMMERORA GO
alter table web_sales  add constraint fk_ws_ship_cdemo_sk
foreign key (ws_ship_cdemo_sk) references customer_demographics(cd_demo_sk);
-- HAMMERORA GO
alter table web_sales  add constraint fk_ws_ship_hdemo_sk
foreign key (ws_ship_hdemo_sk) references household_demographics(hd_demo_sk);
-- HAMMERORA GO
alter table web_sales  add constraint fk_ws_ship_addr_sk
foreign key (ws_ship_addr_sk) references customer_address(ca_address_sk);
-- HAMMERORA GO
alter table web_sales  add constraint fk_ws_web_page_sk
foreign key (ws_web_page_sk) references web_page(wp_web_page_sk);
-- HAMMERORA GO
alter table web_sales  add constraint fk_ws_web_site_sk
foreign key (ws_web_site_sk) references web_site(web_site_sk);
-- HAMMERORA GO
alter table web_sales  add constraint fk_ws_ship_mode_sk
foreign key (ws_ship_mode_sk) references ship_mode(sm_ship_mode_sk);
-- HAMMERORA GO
alter table web_sales  add constraint fk_ws_warehouse_sk
foreign key (ws_warehouse_sk) references warehouse(w_warehouse_sk);
-- HAMMERORA GO
alter table web_sales  add constraint fk_ws_promo_sk
foreign key (ws_promo_sk) references promotion(p_promo_sk);
-- HAMMERORA GO
-- alter table web_sales  add constraint fk_ws_order_number_sk
-- foreign key (ws_order_number_sk) references web_returns(wr_order_number);
-- -- HAMMERORA GO
--
-- web_returns
-- 

alter table web_returns  add constraint fk_wr_returned_date_sk
foreign key (wr_returned_date_sk) references date_dim(d_date_sk);
-- HAMMERORA GO
alter table web_returns  add constraint fk_wr_returned_time_sk
foreign key (wr_returned_time_sk) references time_dim(t_time_sk);
-- HAMMERORA GO
alter table web_returns  add constraint fk_wr_item_sk_1
foreign key (wr_item_sk) references item(i_item_sk);
-- HAMMERORA GO
-- alter table web_returns  add constraint fk_wr_item_sk_2
-- foreign key (wr_item_sk) references web_sales(ws_item_sk);
-- -- HAMMERORA GO
alter table web_returns  add constraint fk_wr_refunded_customer_sk
foreign key (wr_refunded_customer_sk) references customer(c_customer_sk);
-- HAMMERORA GO
alter table web_returns  add constraint fk_wr_refunded_cdemo_sk
foreign key (wr_refunded_cdemo_sk) references customer_demographics(cd_demo_sk);
-- HAMMERORA GO
alter table web_returns  add constraint fk_wr_refunded_hdemo_sk
foreign key (wr_refunded_hdemo_sk) references household_demographics(hd_demo_sk);
-- HAMMERORA GO
alter table web_returns  add constraint fk_wr_refunded_addr_sk
foreign key (wr_refunded_addr_sk) references customer_address(ca_address_sk);
-- HAMMERORA GO
alter table web_returns  add constraint fk_wr_returning_customer_sk
foreign key (wr_returning_customer_sk) references customer(c_customer_sk);
-- HAMMERORA GO
alter table web_returns  add constraint fk_wr_returning_cdemo_sk
foreign key (wr_returning_cdemo_sk) references customer_demographics(cd_demo_sk);
-- HAMMERORA GO
alter table web_returns  add constraint fk_wr_returning_hdemo_sk
foreign key (wr_returning_hdemo_sk) references household_demographics(hd_demo_sk);
-- HAMMERORA GO
alter table web_returns  add constraint fk_wr_returning_addr_sk
foreign key (wr_returning_addr_sk) references customer_address(ca_address_sk);
-- HAMMERORA GO
alter table web_returns  add constraint fk_wr_web_page_sk
foreign key (wr_web_page_sk) references web_page(wp_web_page_sk);
-- HAMMERORA GO
alter table web_returns  add constraint fk_wr_reason_sk
foreign key (wr_reason_sk) references reason(r_reason_sk);
-- HAMMERORA GO
-- alter table web_returns  add constraint fk_wr_order_number
-- foreign key (wr_order_number) references web_sales(ws_order_number);
-- -- HAMMERORA GO
--
-- inv
-- 
alter table inventory  add constraint fk_inv_date_sk
foreign key (inv_date_sk) references date_dim(d_date_sk);
-- HAMMERORA GO
alter table inventory  add constraint fk_inv_item_sk
foreign key (inv_item_sk) references item(i_item_sk);
-- HAMMERORA GO
alter table inventory  add constraint fk_inv_warehouse_sk
foreign key (inv_warehouse_sk) references warehouse(w_warehouse_sk);
-- HAMMERORA GO
--
-- store
-- 
alter table store  add constraint fk_s_closed_date_sk
foreign key (s_closed_date_sk) references date_dim(d_date_sk);
-- HAMMERORA GO
--
-- call_center
-- 
alter table call_center  add constraint fk_cc_closed_date_sk
foreign key (cc_closed_date_sk) references date_dim(d_date_sk);
-- HAMMERORA GO
alter table call_center  add constraint fk_cc_opened_date_sk
foreign key (cc_open_date_sk) references date_dim(d_date_sk);
-- HAMMERORA GO
--
-- catalog_page
-- 
alter table catalog_page  add constraint fk_cp_start_date_sk
foreign key (cp_start_date_sk) references date_dim(d_date_sk);
-- HAMMERORA GO
alter table catalog_page  add constraint fk_cp_end_date_sk
foreign key (cp_end_date_sk) references date_dim(d_date_sk);
-- HAMMERORA GO
--
-- web_site
-- 
alter table web_site  add constraint fk_web_close_date_sk
foreign key (web_close_date_sk) references date_dim(d_date_sk);
-- HAMMERORA GO
alter table web_site  add constraint fk_web_open_date_sk
foreign key (web_open_date_sk) references date_dim(d_date_sk);
-- HAMMERORA GO
--
-- web_page
-- 
alter table web_page  add constraint fk_wp_creation_date_sk
foreign key (wp_creation_date_sk) references date_dim(d_date_sk);
-- HAMMERORA GO
alter table web_page  add constraint fk_wp_access_date_sk
foreign key (wp_access_date_sk) references date_dim(d_date_sk);
-- HAMMERORA GO
alter table web_page  add constraint fk_wp_customer_sk
foreign key (wp_customer_sk) references customer(c_customer_sk);
-- HAMMERORA GO
--
-- warehouse - has no FK
-- 
--
-- customer 
-- 
alter table customer  add constraint fk_c_current_cdemo_sk
foreign key (c_current_cdemo_sk) references customer_demographics(cd_demo_sk);
-- HAMMERORA GO
alter table customer  add constraint fk_c_current_hdemo_sk
foreign key (c_current_hdemo_sk) references household_demographics(hd_demo_sk);
-- HAMMERORA GO
alter table customer  add constraint fk_c_current_addr_sk
foreign key (c_current_addr_sk) references customer_address(ca_address_sk);
-- HAMMERORA GO
alter table customer  add constraint fk_c_first_shipto_date_sk
foreign key (c_first_shipto_date_sk) references date_dim(d_date_sk);
-- HAMMERORA GO
alter table customer  add constraint fk_c_first_sales_date_sk
foreign key (c_first_sales_date_sk) references date_dim(d_date_sk);
-- HAMMERORA GO
--
-- customer_address - has no FK
-- customer_demographics - has no FK
-- date_dim - has no FK
-- household_demographcs - has no FK
-- item - has no FK
-- income_band - has no FK
--
-- promotion
-- 
alter table promotion  add constraint fk_p_start_date_sk
foreign key (p_start_date_sk) references date_dim(d_date_sk);
-- HAMMERORA GO
alter table promotion  add constraint fk_p_end_date_sk
foreign key (p_end_date_sk) references date_dim(d_date_sk);
-- HAMMERORA GO
alter table promotion  add constraint fk_p_item_sk
foreign key (p_item_sk) references item(i_item_sk);
-- HAMMERORA GO
--
-- reason - has no FK
-- ship_mode - has no FK
-- time_dim - has no FK
-- dsdgen_version - has no FK
-- 
