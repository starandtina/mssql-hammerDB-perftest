#
#  Copyright Steve Shaw 2003-2012
#  Copyright Timothy D. Witham 2012
#  Distributed under GPL 2.2
#
#
# Routine to generate the MS SQL connect string from the set parameters
#
# This should end up in the mssql_run.tcl file
#

proc MSSQL_connect_string { log_id server port odbc_driver authentication uid pwd } {
	if {[ string toupper $authentication ] eq "WINDOWS" } { 
		if {[ string match -nocase {*native*} $odbc_driver ] } { 
			set connection "DRIVER=$odbc_driver;SERVER=$server;PORT=$port;TRUSTED_CONNECTION=YES"
		} else {
			set connection "DRIVER=$odbc_driver;SERVER=$server;PORT=$po<log file id> rt"
 		}
	} else {
		if {[ string toupper $authentication ] eq "SQL" } {
			set connection "DRIVER=$odbc_driver;SERVER=$server;PORT=$port;UID=$uid;PWD=$pwd"
 		} else {
			Enter_log_item "WARNING" "Neither WINDOWS or SQL Authentication has been specified" 1
			set connection "DRIVER=$odbc_driver;SERVER=$server;PORT=$port"
 		}
	}
	return $connection
}

proc Oracle_connect_string { server  admin admin_pass test_user test_pass connect sysconnect } {
	upvar $connect    l_connect
	upvar $sysconnect l_sysconnect
	set l_connect    [format "%s/%s@%s" $test_user $test_pass  $server]
	set l_sysconnect [format "%s/%s@%s" $admin     $admin_pass $server]
}

proc Connect_to_MSSQL { log_id hodbc server port ODBC_driver authentication server_ID server_pass xlevel} { 
global rdbms_info f_info xml_info 
	set rdbms_info(connect) [MSSQL_connect_string  $log_id $server $port $ODBC_driver $authentication $server_ID $server_pass]

	if {[catch {database $hodbc $rdbms_info(connect)} err] == 1} {
		Enter_log_item $f_info(log_id) "ERROR" [format "Couldn't connect MSSQL ==\n%s\n==" $rdbms_info(connect)] 2
		Error_out $f_info(log_id) "connect_to_MSSQL"
	}
	Enter_log_item $log_id "MSSQL_connected" $rdbms_info(connect) $xlevel

}

proc Disconnect_from_DB {log_id rdbms hodbc dbhandle xlevel} {

	set sk [string tolower $rdbms]
	switch $sk {
	mssql {
		Enter_log_tag $log_id "S" "disconnect_from_MSSQL" 1 xlevel
		$hodbc commit
		$hodbc disconnect
		Enter_log_tag $log_id "E" "disconnect_from_MSSQL" 1 xlevel
		return
	      }
	oracle {
		Enter_log_tag $log_id "S" "disconnect_from_Oracle" 1 xlevel
		oracommit $dbhandle
		oralogoff $dbhandle
		Enter_log_tag $log_id "E" "disconnect_from_Oracle" 1 xlevel
		return
 	       }
	pgsql {
		Enter_log_tag $log_id "S" "disconnect_from_PostgreSQL" 1 xlevel
		puts "Not really disconnected need to insert PGSQL disconnnect"
		Enter_log_tag $log_id "E" "disconnect_from_PostgreSQL" 1 xlevel
		return
 	       }
	mysql {
		Enter_log_tag $log_id "S" "disconnect_from_MySQL" 1 xlevel
		puts "Not really disconnected need to insert MySQL disconnnect"
		Enter_log_tag $log_id "E" "disconnect_from_MySQL" 1 xlevel
		return
 	       }
      }
}
#
# Oracle Gather Statistics
#
proc GatherStatistics { lda tpcc_user } {
	puts "GATHERING SCHEMA STATISTICS"
	set curn1 [ oraopen $lda ]
	set sql(1) "BEGIN dbms_stats.gather_schema_stats('$tpcc_user'); END;"
	if {[ catch {orasql $curn1 $sql(1)} message ] } {
		puts "$message $sql(1)"
		puts [ oramsg $curn1 all ]
	}
	oraclose $curn1
	return
}

proc Set_db_date_fun {rdbms} {
	set sk [string tolower $rdbms]
	switch $sk {
		mssql   { set db_date "getdate()"  }
		oracle  { set db_date "sysdate"  }
		pgsql   { puts "Need to find the sysdate for PostgreSQL" }
		mysql   { puts "Need to find the sysdate for PostgreSQL" }
	}
}

proc Auto_on_off {rdbms hodbc dbhandle action} {
        set sk [string tolower $rdbms]
        switch $sk {
		mssql  {
			if {$action == "on"} {
				$hodbc set autocommit on
			} else {
				$hodbc set autocommit off
			}
		       }
		oracle {
			if {$action == "on"} {
				#oraautocon $dbhandle on
			} else {
				#oraautocon $dbhandle on	
			}
		       }
		pgsql  {
			if {$action == "on"} {
				puts "Need to be able to turn PostgreSQL autocommit on"
				#db autocommit on
			} else {
				puts "Need to be able to turn PostgreSQL autocommit off"
				#db autocommit off
			}
		       }
		mysql  {
			if {$action == "on"} {
				puts "Need to be able to turn MySQL autocommit on"
				#db autocommit on
			} else {
				puts "Need to be able to turn MySQL autocommit off"
				#db autocommit off
			}
		       }
	       }
}

proc Commit_sql {log_id rdbms hodbc dbhandle sec_name verbose level} { 
	set sk [string tolower $rdbms]
    switch $sk {
        mssql  {   
                $hodbc commit 
				if {$verbose == 1} {
                  	Enter_log_item $log_id "MSSQLcommit" "" $level
				}
        }   
        oracle { 
                oracommit $dbhandle 
			    if {$verbose == 1} {
                   	Enter_log_item $log_id "Oracle_commit" "" $level
				}
		}   
        pgsql  {   
                puts "NEED TO ADD commit FOR PostgreSQL" 
				if {$verbose == 1} {
                   	Enter_log_item $log_id "PostgreSQL_commit" "" $level
				}
        }   
        mysql  {   
               	puts "NEED TO ADD commit FOR MySQL" 
				if {$verbose == 1} {
                  	Enter_log_item $log_id "MySQL_commit" "" $level
				}
        }   
	}
}

proc DB_use {log_id sec_name use_db rdbms database_name connect hodbc dbhandle dbcur} {
	upvar 1 $dbhandle l_dbhandle 
	upvar 1 $dbcur    l_dbcur
	set l_dbhandle "NOT USED"
	set l_dbcur    "NOT USED"
        set sk [string tolower $rdbms]
        switch $sk {
            mssql  {   
	        	if {[catch {database $hodbc $connect} err] == 1} {
	                	Enter_log_item $log_id "ERROR" [format "Couldn't connect MSSQL ===\n%s\n===" $connect] 1
	                	Enter_log_item $log_id "SQLERROR" [format "%s" $err] 1
	                	Put_thread_footer $log_id $sec_name
	                	set r_id [thread::id]
	                	thread::release
	        	}           
	        	if {$use_db == "test" } {$hodbc [format "USE %s;" $database_name] }
		    }
            oracle { 
				set woof [catch [set l_dbhandle [oralogon $connect]]]
				if {[oramsg $l_dbhandle rc] != 0} {
					Enter_log_item $log_id "ERROR" [oramsg error] 1
	           		set r_id [thread::id]
	           		thread::release
					Error_out $log_id $sec_name 1
				}
				set l_dbcur [oraopen $l_dbhandle]
				if {[oramsg $l_dbhandle rc] !=0} {
					Enter_log_item $log_id "ERROR" [format "%s" [oramsg $l_dbhandle error]] 1
					Error_out $log_id $sec_name
				}
            }   
            pgsql  {   
                        puts "NEED TO ADD DB_use FOR PostgreSQL" 
            }   
            mysql  {   
                        puts "NEED TO ADD DB_use FOR MySQL" 
            }   
	       }
}

proc RDBMS_sql { rdbms log_id sec_name sql_sub hodbc dbcur sql_cmd sql_param sql_cnt verbose return_needed} {
global rdbms_info f_info xml_info 
	set max_param [llength $sql_param]
	# make sure all of the parameters you require are set
	for {set i 0} { $i < $max_param } {incr i } {
		set [lindex $sql_param $i] $rdbms_info([lindex $sql_param $i])
	}
	if {$verbose == 1 } {
		Enter_log_item $f_info(log_id) "SQL" [format "Start Statement (%d) Processing" $sql_cnt] 2
	}
	set sk [string tolower $rdbms]
	if {$sk == "mssql"} {
		if {$sql_sub} {
			if {[catch {$hodbc [subst $sql_cmd]}  d_query]} {
				Enter_log_item $log_id "d_query" [format "Returned is ==%s==" $d_query] 2
				Enter_log_item $log_id "ERROR" [format "Unable to execute above command %s" $sql_cmd] 2
				Error_out $log_id $sec_name
			}
		} else  {
			if {[catch {$hodbc $sql_cmd}  d_query]} {
				Enter_log_item $log_id "d_query" [format "Returned is ==%s==" $d_query] 2
				Enter_log_item $log_id "ERROR" [format "Unable to execute this sql ==\n%s\n===" $sql_cmd] 2
				Error_out $log_id $sec_name
			}
		}
		return $d_query
	}
	if {$sk == "oracle"} {
		if {$sql_sub} {
			set q_error 0
			set ora_sql [subst $sql_cmd]
			if {[catch {orasql $dbcur $ora_sql}]} { set q_error 1 }
			if {[oramsg $dbcur rc] != 0 || $q_error == 1} {
				Enter_log_item $log_id "ORACODE" [format "Return code is %d" [oramsg $dbcur rc]] 1
				Enter_log_item $log_id "ORAERR" [format "%s" [oramsg $dbcur error]] 2
				Enter_log_item $log_id "ERROR" [format "Unable to execute this sql ===\n%s\n===" $ora_sql] 2
				Error_out $log_id $sec_name
			}
		} else  {
			orasql $dbcur $sql_cmd
			if {[oramsg $dbcur rc] != 0} {
				Enter_log_item $log_id "ORACODE" [format "Return code is %d" [oramsg $dbcur rc]] 1
				Enter_log_item $log_id "ORAERR" [format "%s" [oramsg $dbcur error]] 1
				Enter_log_item $log_id "ERROR" [format "Unable to execute command ===\n%s\n===" $sql_cmd] 1
				Error_out $log_id $sec_name
			}
		}
		if {$return_needed} {
			orafetch $dbcur -datavariable output
			return $output
		} else {
			return
		}
	}
	if {$sk == "pgsql"} {
		puts [format "In section ===%s=== No RDBMS_sql for PostgreSQL yet" $sec_name]
		return
	}
	if {$sk == "mysql"} {
		puts [format "In section ===%s=== No RDBMS_sql for MySQL yet" $sec_name]
		return
	}
}
#
# This routine is optimized for the queries being run for the TPC-DS as 
# it optimizes the return and logging of the data from the queries.
#
proc DS_sql { rdbms log_id sec_name hodbc dbcur sql_cmd xlevel} {
global rdbms_info f_info xml_info 
	set sk [string tolower $rdbms]
	if {$sk == "mssql"} {
		if {[catch {$hodbc $sql_cmd}  d_query]} {
			Enter_log_item $log_id "d_query" [format "Returned is ==%s==" $d_query] $xlevel
			Enter_log_item $log_id "ERROR" [format "Unable to execute this sql ==\n%s\n===" $sql_cmd] $xlevel
			Error_out $log_id $sec_name
		}
		Enter_log_tag $log_id "S" "Output" 0 xlevel
		set maxindex [llength $d_query]
		for {set qindex 0} {$qindex < $maxindex} {incr qindex} {
			puts $log_id [lindex $d_query 0]
		}
		Enter_log_tag $log_id "E" "Output" 0 xlevel
	}
	if {$sk == "oracle"} {
		orasql $dbcur $sql_cmd
		if {[oramsg $dbcur rc] != 0} {
			Enter_log_item $log_id "ORACODE" [format "Return code is %d" [oramsg $dbcur rc]] $xlevel
			Enter_log_item $log_id "ORAERR" [format "%s" [oramsg $dbcur error]] $xlevel
			Enter_log_item $log_id "ERROR" [format "Unable to execute command ===\n%s\n===" $sql_cmd] $xlevel
			Error_out $log_id $sec_name
		}
		orafetch $dbcur -datavariable output
		puts $log_id $output
		#return $output
	}
	if {$sk == "pgsql"} {
		puts [format "In section ===%s=== No RDBMS_sql for PostgreSQL yet" $sec_name]
		return
	}
	if {$sk == "mysql"} {
		puts [format "In section ===%s=== No RDBMS_sql for MySQL yet" $sec_name]
		return
	}
}
