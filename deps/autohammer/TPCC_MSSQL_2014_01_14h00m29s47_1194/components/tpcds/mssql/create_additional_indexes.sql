-- MISSING INDEXES AND STATISTICS
CREATE NONCLUSTERED INDEX ss_item_customer_nidx
ON dbo.store_sales (ss_customer_sk)
INCLUDE (ss_quantity,ss_sales_price)
-- HAMMERORA GO
CREATE NONCLUSTERED INDEX i_item_price_id_nidx 
ON dbo.item (i_current_price,i_manufact_id)
INCLUDE (i_item_sk,i_item_id,i_item_desc)
-- HAMMERORA GO
CREATE STATISTICS dd_stat_week_date_date ON dbo.date_dim(d_current_week, d_date_sk, d_date)
-- HAMMERORA GO
CREATE STATISTICS dd_stat_date_date ON dbo.date_dim(d_date_sk, d_date)
-- HAMMERORA GO
CREATE STATISTICS inv_stat_quantity_item ON dbo.inventory(inv_quantity_on_hand, inv_item_sk)
-- HAMMERORA GO
CREATE STATISTICS inv_stat_quantity_date_item ON dbo.inventory(inv_quantity_on_hand, inv_date_sk, inv_item_sk)
-- HAMMERORA GO
CREATE NONCLUSTERED INDEX inv_item_quantity_date_nidx ON dbo.inventory 
(
	inv_item_sk ASC,
	inv_quantity_on_hand ASC,
	inv_date_sk ASC
)WITH (SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF) ON 'PRIMARY'
-- HAMMERORA GO
CREATE STATISTICS item_stat_item_current ON dbo.item(i_item_sk, i_current_price)
-- HAMMERORA GO
CREATE NONCLUSTERED INDEX item_id_desc_price_nidx ON dbo.item 
(
	i_item_id ASC,
	i_item_desc ASC,
	i_current_price ASC,
	i_manufact_id ASC
)
INCLUDE ( i_item_sk) WITH (SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF) ON 'PRIMARY'
-- HAMMERORA GO
CREATE STATISTICS ss_stat_whole_item ON dbo.store_sales(ss_wholesale_cost, ss_item_sk)
-- HAMMERORA GO
-- NEXT GROUP
CREATE STATISTICS _dta_stat_2137058649_4_1 ON dbo.catalog_sales(cs_bill_customer_sk, cs_sold_date_sk)
-- HAMMERORA GO
CREATE STATISTICS _dta_stat_2137058649_1_16_4 ON dbo.catalog_sales(cs_sold_date_sk, cs_item_sk, cs_bill_customer_sk)
-- HAMMERORA GO
CREATE NONCLUSTERED INDEX _dta_index_customer_5_165575628__K1 ON dbo.customer 
(
	c_customer_sk ASC
)WITH (SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF) ON 'PRIMARY'
-- HAMMERORA GO
CREATE STATISTICS _dta_stat_213575799_7_3 ON dbo.date_dim(d_year, d_date)
-- HAMMERORA GO
CREATE STATISTICS _dta_stat_213575799_7_9_3 ON dbo.date_dim(d_year, d_moy, d_date)
-- HAMMERORA GO
CREATE NONCLUSTERED INDEX _dta_index_date_dim_5_213575799__K7_K1_K3 ON dbo.date_dim 
(
	d_year ASC,
	d_date_sk ASC,
	d_date ASC
)WITH (SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF) ON 'PRIMARY'
-- HAMMERORA GO
CREATE STATISTICS _dta_stat_213575799_1_7_9_3 ON dbo.date_dim(d_date_sk, d_year, d_moy, d_date)
-- HAMMERORA GO
CREATE STATISTICS _dta_stat_2105058535_4_3_1 ON dbo.store_sales(ss_customer_sk, ss_item_sk, ss_sold_date_sk)
-- HAMMERORA GO
CREATE NONCLUSTERED INDEX _dta_index_store_sales_5_2105058535__K1_K3 ON dbo.store_sales 
(
	ss_sold_date_sk ASC,
	ss_item_sk ASC
)WITH (SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF) ON 'PRIMARY'
-- HAMMERORA GO
CREATE STATISTICS _dta_stat_2105058535_1_4 ON dbo.store_sales(ss_sold_date_sk, ss_customer_sk)
-- HAMMERORA GO
CREATE NONCLUSTERED INDEX _dta_index_store_sales_5_2105058535__K1_K3_K4_11_14 ON dbo.store_sales 
(
	ss_sold_date_sk ASC,
	ss_item_sk ASC,
	ss_customer_sk ASC
)
INCLUDE ( ss_quantity,
ss_sales_price) WITH (SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF) ON 'PRIMARY'
-- HAMMERORA GO
CREATE STATISTICS _dta_stat_21575115_1_5 ON dbo.web_sales(ws_sold_date_sk, ws_bill_customer_sk)
-- HAMMERORA GO
CREATE STATISTICS _dta_stat_21575115_1_4_5 ON dbo.web_sales(ws_sold_date_sk, ws_item_sk, ws_bill_customer_sk)
-- HAMMERORA GO
CREATE STATISTICS _dta_stat_165575628_1_15_10_9 ON dbo.customer(c_customer_sk, c_birth_country, c_last_name, c_first_name)
-- HAMMERORA GO
CREATE STATISTICS _dta_stat_165575628_10_9_15 ON dbo.customer(c_last_name, c_first_name, c_birth_country)
-- HAMMERORA GO
CREATE STATISTICS _dta_stat_181575685_9_10 ON dbo.customer_address(ca_state, ca_zip)
-- HAMMERORA GO
CREATE STATISTICS _dta_stat_245575913_1_18_6_21_19_16 ON dbo.item(i_item_sk, i_color, i_current_price, i_manager_id, i_units, i_size)
-- HAMMERORA GO
CREATE STATISTICS _dta_stat_245575913_18_6_21_19_16 ON dbo.item(i_color, i_current_price, i_manager_id, i_units, i_size)
-- HAMMERORA GO
CREATE STATISTICS _dta_stat_69575286_6_25_11_26 ON dbo.store(s_store_name, s_state, s_market_id, s_zip)
-- HAMMERORA GO
CREATE STATISTICS _dta_stat_69575286_6_25_26 ON dbo.store(s_store_name, s_state, s_zip)
-- HAMMERORA GO
CREATE STATISTICS _dta_stat_69575286_26_11_1_6_25 ON dbo.store(s_zip, s_market_id, s_store_sk, s_store_name, s_state)
-- HAMMERORA GO
CREATE STATISTICS _dta_stat_69575286_1_11 ON dbo.store(s_store_sk, s_market_id)
-- HAMMERORA GO
CREATE STATISTICS _dta_stat_69575286_26_1 ON dbo.store(s_zip, s_store_sk)
-- HAMMERORA GO
CREATE STATISTICS _dta_stat_2105058535_3_4_8_10 ON dbo.store_sales(ss_item_sk, ss_customer_sk, ss_store_sk, ss_ticket_number)
-- HAMMERORA GO
CREATE STATISTICS _dta_stat_2105058535_4_1 ON dbo.store_sales(ss_customer_sk, ss_sold_date_sk)
-- HAMMERORA GO
CREATE STATISTICS _dta_stat_2105058535_4_8_1 ON dbo.store_sales(ss_customer_sk, ss_store_sk, ss_sold_date_sk)
-- HAMMERORA GO
CREATE STATISTICS _dta_stat_2105058535_3_10_1_4 ON dbo.store_sales(ss_item_sk, ss_ticket_number, ss_sold_date_sk, ss_customer_sk)
-- HAMMERORA GO
CREATE NONCLUSTERED INDEX _dta_index_store_sales_5_2105058535__K8_K1_K3_K4_K10_21 ON dbo.store_sales 
(
	ss_store_sk ASC,
	ss_sold_date_sk ASC,
	ss_item_sk ASC,
	ss_customer_sk ASC,
	ss_ticket_number ASC
)
INCLUDE ( ss_net_paid) WITH (SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF) ON 'PRIMARY'
-- HAMMERORA GO
CREATE STATISTICS _dta_stat_2105058535_10_1 ON dbo.store_sales(ss_ticket_number, ss_sold_date_sk)
-- HAMMERORA GO
CREATE STATISTICS _dta_stat_2105058535_1_3_4 ON dbo.store_sales(ss_sold_date_sk, ss_item_sk, ss_customer_sk)
-- HAMMERORA GO
CREATE STATISTICS _dta_stat_2137058649_4_16 ON dbo.catalog_sales(cs_bill_customer_sk, cs_item_sk)
-- HAMMERORA GO
CREATE STATISTICS _dta_stat_2137058649_4_18 ON dbo.catalog_sales(cs_bill_customer_sk, cs_order_number)
-- HAMMERORA GO
CREATE NONCLUSTERED INDEX _dta_index_catalog_sales_5_2137058649__K1_K16_K4_K18_19_20_22 ON dbo.catalog_sales 
(
	cs_sold_date_sk ASC,
	cs_item_sk ASC,
	cs_bill_customer_sk ASC,
	cs_order_number ASC
)
INCLUDE ( cs_quantity,
cs_wholesale_cost,
cs_sales_price) WITH (SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF) ON 'PRIMARY'
-- HAMMERORA GO
CREATE STATISTICS _dta_stat_2137058649_16_18_4_1 ON dbo.catalog_sales(cs_item_sk, cs_order_number, cs_bill_customer_sk, cs_sold_date_sk)
-- HAMMERORA GO
-- Second batch
CREATE NONCLUSTERED INDEX _dta_index_store_sales_5_2105058535__K1_K4_K3_K10_11_12_14 ON dbo.store_sales 
(
	ss_sold_date_sk ASC,
	ss_customer_sk ASC,
	ss_item_sk ASC,
	ss_ticket_number ASC
)
INCLUDE ( ss_quantity,
ss_wholesale_cost,
ss_sales_price) WITH (SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF) ON 'PRIMARY'
-- HAMMERORA GO
CREATE STATISTICS _dta_stat_21575115_5_4_18_1 ON dbo.web_sales(ws_bill_customer_sk, ws_item_sk, ws_order_number, ws_sold_date_sk)
-- HAMMERORA GO
CREATE NONCLUSTERED INDEX _dta_index_web_sales_5_21575115__K1_K4_K5_K18_19_20_22 ON dbo.web_sales 
(
	ws_sold_date_sk ASC,
	ws_item_sk ASC,
	ws_bill_customer_sk ASC,
	ws_order_number ASC
)
INCLUDE ( ws_quantity,
ws_wholesale_cost,
ws_sales_price) WITH (SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF) ON 'PRIMARY'
-- HAMMERORA GO
CREATE STATISTICS _dta_stat_165575628_2_1_9_10 ON dbo.customer(c_customer_id, c_customer_sk, c_first_name, c_last_name)
-- HAMMERORA GO
CREATE NONCLUSTERED INDEX _dta_index_customer_5_165575628__K2_K9_K10_1 ON dbo.customer 
(
	c_customer_id ASC,
	c_first_name ASC,
	c_last_name ASC
)
INCLUDE ( c_customer_sk) WITH (SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF) ON 'PRIMARY'
-- HAMMERORA GO
CREATE NONCLUSTERED INDEX _dta_index_store_sales_5_2105058535__K1_K4_21 ON dbo.store_sales 
(
	ss_sold_date_sk ASC,
	ss_customer_sk ASC
)
INCLUDE ( ss_net_paid) WITH (SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF) ON 'PRIMARY'
-- HAMMERORA GO
CREATE NONCLUSTERED INDEX _dta_index_web_sales_5_21575115__K5_K1_30 ON dbo.web_sales 
(
	ws_bill_customer_sk ASC,
	ws_sold_date_sk ASC
)
INCLUDE ( ws_net_paid) WITH (SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF) ON 'PRIMARY'
-- HAMMERORA GO
-- start here
CREATE NONCLUSTERED INDEX _dta_index_web_sales_5_21575115__K1_K5_30 ON dbo.web_sales 
(
	ws_sold_date_sk ASC,
	ws_bill_customer_sk ASC
)
INCLUDE ( ws_net_paid) WITH (SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF) ON 'PRIMARY'

-- HAMMERORA GO
CREATE STATISTICS _dta_stat_277576027_1_8 ON dbo.catalog_sales(cs_sold_date_sk, cs_ship_customer_sk)
-- HAMMERORA GO
CREATE NONCLUSTERED INDEX _dta_index_catalog_sales_5_277576027__K8_K1 ON dbo.catalog_sales
(
	cs_ship_customer_sk ASC,
	cs_sold_date_sk ASC
)WITH (SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF) ON 'PRIMARY'
-- HAMMERORA GO
CREATE STATISTICS _dta_stat_453576654_3_5_1 ON dbo.customer(c_current_cdemo_sk, c_current_addr_sk, c_customer_sk)
-- HAMMERORA GO
CREATE NONCLUSTERED INDEX _dta_index_customer_5_453576654__K1_K3_K5 ON dbo.customer
(
	c_customer_sk ASC,
	c_current_cdemo_sk ASC,
	c_current_addr_sk ASC
)WITH (SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF) ON 'PRIMARY'
-- HAMMERORA GO
SET ANSI_PADDING ON

CREATE NONCLUSTERED INDEX _dta_index_customer_address_5_469576711__K8_K1 ON dbo.customer_address
(
	ca_county ASC,
	ca_address_sk ASC
)WITH (SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF) ON 'PRIMARY'
-- HAMMERORA GO
CREATE STATISTICS _dta_stat_485576768_2_3_4_5_6_7_8_9 
ON dbo.customer_demographics(cd_gender, cd_marital_status, cd_education_status, cd_purchase_estimate, 
	cd_credit_rating, cd_dep_count, cd_dep_employed_count, cd_dep_college_count)
-- HAMMERORA GO
CREATE STATISTICS _dta_stat_485576768_1_2_3_4_5_6_7_8_9 
ON dbo.customer_demographics(cd_demo_sk, cd_gender, cd_marital_status, cd_education_status, cd_purchase_estimate, 
	cd_credit_rating, cd_dep_count, cd_dep_employed_count, cd_dep_college_count)
-- HAMMERORA GO
CREATE STATISTICS _dta_stat_501576825_9_1 ON dbo.date_dim(d_moy, d_date_sk)
-- HAMMERORA GO
