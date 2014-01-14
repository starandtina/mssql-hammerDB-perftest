-- Defined relationships
-- 
-- Source Schema Table 1  | Source Schema Table 2    | Join Condition
--  s_purchase            | s_purchase_lineitem      | purch_purchase_id = plin_purchase_id
--  s_web_order           | s_web_order_lineitem     | word_order_id = wlin_order_id
--  s_catalog_order       | s_catalog_order_lineitem | cord_order_id = clin_order_id
-- 
create table dbo.s_zip_to_gmt (
                zipg_zip                char(5) not null,
                zipg_gmt_offset         bigint  not null);  
-- HAMMERORA GO
create table dbo.s_purchase_lineitem (
                plin_purchase_id        bigint  not null,
                plin_line_number        bigint  not null,
                plin_item_id            char(16),
                plin_promotion_id       char(16),
                plin_quantity           bigint,
                plin_sale_price         decimal(7,2),
                plin_coupon_amt         decimal(7,2),
                plin_comment            char(100));
-- HAMMERORA GO
create table dbo.s_customer (
                cust_customer_id        bigint not null,
                cust_salutation         char(10),
                cust_first_name         char(20),
                cust_last_name          char(30),
                cust_preferred_flag     char(1),
                cust_birth_date         char(10),
                cust_birth_country      varchar(20),
                cust_login_id           char(13),
                cust_email_address          char(50),
                cust_last_login_chg_date char(10),
                cust_first_shipto_date  char(10),
                cust_first_purchase_date    char(10),
                cust_last_review_date   char(10),
                cust_primary_machine_id char(15),
                cust_secondary_machine_id   char(15),
                cust_street_number          char(10),
                cust_suite_number           char(10),
                cust_street_name1           char(30),
                cust_street_name2           char(30),
                cust_street_type            char(15),
                cust_city                   char(60),
                cust_zip                    char(10),
                cust_county                 char(30),
                cust_state                  char(2),
                cust_country                char(20),
                cust_loc_type               char(20),
                cust_gender                 char(1),
                cust_marital_status         char(1),
                cust_educ_status            char(20),
                cust_credit_rating          char(10),
                cust_purch_est              decimal(7,2),
                cust_buy_potential          char(15),
                cust_depend_cnt             bigint,
                cust_depend_emp_cnt         bigint,
                cust_depend_college_cnt     bigint,
                cust_vehicle_cnt            bigint,
                cust_annual_income          decimal(9,2));
-- HAMMERORA GO
create table dbo.s_purchase (
                purc_purchase_id            bigint not null,
                purc_store_id               char(16),
                purc_customer_id            char(16),
                purc_purchase_date          char(10),
                purc_purchase_time          bigint,
                purc_register_id            bigint,
                purc_clerk_id               bigint,
                purc_comment                char(100));
-- HAMMERORA GO
create table dbo.s_catalog_order (
                cord_order_id               bigint not null,
                cord_bill_customer_id       char(16),
                cord_ship_customer_id       char(16),
                cord_order_date             char(10),
                cord_order_time             bigint,
                cord_ship_mode_id           char(16),
                cord_call_center_id         char(16),
                cord_order_comments         varchar(100));
-- HAMMERORA GO
create table dbo.s_web_order (
                word_order_id               bigint not null,
                word_bill_customer_id       char(16),
                word_ship_customer_id       char(16),
                word_order_date             char(10),
                word_order_time             bigint,
                word_ship_mode_id           char(16),
                word_web_site_id            char(16),
                word_order_comments         char(100));
-- HAMMERORA GO
create table dbo.s_item (
                item_item_id                char(16) not null,
                item_item_description       char(200),
                item_list_price             decimal(7,2),
                item_wholesale_cost         decimal(7,2),
                item_size                   char(20),
                item_formulation            char(20),
                item_color                  char(20),
                item_units                  char(10),
                item_container              char(10),
                item_manager_id             bigint);
-- HAMMERORA GO
create table dbo.s_catalog_order_lineitem (
                clin_order_id               bigint not null,
                clin_line_number            bigint,
                clin_item_id                char(16),
                clin_promotion_id           char(16),
                clin_quantity               bigint,
                clin_sales_price            decimal(7,2),
                clin_coupon_amt             decimal(7,2),
                clin_warehouse_id           char(16),
                clin_ship_date              char(10),
                clin_catalog_number         bigint,
                clin_catalog_page_number    bigint,
                clin_ship_cost              decimal(7,2));
-- HAMMERORA GO
create table dbo.s_web_order_lineitem (
                wlin_order_id               bigint not null,
                wlin_line_number            bigint not null,
                wlin_item_id                char(16),
                wlin_promotion_id           char(16),
                wlin_quantity               bigint,
                wlin_sales_price            decimal(7,2),
                wlin_coupon_amt             decimal(7,2),
                wlin_warehouse_id           char(16),
                wlin_ship_date              char(10),
                wlin_ship_cost              decimal(7,2),
                wlin_web_page_id            char(16));
-- HAMMERORA GO
create table dbo.s_store (
                stor_store_id               char(16) not null,
                stor_closed_date            char(10),
                stor_name                   char(50),
                stor_employees              bigint,
                stor_floor_space            bigint,
                stor_hours                  char(20),
                stor_store_manager          char(40),
                stor_market_id              bigint,
                stor_geography_class        char(100),
                stor_market_manager         char(40),
                stor_tax_percentage         decimal(5,2));
-- HAMMERORA GO
create table dbo.s_call_center (
                call_center_id              char(16) not null,
                call_open_date              char(10),
                call_closed_date            char(10),
                call_center_name            char(50),
                call_center_class           char(50),
                call_center_employees       bigint,
                call_center_sq_ft           bigint,
                call_center_hours           char(20),
                call_center_manager         char(40),
                call_center_tax_percentage  decimal(7,2));
-- HAMMERORA GO
create table dbo.s_web_site (
                wsit_web_site_id            char(16) not null,
                wsit_open_date              char(10),
                wsit_closed_date            char(10),
                wsit_site_name              char(50),
                wsit_site_class             char(50),
                wsit_site_manager           char(40),
                wsit_tax_percentage         decimal(5,2));
-- HAMMERORA GO
create table dbo.s_warehouse (
                wrhs_warehouse_id           char(16) not null,
                wrhs_warehouse_desc         char(200),
                wrhs_warehouse_sq_ft        bigint);
-- HAMMERORA GO
create table dbo.s_web_page (
                wpag_web_page_id            char(16) not null,
                wpag_create_date            char(10),
                wpag_access_date            char(10),
                wpag_autogen_flag           char(1),
                wpag_url                    char(100),
                wpag_type                   char(50),
                wpag_char_cnt               bigint,
                wpag_link_cnt               bigint,
                wpag_image_cnt              bigint,
                wpag_max_ad_cnt             bigint);
-- HAMMERORA GO
create table dbo.s_promotion (
                prom_promotion_id           char(16) not null,
                prom_promotion_name         char(30),
                prom_start_date             char(10),
                prom_end_date               char(10),
                prom_cost                   decimal(7,2),
                prom_response_target        char(1),
                prom_channel_dmail          char(1),
                prom_channel_email          char(1),
                prom_channel_catalog        char(1),
                prom_channel_tv             char(1),
                prom_channel_radio          char(1),
                prom_channel_press          char(1),
                prom_channel_event          char(1),
                prom_channel_demo           char(1),
                prom_channel_details        char(100),
                prom_purpose                char(15),
                prom_discount_active        char(1));
-- HAMMERORA GO
create table dbo.s_store_returns (
                sret_store_id               char(16),
                sret_purchase_id            char(16) not null,
                sret_line_number            bigint not null,
                sret_item_id                char(16) not null,
                sret_customer_id            char(16),
                sret_return_date            char(10),
                sret_return_time            char(10),
                sret_ticket_number          char(20),
                sret_return_qty             bigint,
                sret_return_amt             decimal(7,2),
                sret_return_tax             decimal(7,2),
                sret_return_fee             decimal(7,2),
                sret_return_ship_cost       decimal(7,2),
                sret_refunded_cash          decimal(7,2),
                sret_reversed_charge        decimal(7,2),
                sret_store_credit           decimal(7,2),
                sret_reason_id              char(16));
-- HAMMERORA GO
create table dbo.s_catalog_returns (
                cret_call_center_id         char(16),
                cret_order_id               bigint not null,
                cret_line_number            bigint not null,
                cret_item_id                char(16) not null,
                cret_return_customer_id     char(16),
                cret_refund_customer_id     char(16),
                cret_return_date            char(10),
                cret_return_time            char(10),
                cret_return_qty             bigint,
                cret_return_amt             decimal(7,2),
                cret_return_tax             decimal(7,2),
                cret_return_fee             decimal(7,2),
                cret_return_ship_cost       decimal(7,2),
                cret_refunded_cash          decimal(7,2),
                cret_reversed_charge        decimal(7,2),
                cret_merchant_credit        decimal(7,2),
                cret_reason_id              char(16),
                cret_shipmode_id            char(16),
                cret_catalog_page_id        char(16),
                cret_warehouse_id           char(16));
-- HAMMERORA GO
create table dbo.s_web_returns (
                wret_web_page_id            char(16),
                wret_order_id               bigint not null,
                wret_line_number            bigint not null,
                wret_item_id                char(16) not null,
                wret_return_customer_id     char(16),
                wret_refund_customer_id     char(16),
                wret_return_date            char(10),
                wret_return_time            char(10),
                wret_return_qty             bigint,
                wret_return_amt             decimal(7,2),
                wret_return_tax             decimal(7,2),
                wret_return_fee             decimal(7,2),
                wret_return_ship_cost       decimal(7,2),
                wret_refunded_cash          decimal(7,2),
                wret_reversed_charge        decimal(7,2),
                wret_account_credit         decimal(7,2),
                wret_reason_id              char(16));
-- HAMMERORA GO
create table dbo.s_inventory (
                invn_warehouse_id           char(16) not null,
                invn_item_id                char(16) not null,
                invn_date                   char(10) not null,
                invn_qty_on_hand           bigint);
-- HAMMERORA GO
create table dbo.s_catalog_page (
                cpag_catalog_number         bigint not null,
                cpag_catalog_page_number    bigint not null,
                cpag_department             char(20),
                cpag_id                     char(16),
                cpag_start_date             char(10),
                cpag_end_date               char(10),
                cpag_description            varchar(100),
                cpag_type                   varchar(100));
