alter table store_sales check constraint fk_ss_sold_date_sk;
-- HAMMERORA GO
alter table store_sales check constraint fk_ss_sold_time_sk;
-- HAMMERORA GO
alter table store_sales check constraint fk_ss_item_sk_1;
-- HAMMERORA GO
-- alter table store_sales check constraint fk_ss_item_sk_2;
-- -- HAMMERORA GO
alter table store_sales check constraint fk_ss_customer_sk;
-- HAMMERORA GO
alter table store_sales check constraint fk_ss_demo_sk_1;
-- HAMMERORA GO
alter table store_sales check constraint fk_ss_demo_sk_2;
-- HAMMERORA GO
alter table store_sales check constraint fk_ss_addr_sk;
-- HAMMERORA GO
alter table store_sales check constraint fk_ss_store_sk;
-- HAMMERORA GO
alter table store_sales check constraint fk_ss_promo_sk;
-- HAMMERORA GO
-- alter table store_sales check constraint fk_ss_ticket_number;
-- -- HAMMERORA GO
alter table store_returns check constraint fk_sr_returned_date_sk;
-- HAMMERORA GO
alter table store_returns check constraint fk_sr_return_time_sk;
-- HAMMERORA GO
alter table store_returns check constraint fk_sr_item_sk;
-- HAMMERORA GO
-- alter table store_returns check constraint fk_sr_item_sk_2;
-- -- HAMMERORA GO
alter table store_returns check constraint fk_sr_customer_sk;
-- HAMMERORA GO
alter table store_returns check constraint fk_sr_cdemo_sk;
-- HAMMERORA GO
alter table store_returns check constraint fk_sr_hdemo_sk;
-- HAMMERORA GO
alter table store_returns check constraint fk_sr_addr_sk;
-- HAMMERORA GO
alter table store_returns check constraint fk_sr_store_sk;
-- HAMMERORA GO
alter table store_returns check constraint fk_sr_reason_sk;
-- HAMMERORA GO
-- alter table store_returns check constraint fk_sr_ticket_number;
-- -- HAMMERORA GO
alter table catalog_sales check constraint fk_cs_sold_date_sk;
-- HAMMERORA GO
alter table catalog_sales check constraint fk_cs_sold_time_sk;
-- HAMMERORA GO
alter table catalog_sales check constraint fk_cs_ship_date_sk;
-- HAMMERORA GO
alter table catalog_sales check constraint fk_cs_bill_customer_sk;
-- HAMMERORA GO
alter table catalog_sales check constraint fk_cs_bill_cdemo_sk;
-- HAMMERORA GO
alter table catalog_sales check constraint fk_cs_bill_hdemo_sk;
-- HAMMERORA GO
alter table catalog_sales check constraint fk_cs_bill_addr_sk;
-- HAMMERORA GO
alter table catalog_sales check constraint fk_cs_ship_customer_sk;
-- HAMMERORA GO
alter table catalog_sales check constraint fk_cs_ship_cdemo_sk;
-- HAMMERORA GO
alter table catalog_sales check constraint fk_cs_ship_hdemo_sk;
-- HAMMERORA GO
alter table catalog_sales check constraint fk_cs_ship_addr_sk;
-- HAMMERORA GO
alter table catalog_sales check constraint fk_cs_call_center_sk;
-- HAMMERORA GO
alter table catalog_sales check constraint fk_cs_catalog_page_sk;
-- HAMMERORA GO
alter table catalog_sales check constraint fk_cs_ship_mode_sk;
-- HAMMERORA GO
alter table catalog_sales check constraint fk_cs_warehouse_sk;
-- HAMMERORA GO
alter table catalog_sales check constraint fk_cs_item_sk_1;
-- HAMMERORA GO
-- alter table catalog_sales check constraint fk_cs_item_sk_2;
-- -- HAMMERORA GO
alter table catalog_sales check constraint fk_cs_promo_sk;
-- HAMMERORA GO
-- alter table catalog_sales check constraint fk_cs_order_number;
-- HAMMERORA GO
alter table catalog_returns check constraint fk_cr_returned_date_sk;
-- HAMMERORA GO
alter table catalog_returns check constraint fk_cr_return_time_sk;
-- HAMMERORA GO
alter table catalog_returns check constraint fk_cr_item_sk_1;
-- HAMMERORA GO
-- alter table catalog_returns check constraint fk_cr_item_sk_2;
-- -- HAMMERORA GO
alter table catalog_returns check constraint fk_cr_refunded_customer_sk;
-- HAMMERORA GO
alter table catalog_returns check constraint fk_cr_refunded_cdemo_sk;
-- HAMMERORA GO
alter table catalog_returns check constraint fk_cr_refunded_hdemo_sk;
-- HAMMERORA GO
alter table catalog_returns check constraint fk_cr_refunded_addr_sk;
-- HAMMERORA GO
alter table catalog_returns check constraint fk_cr_returning_customer_sk;
-- HAMMERORA GO
alter table catalog_returns check constraint fk_cr_returning_cdemo_sk;
-- HAMMERORA GO
alter table catalog_returns check constraint fk_cr_return_hdemo_sk;
-- HAMMERORA GO
alter table catalog_returns check constraint fk_cr_returning_addr_sk;
-- HAMMERORA GO
alter table catalog_returns check constraint fk_cr_call_center_sk;
-- HAMMERORA GO
alter table catalog_returns check constraint fk_cr_catalog_page_sk;
-- HAMMERORA GO
alter table catalog_returns check constraint fk_cr_ship_mode_sk;
-- HAMMERORA GO
alter table catalog_returns check constraint fk_cr_warehouse_sk;
-- HAMMERORA GO
alter table catalog_returns check constraint fk_cr_reason_sk;
-- HAMMERORA GO
-- alter table catalog_returns check constraint fk_cr_order_number_sk;
-- -- HAMMERORA GO
alter table web_sales check constraint fk_ws_sold_date_sk;
-- HAMMERORA GO
alter table web_sales check constraint fk_ws_sold_time_sk;
-- HAMMERORA GO
alter table web_sales check constraint fk_ws_ship_date_sk;
-- HAMMERORA GO
alter table web_sales check constraint fk_ws_item_sk_1;
-- HAMMERORA GO
alter table web_sales check constraint fk_ws_bill_customer_sk;
-- HAMMERORA GO
alter table web_sales check constraint fk_ws_bill_cdemo_sk;
-- HAMMERORA GO
alter table web_sales check constraint fk_ws_bill_hdemo_sk;
-- HAMMERORA GO
alter table web_sales check constraint fk_ws_bill_addr_sk;
-- HAMMERORA GO
alter table web_sales check constraint fk_ws_ship_customer_sk;
-- HAMMERORA GO
alter table web_sales check constraint fk_ws_ship_cdemo_sk;
-- HAMMERORA GO
alter table web_sales check constraint fk_ws_ship_hdemo_sk;
-- HAMMERORA GO
alter table web_sales check constraint fk_ws_ship_addr_sk;
-- HAMMERORA GO
alter table web_sales check constraint fk_ws_web_page_sk;
-- HAMMERORA GO
alter table web_sales check constraint fk_ws_web_site_sk;
-- HAMMERORA GO
alter table web_sales check constraint fk_ws_ship_mode_sk;
-- HAMMERORA GO
alter table web_sales check constraint fk_ws_warehouse_sk;
-- HAMMERORA GO
alter table web_sales check constraint fk_ws_promo_sk;
-- HAMMERORA GO
-- alter table web_sales check constraint fk_ws_order_number_sk;
-- -- HAMMERORA GO
alter table web_returns check constraint fk_wr_returned_date_sk;
-- HAMMERORA GO
alter table web_returns check constraint fk_wr_returned_time_sk;
-- HAMMERORA GO
alter table web_returns check constraint fk_wr_item_sk_1;
-- HAMMERORA GO
-- alter table web_returns check constraint fk_wr_item_sk_2;
-- -- HAMMERORA GO
alter table web_returns check constraint fk_wr_refunded_customer_sk;
-- HAMMERORA GO
alter table web_returns check constraint fk_wr_refunded_cdemo_sk;
-- HAMMERORA GO
alter table web_returns check constraint fk_wr_refunded_hdemo_sk;
-- HAMMERORA GO
alter table web_returns check constraint fk_wr_refunded_addr_sk;
-- HAMMERORA GO
alter table web_returns check constraint fk_wr_returning_customer_sk;
-- HAMMERORA GO
alter table web_returns check constraint fk_wr_returning_cdemo_sk;
-- HAMMERORA GO
alter table web_returns check constraint fk_wr_returning_hdemo_sk;
-- HAMMERORA GO
alter table web_returns check constraint fk_wr_returning_addr_sk;
-- HAMMERORA GO
alter table web_returns check constraint fk_wr_web_page_sk;
-- HAMMERORA GO
alter table web_returns check constraint fk_wr_reason_sk;
-- HAMMERORA GO
-- alter table web_returns check constraint fk_wr_order_number;
-- -- HAMMERORA GO
alter table inventory check constraint fk_inv_date_sk;
-- HAMMERORA GO
alter table inventory check constraint fk_inv_item_sk;
-- HAMMERORA GO
alter table inventory check constraint fk_inv_warehouse_sk;
-- HAMMERORA GO
alter table store check constraint fk_s_closed_date_sk;
-- HAMMERORA GO
alter table call_center check constraint fk_cc_closed_date_sk;
-- HAMMERORA GO
alter table call_center check constraint fk_cc_opened_date_sk;
-- HAMMERORA GO
alter table catalog_page check constraint fk_cp_start_date_sk;
-- HAMMERORA GO
alter table catalog_page check constraint fk_cp_end_date_sk;
-- HAMMERORA GO
alter table web_site check constraint fk_web_close_date_sk;
-- HAMMERORA GO
alter table web_site check constraint fk_web_open_date_sk;
-- HAMMERORA GO
alter table web_page check constraint fk_wp_creation_date_sk;
-- HAMMERORA GO
alter table web_page check constraint fk_wp_access_date_sk;
-- HAMMERORA GO
alter table web_page check constraint fk_wp_customer_sk;
-- HAMMERORA GO
alter table customer check constraint fk_c_current_cdemo_sk;
-- HAMMERORA GO
alter table customer check constraint fk_c_current_hdemo_sk;
-- HAMMERORA GO
alter table customer check constraint fk_c_current_addr_sk;
-- HAMMERORA GO
alter table customer check constraint fk_c_first_shipto_date_sk;
-- HAMMERORA GO
alter table customer check constraint fk_c_first_sales_date_sk;
-- HAMMERORA GO
alter table promotion check constraint fk_p_start_date_sk;
-- HAMMERORA GO
alter table promotion check constraint fk_p_end_date_sk;
-- HAMMERORA GO
alter table promotion check constraint fk_p_item_sk;
-- HAMMERORA GO
