-- s_zip_to_gmt -- No foreign keys defined
-- Need to create unique indexes for fk to work
create unique index i_item_id_uidx on item(i_item_id);
-- HAMMERORA GO
create unique index p_promo_id_uidx on promotion(p_promo_id);
-- HAMMERORA GO
create unique index c_customer_id_uidx on customer(c_customer_id);
-- HAMMERORA GO
create unique index cd_gender_uidx on customer_demographics(cd_gender);
-- HAMMERORA GO
create unique index cd_martial_status_uidx on customer_demographics(cd_martial_status);
-- HAMMERORA GO
create unique index cd_education_status_uidx on customer_demographics(cd_education_status);
-- HAMMERORA GO
create unique index cd_credit_rating_uidx on customer_demographics(cd_credit_rating);
-- HAMMERORA GO
create unique index cd_purchase_est_uidx on customer_demographics(cd_purchase_est);
-- HAMMERORA GO
create unique index cd_buy_potential_uidx on household_demographics(hd_buy_potential);
-- HAMMERORA GO
create unique index cd_dep_count_uidx on household_demographics(hd_dep_count);
-- HAMMERORA GO
create unique index cd_dep_employed_count_uidx on household_demographics(hd_dep_employed_count);
-- HAMMERORA GO
create unique index cd_dep_college_count_uidx on household_demographics(hd_dep_college_count);
-- HAMMERORA GO
create unique index cd_dep_vehicle_count_uidx on household_demographics(hd_dep_vehicle_count);
-- HAMMERORA GO
create unique index ib_lower_bound_uidx on income_band(ib_lower_bound);
-- HAMMERORA GO
create unique index ib_upper_bound_uidx on income_band(ib_upper_bound);
-- HAMMERORA GO
create unique index plin_purchase_id_uidx on s_purchase_lineitem(plin_purchase_id);
-- HAMMERORA GO
create unique index s_store_id_uidx on store(s_store_id);
-- HAMMERORA GO
create unique index s_customer_id_uidx on store(s_customer_id);
-- HAMMERORA GO
create unique index d_date_uidx on date_dim(d_date);
-- HAMMERORA GO
create unique index t_time_uidx on time_dim(t_time);
-- HAMMERORA GO
create unique index clin_order_id_uidx on s_catalog_order_lineitem(clin_order_id);
-- HAMMERORA GO
create unique index wlin_order_id_uidx on s_web_order_lineitem(wlin_order_id);
-- HAMMERORA GO
create unique index sm_ship_mode_id_uidx on ship_mode(sm_ship_mode_id);
-- HAMMERORA GO
create unique index web_site_id_uidx on web_site(web_site_id);
-- HAMMERORA GO
create unique index cord_order_id_uidx on s_catalog_order(cord_order_id);
-- HAMMERORA GO
create unique index w_warehouse_id_uidx on warehouse(w_warehouse_id);
-- HAMMERORA GO
create unique index web_order_id_uidx on s_web_order(web_order_id);
-- HAMMERORA GO
create unique index wp_web_page_id on web_page(wp_web_page_id);
-- HAMMERORA GO
create unique index cc_center_id_uidx on call_center(cc_center_id);
-- HAMMERORA GO
create unique index r_reason_id_uidx on reason(r_reason_id);
-- HAMMERORA GO
create unique index r_reason_id_uidx on reason(r_reason_id);
-- HAMMERORA GO
-- s_purchase_lineitem
alter table s_purchase_lineitem add constraint fk_plin_item_id
foreign key (plin_item_id) references item(i_item_id);
-- HAMMERORA GO
alter table s_purchase_lineitem add constraint fk_plin_promotion_id
foreign key (plin_promotion_id) references promotion(p_promo_id);
-- HAMMERORA GO
-- s_customer
alter table s_customer add constraint fk_cust_customer_id
foreign key (cust_customer_id) references customer(c_customer_id);
-- HAMMERORA GO
alter table s_customer add constraint fk_cust_gender
foreign key (cust_gender) references customer_demographics(cd_gender);
-- HAMMERORA GO
alter table s_customer add constraint fk_cust_martial_status
foreign key (cust_martial_status) references customer_demographics(cd_martial_status);
-- HAMMERORA GO
alter table s_customer add constraint fk_cust_educ_status
foreign key (cust_educ_status) references customer_demographics(cd_education_status);
-- HAMMERORA GO
alter table s_customer add constraint fk_cust_credit_rating
foreign key (cust_credit_rating) references customer_demographics(cd_credit_rating);
-- HAMMERORA GO
alter table s_customer add constraint fk_cust_purch_est
foreign key (cust_purch_est) references customer_demographics(cd_purchase_est);
-- HAMMERORA GO
alter table s_customer add constraint fk_cust_buy_potential
foreign key (cust_buy_potential) references household_demographics(hd_buy_potential);
-- HAMMERORA GO
alter table s_customer add constraint fk_cust_depend_cnt
foreign key (cust_depend_cnt) references household_demographics(hd_dep_count);
-- HAMMERORA GO
alter table s_customer add constraint fk_cust_depend_emp_cnt
foreign key (cust_depend_emp_cnt) references household_demographics(hd_dep_employed_count);
-- HAMMERORA GO
alter table s_customer add constraint fk_cust_depend_college_cnt
foreign key (cust_depend_college_cnt) references household_demographics(hd_dep_college_count);
-- HAMMERORA GO
alter table s_customer add constraint fk_cust_vehicle_cnt
foreign key (cust_vehicle_cnt) references household_demographics(hd_dep_vehicle_count);
-- HAMMERORA GO
alter table s_customer add constraint fk_cust_annual_income_lb
foreign key (cust_annual_income) references income_band(ib_lower_bound);
-- HAMMERORA GO
alter table s_customer add constraint fk_cust_annual_income_ub
foreign key (cust_annual_income) references income_band(ib_upper_bound);
-- HAMMERORA GO
-- s_purchase
alter table s_purchase add constraint fk_purc_purchase_id
foreign key (purc_purchase_id) references s_purchase_lineitem(plin_purchase_id);
-- HAMMERORA GO
alter table s_purchase add constraint fk_purc_store_id
foreign key (purc_store_id) references store(s_store_id);
-- HAMMERORA GO
alter table s_purchase add constraint fk_purc_customer_id
foreign key (purc_customer_id) references store(s_customer_id);
-- HAMMERORA GO
alter table s_purchase add constraint fk_purc_purchase_date
foreign key (purc_purchase_date) references date_dim(d_date);
-- HAMMERORA GO
alter table s_purchase add constraint fk_purc_purchase_time
foreign key (purc_purchase_time) references time_dim(t_time);
-- HAMMERORA GO
-- s_catalog_order
alter table s_catalog_order add constraint fk_cord_order_id
foreign key (cord_order_id) references s_catalog_order_lineitem(clin_order_id);
-- HAMMERORA GO
alter table s_catalog_order add constraint fk_cord_bill_customer_id
foreign key (cord_bill_customer_id) references customer(c_customer_id);
-- HAMMERORA GO
alter table s_catalog_order add constraint fk_cord_ship_customer_id
foreign key (cord_ship_customer_id) references customer(c_customer_id);
-- HAMMERORA GO
alter table s_catalog_order add constraint fk_cord_order_date
foreign key (cord_order_date) references date_dim(d_date);
-- HAMMERORA GO
alter table s_catalog_order add constraint fk_cord_order_time
foreign key (cord_order_time) references time_dim(t_time);
-- HAMMERORA GO
alter table s_catalog_order add constraint fk_cord_ship_mode_id
foreign key (cord_ship_mode_id) references time_dim(t_time);
-- HAMMERORA GO
alter table s_catalog_order add constraint fk_cord_ship_mode_id
foreign key (cord_ship_mode_id) references time_dim(t_time);
-- HAMMERORA GO
-- s_web_order
alter table s_web_order add constraint fk_word_order_id
foreign key (word_order_id) references s_web_order_lineitem(wlin_order_id);
-- HAMMERORA GO
alter table s_web_order add constraint fk_word_bill_customer_id
foreign key (word_bill_customer_id) references customer(c_customer_id);
-- HAMMERORA GO
alter table s_web_order add constraint fk_word_ship_customer_id
foreign key (word_ship_customer_id) references customer(c_customer_id);
-- HAMMERORA GO
alter table s_web_order add constraint fk_word_order_date
foreign key (word_order_date) references date_dim(d_date);
-- HAMMERORA GO
alter table s_web_order add constraint fk_word_order_time
foreign key (word_order_time) references time_dim(t_time);
-- HAMMERORA GO
alter table s_web_order add constraint fk_word_ship_mode_id
foreign key (word_ship_mode_id) references ship_mode(sm_ship_mode_id);
-- HAMMERORA GO
alter table s_web_order add constraint fk_word_web_site_id
foreign key (word_web_site_id) references web_site(web_site_id);
-- HAMMERORA GO
-- s_item
alter table s_item add constraint fk_item_item_id
foreign key (item_item_id) references item(i_item_id);
-- HAMMERORA GO
-- s_catalog_order_lineitem
alter table s_catalog_order_lineitem add constraint fk_clin_order_id
foreign key (clin_order_id) references s_catalog_order(cord_order_id);
-- HAMMERORA GO
alter table s_catalog_order_lineitem add constraint fk_clin_item_id
foreign key (clin_item_id) references item(i_item_id);
-- HAMMERORA GO
alter table s_catalog_order_lineitem add constraint fk_clin_promotion_id
foreign key (clin_promotion_id) references promotion(p_promo_id);
-- HAMMERORA GO
alter table s_catalog_order_lineitem add constraint fk_clin_warehouse_id
foreign key (clin_warehouse_id) references warehouse(w_warehouse_id);
-- HAMMERORA GO
-- s_web_order_lineitem
alter table s_web_order_lineitem add constraint fk_wlin_order_id
foreign key (wlin_order_id) references s_web_order(word_order_id);
-- HAMMERORA GO
alter table s_web_order_lineitem add constraint fk_wlin_item_id
foreign key (wlin_item_id) references item(i_item_id);
-- HAMMERORA GO
alter table s_web_order_lineitem add constraint fk_wlin_promotion_id
foreign key (wlin_promotion_id) references promotion(p_promo_id);
-- HAMMERORA GO
alter table s_web_order_lineitem add constraint fk_wlin_warehouse_id
foreign key (wlin_warehouse_id) references warehouse(w_warehouse_id);
-- HAMMERORA GO
alter table s_web_order_lineitem add constraint fk_wlin_ship_date
foreign key (wlin_ship_date) references date_dim(d_date);
-- HAMMERORA GO
alter table s_web_order_lineitem add constraint fk_wlin_ship_date
foreign key (wlin_ship_date) references date_dim(d_date);
-- HAMMERORA GO
alter table s_web_order_lineitem add constraint fk_wlin_web_page_id
foreign key (wlin_web_page_id) references web_page(wp_web_page_id);
-- HAMMERORA GO
-- s_store
alter table s_store add constraint fk_stor_store_id
foreign key (stor_store_id) references store(s_store_id);
-- HAMMERORA GO
alter table s_store add constraint fk_stor_closed_date
foreign key (stor_closed_date) references date_dim(d_date);
-- HAMMERORA GO
-- s_call_center
alter table s_call_center add constraint fk_call_center_id
foreign key (call_center_id) references call_center(cc_center_id);
-- HAMMERORA GO
alter table s_call_center add constraint fk_call_open_date
foreign key (call_open_date) references date_dim(d_date);
-- HAMMERORA GO
alter table s_call_center add constraint fk_call_closed_date
foreign key (call_closed_date) references date_dim(d_date);
-- HAMMERORA GO
-- s_web_site
alter table s_web_site add constraint fk_wsit_web_site_id
foreign key (wsit_web_site_id) references web_site(web_site_id);
-- HAMMERORA GO
alter table s_web_site add constraint fk_web_open_date
foreign key (web_open_date) references date_dim(d_date);
-- HAMMERORA GO
alter table s_web_site add constraint fk_web_closed_date
foreign key (web_closed_date) references date_dim(d_date);
-- HAMMERORA GO
-- s_warehouse
alter table s_warehouse add constraint fk_wrhs_warehouse_id
foreign key (wrhs_warehouse_id) references warehouse(w_warehouse_id);
-- HAMMERORA GO
-- s_web_page
alter table s_web_page add constraint fk_wpag_web_page_id
foreign key (wpag_web_page_id) references web_page(wp_web_page_id);
-- HAMMERORA GO
alter table s_web_page add constraint fk_wpag_create_date
foreign key (wpag_web_create_date) references date_dim(d_date);
-- HAMMERORA GO
alter table s_web_page add constraint fk_wpag_access_date
foreign key (wpag_web_access_date) references date_dim(d_date);
-- HAMMERORA GO
-- s_promotion
alter table s_promotion add constraint fk_prom_start_date
foreign key (prom_start_date) references date_dim(d_date);
-- HAMMERORA GO
alter table s_promotion add constraint fk_prom_end_date
foreign key (prom_end_date) references date_dim(d_date);
-- HAMMERORA GO
-- s_store_returns
alter table s_store_returns add constraint fk_sret_store_id
foreign key (sret_store_id) references s_store(s_store_id);
-- HAMMERORA GO
alter table s_store_returns add constraint fk_sret_customer_id
foreign key (sret_customer_id) references s_customer(s_customer_id);
-- HAMMERORA GO
alter table s_store_returns add constraint fk_sret_return_date
foreign key (sret_return_date) references date_dim(d_date);
-- HAMMERORA GO
alter table s_store_returns add constraint fk_sret_return_time
foreign key (sret_return_time) references time_dim(t_time);
-- HAMMERORA GO
alter table s_store_returns add constraint fk_sret_reason_id
foreign key (sret_reason_id) references reason(r_reason_id);
-- HAMMERORA GO
-- s_catalog_returns
alter table s_catalog_returns add constraint fk_cret_call_center_id
foreign key (cret_call_center_id) references call_center(cc_call_center_id);
-- HAMMERORA GO
alter table s_catalog_returns add constraint fk_cret_item_id
foreign key (cret_item_id) references item(i_item_id);
-- HAMMERORA GO
alter table s_catalog_returns add constraint fk_cret_return_customer_id
foreign key (cret_return_customer_id) references customer(c_customer_id);
-- HAMMERORA GO
alter table s_catalog_returns add constraint fk_cret_refund_customer_id
foreign key (cret_refund_customer_id) references customer(c_customer_id);
-- HAMMERORA GO
alter table s_catalog_returns add constraint fk_cret_return_date
foreign key (cret_return_date) references date_dim(d_date);
-- HAMMERORA GO
alter table s_catalog_returns add constraint fk_cret_return_time
foreign key (cret_return_time) references time_dim(t_time);
-- HAMMERORA GO
alter table s_catalog_returns add constraint fk_cret_reason_id
foreign key (cret_reason_id) references reason(r_reason_id);
-- HAMMERORA GO
-- s_web_returns
alter table s_web_returns add constraint fk_wret_web_page_id
foreign key (wret_web_page_id) references web_page(wp_web_page_id);
-- HAMMERORA GO
alter table s_web_returns add constraint fk_wret_item_id
foreign key (wret_item_id) references item(i_item_id);
-- HAMMERORA GO
alter table s_web_returns add constraint fk_wret_return_customer_id
foreign key (wret_return_customer_id) references customer(c_customer_id);
-- HAMMERORA GO
alter table s_web_returns add constraint fk_wret_refund_customer_id
foreign key (wret_refund_customer_id) references customer(c_customer_id);
-- HAMMERORA GO
alter table s_web_returns add constraint fk_wret_return_date
foreign key (wret_return_date) references date_dim(d_date);
-- HAMMERORA GO
alter table s_web_returns add constraint fk_wret_return_time
foreign key (wret_return_time) references time_dim(t_time);
-- HAMMERORA GO
alter table s_web_returns add constraint fk_wret_reason_id
foreign key (wret_reason_id) references reason(r_reason_id);
-- HAMMERORA GO
-- s_inventory
alter table s_inventory add constraint fk_invn_warehouse_id
foreign key (invn_warehouse_id) references warehouse(w_warehouse_id);
-- HAMMERORA GO
alter table s_inventory add constraint fk_invn_item_id
foreign key (invn_item_id) references item(i_item_id);
-- HAMMERORA GO
alter table s_inventory add constraint fk_invn_return_date
foreign key (invn_return_date) references date_dim(d_date);
-- HAMMERORA GO
-- s_catalog_page
alter table s_catalog_page add constraint fk_cpag_start_date
foreign key (cpag_start_date) references date_dim(d_date);
-- HAMMERORA GO
alter table s_catalog_page add constraint fk_cpag_end_date
foreign key (cpag_end_date) references date_dim(d_date);
-- HAMMERORA GO
