create table dbo.customer (c_id int,
                           c_d_id tinyint, 
                           c_w_id int, 
			   c_discount smallmoney, 
			   c_credit_lim money, 
			   c_first char(16), 
			   c_middle char(2), 
			   c_last char(16), 
			   c_credit char(2), 
			   c_balance money, 
			   c_ytd_payment money, 
			   c_payment_cnt smallint, 
			   c_delivery_cnt smallint, 
			   c_street_1 char(20), 
			   c_street_2 char(20), 
			   c_city char(20), 
			   c_state char(2), 
			   c_zip char(9), 
			   c_phone char(16), 
			   c_since datetime, 
			   c_data char(500));
-- HAMMERORA GO
create table dbo.district (d_id tinyint, 
	                   d_w_id int, 
			   d_ytd money, 
			   d_next_o_id int, 
			   d_tax smallmoney, 
			   d_name char(10), 
			   d_street_1 char(20), 
			   d_street_2 char(20), 
			   d_city char(20), 
			   d_state char(2), 
			   d_zip char(9));
-- HAMMERORA GO
create table dbo.history (h_c_id int, 
	                  h_c_d_id tinyint, 
			  h_c_w_id int, 
			  h_d_id tinyint, 
			  h_w_id int, 
			  h_date datetime, 
			  h_amount smallmoney, 
			  h_data char(24));
-- HAMMERORA GO
create table dbo.item (i_id int, 
	               i_name char(24), 
		       i_price smallmoney, 
		       i_data char(50), 
		       i_im_id int);
-- HAMMERORA GO
create table dbo.new_order (no_o_id int, 
	                    no_d_id tinyint, 
			    no_w_id int);
-- HAMMERORA GO
create table dbo.order_line (ol_o_id int, 
	                     ol_d_id tinyint, 
			     ol_w_id int, 
			     ol_number tinyint, 
			     ol_i_id int, 
			     ol_delivery_d datetime, 
			     ol_amount smallmoney, 
			     ol_supply_w_id int, 
			     ol_quantity smallint, 
			     ol_dist_info char(24));
-- HAMMERORA GO
create table orders (o_id int, 
	             o_d_id tinyint, 
		     o_w_id int, 
		     o_c_id int, 
		     o_carrier_id tinyint, 
		     o_ol_cnt tinyint, 
		     o_all_local tinyint, 
		     o_entry_d datetime);
-- HAMMERORA GO
create table stock (s_i_id int, 
	            s_w_id int, 
		    s_quantity smallint, 
		    s_ytd int, 
		    s_order_cnt smallint, 
		    s_remote_cnt smallint, 
		    s_data char(50), 
		    s_dist_01 char(24), 
		    s_dist_02 char(24), 
		    s_dist_03 char(24), 
		    s_dist_04 char(24), 
		    s_dist_05 char(24), 
		    s_dist_06 char(24), 
		    s_dist_07 char(24), 
		    s_dist_08 char(24), 
		    s_dist_09 char(24), 
		    s_dist_10 char(24));
-- HAMMERORA GO
create table dbo.warehouse(w_id int, 
	                   w_ytd money, 
			   w_tax smallmoney, 
			   w_name char(10), 
			   w_street_1 char(20), 
			   w_street_2 char(20), 
			   w_city char(20), 
			   w_state char(2), 
			   w_zip char(9));
-- HAMMERORA GO
