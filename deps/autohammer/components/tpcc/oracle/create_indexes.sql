alter session set sort_area_size=5000000
-- HAMMERORA GO
CREATE UNIQUE INDEX CUSTOMER_I1 
              ON CUSTOMER ( C_W_ID, C_D_ID, C_ID) 
              INITRANS 4 MAXTRANS 16 PCTFREE 10
-- HAMMERORA GO
CREATE UNIQUE INDEX CUSTOMER_I2 
              ON CUSTOMER ( C_LAST, C_W_ID, C_D_ID, C_FIRST, C_ID) 
              INITRANS 4 MAXTRANS 16 PCTFREE 10
-- HAMMERORA GO
CREATE UNIQUE INDEX DISTRICT_I1 
              ON DISTRICT ( D_W_ID, D_ID) 
              INITRANS 4 MAXTRANS 16 PCTFREE 10
-- HAMMERORA GO
CREATE UNIQUE INDEX ITEM_I1 
              ON ITEM (I_ID) 
              INITRANS 4 MAXTRANS 16 PCTFREE 10
-- HAMMERORA GO
CREATE UNIQUE INDEX ORDERS_I1 
              ON ORDERS (O_W_ID, O_D_ID, O_ID) 
              INITRANS 4 MAXTRANS 16 PCTFREE 10
-- HAMMERORA GO
CREATE UNIQUE INDEX ORDERS_I2 
              ON ORDERS (O_W_ID, O_D_ID, O_C_ID, O_ID) 
              INITRANS 4 MAXTRANS 16 PCTFREE 10
-- HAMMERORA GO
CREATE UNIQUE INDEX STOCK_I1 
              ON STOCK (S_I_ID, S_W_ID) 
              INITRANS 4 MAXTRANS 16 PCTFREE 10
-- HAMMERORA GO
CREATE UNIQUE INDEX WAREHOUSE_I1 
              ON WAREHOUSE (W_ID) 
              INITRANS 4 MAXTRANS 16 PCTFREE 10
-- HAMMERORA GO