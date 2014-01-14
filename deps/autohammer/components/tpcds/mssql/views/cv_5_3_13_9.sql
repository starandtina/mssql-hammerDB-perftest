-- 5.3.13.9 DM_WS
CREATE VIEW websv AS
SELECT  
--	web_seq web_site_sk,
	wsit_web_site_id web_site_id,
	GETDATE() web_rec_start_date,
	cast(NULL AS DATE) web_rec_end_date,
	wsit_site_name web_name,
	d1.d_date_sk web_open_date_sk,
	d2.d_date_sk web_close_date_sk,
	wsit_site_class web_class,
	wsit_site_manager web_manager,
	web_mkt_id,
	web_mkt_class,
	web_mkt_desc,
	web_market_manager,
	web_company_id,
	web_company_name,
	web_street_number,
	web_street_name,
	web_street_type,
	web_suite_number,
	web_city,
	web_county,
	web_state,
	web_zip,
	web_country,
	web_gmt_offset,
	wsit_tax_percentage web_tax_percentage
FROM	s_web_site
LEFT OUTER JOIN date_dim d1 on (d1.d_date = cast(wsit_open_date AS DATE))
LEFT OUTER JOIN date_dim d2 on (d2.d_date = cast(wsit_closed_date AS DATE))
LEFT OUTER JOIN web_site on (web_site_id = wsit_web_site_id AND web_rec_end_date IS NULL)
-- HAMMERORA GO
