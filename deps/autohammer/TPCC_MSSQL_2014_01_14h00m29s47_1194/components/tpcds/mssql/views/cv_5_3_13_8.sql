-- 5.3.13.8 DM_P
CREATE VIEW promv as
SELECT	p_promo_sk,
	prom_promotion_id p_promo_id,
	d1.d_date_sk p_start_date_sk,
	d2.d_date_sk p_end_date_sk,
	p_item_sk,
	prom_cost p_cost,
	prom_response_target p_response_target,
	prom_promotion_name p_promo_name,
	prom_channel_dmail p_channel_dmail,
	prom_channel_email p_channel_email,
	prom_channel_catalog P_channel_catalog,
	prom_channel_tv p_channel_tv,
	prom_channel_radio p_channel_radio,
	prom_channel_press p_channel_ppress,
	prom_channel_event p_channel_event,
	prom_channel_demo p_channel_demo,
	prom_channel_details p_channel_details,
	prom_purpose p_purpose,
	prom_discount_active p_discount_active
FROM s_promotion
LEFT OUTER JOIN date_dim d1 ON (prom_start_date = d1.d_date)
LEFT OUTER JOIN date_dim d2 ON (prom_end_date = d2.d_date)
LEFT OUTER JOIN promotion ON (prom_promotion_id = p_promo_id)
-- HAMMERORA GO
