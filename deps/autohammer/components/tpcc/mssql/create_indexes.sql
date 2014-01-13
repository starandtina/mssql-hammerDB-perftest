CREATE UNIQUE CLUSTERED INDEX customer_i1 
       ON customer(c_w_id, c_d_id, c_id);
-- HAMMERORA GO
CREATE UNIQUE NONCLUSTERED INDEX customer_i2 
       ON customer(c_w_id, c_d_id, c_last, c_first, c_id);
-- HAMMERORA GO
CREATE UNIQUE CLUSTERED INDEX district_i1 
       ON district(d_w_id, d_id) WITH FILLFACTOR=100;
-- HAMMERORA GO
CREATE UNIQUE CLUSTERED INDEX item_i1 
       ON item(i_id);
-- HAMMERORA GO
CREATE UNIQUE CLUSTERED INDEX new_order_i1 
       ON new_order(no_w_id, no_d_id, no_o_id);
-- HAMMERORA GO
CREATE UNIQUE CLUSTERED INDEX order_line_i1 
       ON order_line(ol_w_id, ol_d_id, ol_o_id, ol_number);
-- HAMMERORA GO
CREATE UNIQUE CLUSTERED INDEX orders_i1 
       ON orders(o_w_id, o_d_id, o_id);
-- HAMMERORA GO
CREATE INDEX orders_i2 
       ON orders(o_w_id, o_d_id, o_c_id, o_id);
-- HAMMERORA GO
CREATE UNIQUE INDEX stock_i1 
       ON stock(s_i_id, s_w_id);
-- HAMMERORA GO
CREATE UNIQUE CLUSTERED INDEX warehouse_c1 
       ON warehouse(w_id) WITH FILLFACTOR=100;
-- HAMMERORA GO
