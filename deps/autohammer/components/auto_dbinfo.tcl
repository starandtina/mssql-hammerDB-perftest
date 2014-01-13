#  Copyright Timothy D. Witham 2012
#  Distributed under GPL 2.2
#
#
# Routines to dump configuration information into files
#
#
#
#
# Start of main
#
# usage: sysdb_info.tcl rdbms connect_string user/database directory
#

proc MSSQL_params {log_id connect} {
set sec_name "mssql"
set sql(1) "EXEC sp_configure 'show advanced options', 1" 
set sql(2) "GO"
set sql(3) "RECONFIGURE WITH OVERRIDE"
set sql(4) "EXEC sp_configure"
	set xlevel 0
	puts $log_id "<?xml version=\"1.0\" encoding=\"utf-8\"?>"
	Enter_log_tag $log_id "S" $sec_name 0 xlevel

	if {[catch {database db $connect} err] == 1} {
    	Enter_log_item $tlog_id "ERROR" [format "Couldn't connect MSSQL ===\n%s\n===" $connect] 1
        Enter_log_item $tlog_id "SQLERROR" [format "%s" $err] 1
        Put_thread_footer $tlog_id $sec_name
		return
    } 
    db "USE master"
	db "EXEC sp_configure 'show advanced options', 1"
	db "RECONFIGURE WITH OVERRIDE"
	db statement info_conf "EXEC sp_configure"
	info_conf execute
	while {[set output [info_conf fetch]] != {}} {
		set param_name [string map {{ } _} [lindex $output 0]] 
		set param_name [string map {{/} _} $param_name] 
		Enter_log_tag $log_id "S" "rdbms_param" 0 xlevel

		Enter_log_item $log_id "name"         [lindex $output 0]  $xlevel
		Enter_log_item $log_id "mimimum"      [lindex $output 1]  $xlevel
		Enter_log_item $log_id "maximum"      [lindex $output 2]  $xlevel
		Enter_log_item $log_id "config_value" [lindex $output 3]  $xlevel
		Enter_log_item $log_id "run_value"    [lindex $output 4]  $xlevel

		Enter_log_tag $log_id "E" "rdbms_param" 0 xlevel
		flush $log_id
	}
	Enter_log_tag $log_id "E" $sec_name 0 xlevel
	flush $log_id
	db commit
	db disconnect
	return

}

proc Oracle_params {log_id sysconnect database_name} {
set sec_name "oracle"
set sql(1) "select * from v\$sgainfo"
set sql(2) "select * from v\$sga_dynamic_components"

	set xlevel 0
	puts $log_id "<?xml version=\"1.0\" encoding=\"utf-8\"?>"
	Enter_log_tag $log_id "S" $sec_name 0 xlevel

	DB_use $log_id $sec_name "oracle" $database_name $sysconnect dbhandle dbcur

	Enter_log_tag $log_id "S" "sgainfo" 0 xlevel
	set sql_return [RDBMS_sql "oracle" $log_id $sec_name 0 $dbcur "select * from v\$sgainfo" "" 0 0 0]

	while (1) {
		set code [orafetch $dbcur -datavariable output]
		if {$code != 0 } break
		set param_name [string map {{ } _} [lindex $output 0]] 

		Enter_log_tag $log_id "S" "rdbms_param" 0 xlevel
		Enter_log_item $log_id "name" [lindex $output 0]  $xlevel
		Enter_log_item $log_id "bytes" [lindex $output 1]  $xlevel
		Enter_log_item $log_id "res" [lindex $output 2]  $xlevel

		Enter_log_tag $log_id "E" "rdbms_param" 0 xlevel
	}
	Enter_log_tag $log_id "E" "sgainfo" 0 xlevel

	Enter_log_tag $log_id "S" "sga_dynamic_components" 0 xlevel
	RDBMS_sql "oracle" $log_id $sec_name 0 $dbcur "select * from v\$sga_dynamic_components" "" 0 0 0
	while (1) {
		set code [orafetch $dbcur -datavariable output]
		if {$code != 0 } break
		set param_name [string map {{ } _} [lindex $output 0]] 
		Enter_log_tag $log_id "S" "rdbms_param" 0 xlevel
		Enter_log_item $log_id "name" [lindex $output 0]  $xlevel
		Enter_log_item $log_id "current_size" [lindex $output 1]  $xlevel
		Enter_log_item $log_id "min_size" [lindex $output 2]  $xlevel
		Enter_log_item $log_id "max_size" [lindex $output 3]  $xlevel
		Enter_log_item $log_id "user_specified_size" [lindex $output 4]  $xlevel
		Enter_log_item $log_id "oper_count" [lindex $output 5]  $xlevel
		Enter_log_item $log_id "last_oper_type" [lindex $output 6]  $xlevel
		Enter_log_item $log_id "last_oper" [lindex $output 7]  $xlevel
		Enter_log_item $log_id "last_oper_time" [lindex $output 8]  $xlevel
		Enter_log_item $log_id "grandule_size" [lindex $output 9]  $xlevel
		Enter_log_tag $log_id "E" "rdbms_param" 0 xlevel
		flush $log_id
	}

	Enter_log_tag $log_id "E" "sga_dynamic_components" 0 xlevel
	Enter_log_tag $log_id "E" $sec_name                0 xlevel
	flush $log_id
	
	oracommit $dbhandle
	oraclose  $dbcur
	oralogoff $dbhandle
}

proc Count_tpch {log_dir rdbms database_name connect sf} {
set stmt_cnt 8
set sec_name "tpch_table_ratios"
set dbhandle "NULL"
set dbcur    "NULL"
set hodbc    "db_main"

set sql(1) "SELECT COUNT(r_name)     FROM region"
set sql(2) "SELECT COUNT(n_name)     FROM nation"
set sql(3) "SELECT COUNT(s_name)     FROM supplier"
set sql(4) "SELECT COUNT(c_name)     FROM customer"
set sql(5) "SELECT COUNT(p_name)     FROM part"
set sql(6) "SELECT COUNT(ps_partkey) FROM partsupp"
set sql(7) "SELECT COUNT(o_custkey)  FROM orders"
set sql(8) "SELECT COUNT(l_shipdate) FROM lineitem"

set ecnt(1) 5.0
set ecnt(2) 25.0
set ecnt(3) 10000.0
set ecnt(4) 150000.0
set ecnt(5) 200000.0
set ecnt(6) 800000.0
set ecnt(7) 1500000.0
set ecnt(8) 6000000.0

set escale(1) 0
set escale(2) 0
set escale(3) 1
set escale(4) 1
set escale(5) 1
set escale(6) 1
set escale(7) 1
set escale(8) 1


set xmltag(1) "REGION"
set xmltag(2) "NATION"
set xmltag(3) "SUPPLIER"
set xmltag(4) "CUSTOMER"
set xmltag(5) "PART"
set xmltag(6) "PARTSUPP"
set xmltag(7) "ORDERS"
set xmltag(8) "LINEITEM"

	set log_file [file join $log_dir "tpch_info.xml"]
	if [catch {open $log_file w} log_id ] {
		puts stderr [format "ERROR: Unable to create ==%s==" $log_file" ]
		exit
	}

	DB_use $log_id $sec_name "test" $rdbms $database_name $connect $hodbc dbhandle dbcur

	set xlevel 0
	puts $log_id "<?xml version=\"1.0\" encoding=\"utf-8\"?>"
	Enter_log_tag $log_id "S" $sec_name 0 xlevel

	for {set i 1 } { $i <= $stmt_cnt } { incr i } {
		set db_cnt [RDBMS_sql $rdbms $log_id $sec_name 0 $hodbc $dbcur $sql($i) "" 1 0 1]
		if {$escale($i) } {
			set results [expr {$db_cnt / ($sf * $ecnt($i))} ]
		} else {
			set results [expr {$db_cnt/$ecnt($i)} ]
		}

		#set results [expr {$db_cnt/$factor} ]
		Enter_log_tag $log_id "S" $xmltag($i) 0 xlevel
		incr xlevel
		Enter_log_item $log_id "count" $db_cnt  $xlevel
		Enter_log_item $log_id "ratio" $results $xlevel
		incr xlevel -1
		Enter_log_tag $log_id "E" $xmltag($i) 0 xlevel
	}

	Commit_sql $log_id $rdbms $hodbc $dbhandle $sec_name 0 $xlevel

	Enter_log_tag $log_id "E" $sec_name 0 xlevel
	flush $log_id
	close $log_id

}

proc Count_tpcc {log_dir rdbms database_name connect wh} {
set stmt_cnt 9
set sec_name "tpcc_table_ratios"
set dbhandle "NULL"
set dbcur    "NULL"
set hodbc    "db_main"


set sql(1) "SELECT COUNT(c_id)    FROM customer"
set sql(2) "SELECT COUNT(d_id)    FROM district"
set sql(3) "SELECT COUNT(h_c_id)  FROM history"
set sql(4) "SELECT COUNT(i_id)    FROM item"
set sql(5) "SELECT COUNT(no_o_id) FROM new_order"
set sql(6) "SELECT COUNT(ol_o_id) FROM order_line"
set sql(7) "SELECT COUNT(o_id)    FROM orders"
set sql(8) "SELECT COUNT(s_i_id)  FROM stock"
set sql(9) "SELECT COUNT(w_id)    FROM warehouse"

set ecnt(1) [expr {$wh*30000.0 }]
set ecnt(2) [expr {$wh*10.0 } ]
set ecnt(3) [expr {$wh*30000.0 } ]
set ecnt(4) 100000.0
set ecnt(5) [expr {$wh*9000.0 } ]
set ecnt(6) [expr {$wh*300000.0 } ]
set ecnt(7) [expr {$wh*30000.0 } ]
set ecnt(8) [expr {$wh*100000.0 } ]
set ecnt(9) [expr {$wh*1.0 } ]

set xmltag(1) "Customer"
set xmltag(2) "District"
set xmltag(3) "History"
set xmltag(4) "Item"
set xmltag(5) "New_Order"
set xmltag(6) "Order_Line"
set xmltag(7) "Order_Line"
set xmltag(8) "Stock"
set xmltag(9) "Warehouse"

	set log_file [file join $log_dir "tpcc_info.xml" ]
	if [catch {open $log_file w} log_id ] {
		puts stderr [format "ERROR: Unable to create ==%s==" $log_file" ]
		exit
	}

	DB_use $log_id $sec_name "test" $rdbms $database_name $connect $hodbc dbhandle dbcur

	set xlevel 0
	puts $log_id "<?xml version=\"1.0\" encoding=\"utf-8\"?>"
	Enter_log_tag $log_id "S" $sec_name 0 xlevel

	for {set i 1 } { $i <= $stmt_cnt } { incr i } {
		set db_cnt [RDBMS_sql $rdbms $log_id $sec_name 0 $hodbc $dbcur $sql($i) "" 1 0 1]
		set results [expr {$db_cnt/$ecnt($i)} ]
		Enter_log_tag $log_id "S" $xmltag($i) 0 xlevel
		Enter_log_item $log_id "count" $db_cnt  $xlevel
		Enter_log_item $log_id "ratio" $results $xlevel
		Enter_log_tag $log_id "E" $xmltag($i) 0 xlevel
	}

	Commit_sql $log_id $rdbms $hodbc $dbhandle $sec_name 0 $xlevel

	Enter_log_tag $log_id "E" $sec_name 0 xlevel
	flush $log_id
	close $log_id

}
