-- 5.3.13.10 DM_WP
CREATE VIEW webv AS
SELECT 
--	wp_seq wp_web_age_sk,
	wpag_web_page_id wp_web_page_id,
	GETDATE() wp_rec_start_date,
	cast(NULL as date) wp_rec_end_date,
	d1.d_date_sk wp_creation_date_sk,
	d2.d_date_sk wp_access_date_sk,
	wpag_autogen_flag wp_autogen_flag,
	wp_customer_sk,
	wpag_url wp_url,
	wpag_type wp_type,
	wpag_char_cnt wp_char_count,
	wpag_link_cnt wp_link_count,
	wpag_image_cnt wp_image_count,
	wpag_max_ad_cnt wp_max_ad_count
FROM	s_web_page
LEFT OUTER JOIN date_dim d1 ON cast(wpag_create_date as DATE) = d1.d_date
LEFT OUTER JOIN date_dim d2 ON cast(wpag_access_date as DATE) = d2.d_date
LEFT OUTER JOIN web_page ON (wpag_web_page_id = wp_web_page_id AND wp_rec_end_date is null);
-- HAMMERORA GO
