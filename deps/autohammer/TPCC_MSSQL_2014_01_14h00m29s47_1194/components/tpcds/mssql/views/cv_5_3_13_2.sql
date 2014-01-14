-- 5.3.13.2 DM_I
CREATE VIEW itemv AS
SELECT 
--    item_seq i_item_sk,
	item_item_id i_item_id,
	GETDATE() i_rec_start_date,
	cast(NULL as datetime) i_rec_end_date,
	item_item_description i_item_desc,
	item_list_price i_current_price,
	item_wholesale_cost i_cholesalecost,
	i_brand_id,
	i_brand,
	i_class,
	i_category_id,
	i_category,
	i_manufact_id,
	i_manufact,
	item_size isize,
	item_formulation i_formulation,
	item_color i_color,
	item_units i_units,
	item_container i_container,
	item_manager_id imanager,
	i_product_name
FROM s_item
LEFT OUTER JOIN item on (item_item_id = i_item_id and i_rec_end_date is NULL)
-- HAMMERORA GO

