CREATE TABLE CUSTOMER (C_ID           NUMBER(5, 0), 
                       C_D_ID         NUMBER(2, 0), 
                       C_W_ID         NUMBER(4, 0), 
                       C_FIRST        VARCHAR2(16), 
                       C_MIDDLE       CHAR(2), 
                       C_LAST         VARCHAR2(16), 
                       C_STREET_1     VARCHAR2(20), 
                       C_STREET_2     VARCHAR2(20), 
                       C_CITY         VARCHAR2(20), 
                       C_STATE        CHAR(2), 
                       C_ZIP          CHAR(9), 
                       C_PHONE        CHAR(16), 
                       C_SINCE        DATE, 
                       C_CREDIT       CHAR(2), 
                       C_CREDIT_LIM   NUMBER(12, 2), 
                       C_DISCOUNT     NUMBER(4, 4), 
                       C_BALANCE      NUMBER(12, 2), 
                       C_YTD_PAYMENT  NUMBER(12, 2), 
                       C_PAYMENT_CNT  NUMBER(8, 0), 
                       C_DELIVERY_CNT NUMBER(8, 0), 
                       C_DATA         VARCHAR2(500)) 
             INITRANS 4 MAXTRANS 16 PCTFREE 10
-- HAMMERORA GO
CREATE TABLE DISTRICT (D_ID        NUMBER(2, 0), 
                       D_W_ID      NUMBER(4, 0), 
                       D_YTD       NUMBER(12, 2), 
                       D_TAX       NUMBER(4, 4), 
                       D_NEXT_O_ID NUMBER, 
                       D_NAME      VARCHAR2(10), 
                       D_STREET_1  VARCHAR2(20), 
                       D_STREET_2  VARCHAR2(20), 
                       D_CITY      VARCHAR2(20), 
                       D_STATE     CHAR(2), 
                       D_ZIP       CHAR(9)) 
             INITRANS 4 MAXTRANS 16 PCTFREE 99
-- HAMMERORA GO
CREATE TABLE HISTORY (H_C_ID   NUMBER, 
                      H_C_D_ID NUMBER, 
                      H_C_W_ID NUMBER, 
                      H_D_ID   NUMBER, 
                      H_W_ID   NUMBER, 
                      H_DATE   DATE, 
                      H_AMOUNT NUMBER(6, 2), 
                      H_DATA   VARCHAR2(24)) 
             INITRANS 4 MAXTRANS 16  PCTFREE 10
-- HAMMERORA GO
CREATE TABLE ITEM (I_ID    NUMBER(6, 0), 
                   I_IM_ID NUMBER, 
                   I_NAME  VARCHAR2(24), 
                   I_PRICE NUMBER(5, 2), 
                   I_DATA  VARCHAR2(50)) 
             INITRANS 4 MAXTRANS 16 PCTFREE 10
-- HAMMERORA GO
CREATE TABLE WAREHOUSE (W_ID       NUMBER(4, 0), 
                        W_YTD      NUMBER(12, 2), 
                        W_TAX      NUMBER(4, 4), 
                        W_NAME     VARCHAR2(10), 
                        W_STREET_1 VARCHAR2(20), 
                        W_STREET_2 VARCHAR2(20), 
                        W_CITY     VARCHAR2(20), 
                        W_STATE    CHAR(2), 
                        W_ZIP      CHAR(9)) 
             INITRANS 4 MAXTRANS 16 PCTFREE 99
-- HAMMERORA GO
CREATE TABLE STOCK (S_I_ID       NUMBER(6, 0), 
                    S_W_ID       NUMBER(4, 0), 
                    S_QUANTITY   NUMBER(6, 0), 
                    S_DIST_01    CHAR(24), 
                    S_DIST_02    CHAR(24), 
                    S_DIST_03    CHAR(24), 
                    S_DIST_04    CHAR(24), 
                    S_DIST_05    CHAR(24), 
                    S_DIST_06    CHAR(24), 
                    S_DIST_07    CHAR(24), 
                    S_DIST_08    CHAR(24), 
                    S_DIST_09    CHAR(24), 
                    S_DIST_10    CHAR(24), 
                    S_YTD        NUMBER(10, 0), 
                    S_ORDER_CNT  NUMBER(6, 0), 
                    S_REMOTE_CNT NUMBER(6, 0), 
                    S_DATA       VARCHAR2(50)) 
             INITRANS 4 MAXTRANS 16 PCTFREE 10
-- HAMMERORA GO
CREATE TABLE NEW_ORDER (NO_W_ID NUMBER, 
                        NO_D_ID NUMBER, 
                        NO_O_ID NUMBER, 
                        CONSTRAINT INORD PRIMARY KEY (NO_W_ID, NO_D_ID, NO_O_ID) ENABLE ) 
              ORGANIZATION INDEX NOCOMPRESS INITRANS 4 MAXTRANS 16 PCTFREE 10
-- HAMMERORA GO
CREATE TABLE ORDERS (O_ID         NUMBER, 
                     O_W_ID       NUMBER, 
                     O_D_ID       NUMBER, 
                     O_C_ID       NUMBER, 
                     O_CARRIER_ID NUMBER, 
                     O_OL_CNT     NUMBER, 
                     O_ALL_LOCAL  NUMBER, 
                     O_ENTRY_D    DATE) 
             INITRANS 4 MAXTRANS 16 PCTFREE 10
-- HAMMERORA GO
CREATE TABLE ORDER_LINE (OL_W_ID NUMBER, 
                         OL_D_ID NUMBER, 
                         OL_O_ID NUMBER, 
                         OL_NUMBER NUMBER, 
                         OL_I_ID NUMBER, 
                         OL_DELIVERY_D DATE, 
                         OL_AMOUNT NUMBER, 
                         OL_SUPPLY_W_ID NUMBER, 
                         OL_QUANTITY NUMBER, 
                         OL_DIST_INFO CHAR(24), 
                         CONSTRAINT IORDL PRIMARY KEY (OL_W_ID, OL_D_ID, OL_O_ID, OL_NUMBER) ENABLE) 
             ORGANIZATION INDEX NOCOMPRESS INITRANS 4 MAXTRANS 16 PCTFREE 10
-- HAMMERORA GO
