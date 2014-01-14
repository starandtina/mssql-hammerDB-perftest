#!/bin/sh 
########################################################################
# \
export LD_LIBRARY_PATH=./lib:$LD_LIBRARY_PATH
# \
export PATH=./bin:$PATH
# \
exec tclsh8.5 -file $0 ${1+"$@"}
# \
exit
########################################################################
#
#
#  Copyright Timothy D. Witham 2012, 2013
#  Distributed under GPL 2.2
# 
#   Has one or two arguments - first is directory for benchmark you wish to run control page files
#                            - second is the directory that the output of the run will go
#                            - Within the specified results location a new directory will be made 
#                            - of the format:  Database_test_type_yyyy_mm_ddhHHmMMsSS.
#
#   If logging is turned on the following will happen:
#      The directory will be created and the follwoing items will be placed
#      into the directory.
#
#      1) The entire contents of the statements directory
#      2) A log file with timestamps and various debug/trace messages
#      3) The performance results
#      4) Output of any other trace/logging commands request in the {statements}/commands
#      5) If it runs to completion there will be a file created just called "COMPLETION"
#         with no data in it.
#
#
package require Thread 
package require platform 

global rdbms_info f_info xml_info 
set err_flg 0
#
# Get the required
#
#
# bring in the external sources that we need
#
set sources {"auto_xml.tcl" "auto_db.tcl" "auto_logs.tcl" "auto_info.tcl" "auto_dbinfo.tcl"}
set comp "components"
foreach f $sources {
	set fn_in [file join $comp $f]
	if [catch [source $fn_in] ] {
		puts [format "ERROR: can't find %s" $fn_in]
		exit
	}
}

proc Dump_params { log_id params_needed} {
global rdbms_info f_info xml_info 
	set param_error 0
	puts $log_id "\t\t<params>"
	foreach f $params_needed {
		if {[info exists rdbms_info($f)] == 1} {
			puts $log_id [format "\t\t\t<%s>%s</%s>" $f $rdbms_info($f) $f]
		} else { 
			if {[info exists f_info($f)] == 1} {
				puts $log_id [format "\t\t\t<%s>%s</%s>" $f $f_info($f) $f]
			} else {
				puts $log_id [format "\t\t\t<WARNING>%s is needed but not defined</WARNING>" $f ]
				set param_error 1
			}
		}

	}
	puts $log_id "\t\t</params>"
	return $param_error
	# fix old way of doing things
	foreach f $rdbms_info(sql_params) {
		puts $log_id [format "\t\t\t<%s>%s</%s>" $f $rdbms_info($f) $f]
	}
}

#
# Will parse the {configuration directory}/background.txt file
# and launch and manage any background monitoring processes
#

proc xBackground { sf_flag } {
global rdbms_info f_info xml_info 
set c_list [list background]

	if { [string compare "S" $sf_flag] == 0 } {
		Enter_log_tag $f_info(log_id) "S" "background_start" 1
		set file_id [Get_file_id "background_start" $rdbms_info(background) $rdbms_info(component) ""
		close $file_id
		Enter_log_tag $f_info(log_id) "E" "background_start" 1
	} else {
		Enter_log_tag $f_info(log_id) "S" "background_end" 1
		set file_id [Get_file_id "background_end" $rdbms_info(background) $rdbms_info(component) ""]
		close $file_id
		Enter_log_tag $f_info(log_id) "E" "background_end" 1
	}
}

proc Connect_to_DB {log_id rdbms } {
global rdbms_info f_info xml_info 
	set xlevel 1
	set rdbms_info(dbhandle) "NOT_USED"
	set rdbms_info(dbcur)    "NOT_USED"

	set sk [string tolower $rdbms]
	if { $sk == "mssql" } {
		 package require tclodbc 2.5.1
		 Enter_log_tag $log_id "S" "connect_to_MSSQL" 1 xlevel
		 set params_needed [list rdbms test server port authentication server_ID server_pass database_name ODBC_driver]
		 if {[Dump_params $log_id $params_needed]} {
			Error_out $f_info(log_id) "connect_to_MSSQL"
		}
		Connect_to_MSSQL  $log_id $rdbms_info(main_db) $rdbms_info(server) $rdbms_info(port) \
		               	  $rdbms_info(ODBC_driver)     $rdbms_info(authentication) \
			              $rdbms_info(server_ID)       $rdbms_info(server_pass) $xlevel
		Enter_log_tag $log_id "E" "connect_to_MSSQL" 1 xlevel
	   	return
	}
	if { $sk == "oracle" } {
		package require Oratcl 4.5
		Enter_log_tag $log_id "S" "connect_to_ORACLE" 1 xlevel
		set params_needed [list rdbms test server admin admin_pass test_user test_pass \
		                        connect sysconnect test_table_space test_temp_space]
		Oracle_connect_string $rdbms_info(server) $rdbms_info(admin) $rdbms_info(admin_pass) \
		                      $rdbms_info(test_user) $rdbms_info(test_pass) \
				              rdbms_info(connect) rdbms_info(sysconnect)
		if {[Dump_params $log_id $params_needed]} {
			Error_out $f_info(log_id) "connect_to_ORACLE"
		}
		Enter_log_tag $log_id "E" "connect_to_ORACLE" 1 xlevel
	   	return
	}
	if { $sk == "pgsql" } {
		 package require pgtcl 2.0.0
		 Enter_log_tag $log_id "S" "connect_to_PGSQL" 1 xlevel
		 set params_needed [list rdbms test server admin admin_pass ]
		 if {[Dump_params $log_id $params_needed]} {
			Error_out $f_info(log_id) "connect_to_PGSQL"
		}
		Connect_to_PGSQL $log_id 
	   	return
	}
	if { $sk == "mysql" } {
		 package require mysqltcl 3.0.5
		 Enter_log_tag $log_id "S" "connect_to_MySQL" 1 xlevel
		 if {[Dump_params $log_id $params_needed]} {
			Error_out $f_info(log_id) "connect_to_MySQL"
		}
		Connect_to_MySQL $log_id 
	   	return
	}
	Enter_log_item $log_id "ERROR" [format "Don't know about database %s" $rdbms ] 1
	Enter_log_tag $log_id "E" "autohammer" 0
	exit 
}

# 
# Routine to open a file and create the proper log file entries
# second option is the list of params being used by the call
# routine
#
proc Get_file_id { p_name f_name component params_needed} {
global rdbms_info f_info xml_info 
	set sk [string tolower $component]
	switch $sk {
		yes { set file_in [file join "components" $f_name]  
		      set alt_in  [file join "components" \
		                             [string tolower $rdbms_info(test)] \
		                             [string tolower $rdbms_info(rdbms)] \
					     $f_name] } 
		no  { set file_in [file join $f_info(cmd_dir) $f_name] }
		default { Enter_log_item $f_info(log_id) "ERROR" "Component must be yes or no" 2
		          Enter_log_item $f_info(log_id) "ERROR" "Value is ==$sk==" 2
			  Error_out $f_info(log_id) $p_name }
	}
	Enter_log_item $f_info(log_id) "using" $file_in 2
	if {[Dump_params $f_info(log_id) $params_needed]} {
		Error_out $f_info(log_id) $p_name
	}
	if [catch {open $file_in r} file_id ] {
		if { $sk == "yes" } {
			if [catch {open $alt_in r} file_id ] {
				Enter_log_item $f_info(log_id) "ERROR" [format "Unable to open %s" $file_in] 2
				Enter_log_item $f_info(log_id) "ERROR" [format "Unable to open %s" $alt_in] 2
				Error_out $f_info(log_id) $p_name
			}
		} else {
			Enter_log_item $f_info(log_id) "ERROR" [format "Unable to open %s" $file_in] 2
			Error_out $f_info(log_id) $p_name
		}
	}
	return $file_id
}

# 
# Routine to open a file and create the proper log file entries
# third option is the list of params being used by the call
# routine
#
proc Source_file { p_name f_name params_needed} {
global rdbms_info f_info xml_info 
	if { [string compare [string tolower $rdbms_info(component)] "yes"] == 0 } {
		set file_in [file join "components" $f_name]
	} else {
		set file_in [file join $f_info(cmd_dir) $f_name]
	}
	Enter_log_item $f_info(log_id) "using" $file_in 2
	if {[Dump_params $f_info(log_id) $params_needed]} {
		Error_out $f_info(log_id) $p_name
	}
	if [catch [source $file_in ] ] {
		Enter_log_item $f_info(log_id) "ERROR" [format "Unable to source %s" $file_in] 1
		Error_out $f_info(log_id) $p_name
	}
}


proc Use_database { rdbms hodbc db_name p_name} {
global rdbms_info f_info xml_info 
	if {[string compare "no" [string tolower $rdbms_info(use_db)]] == 0 } { return }
	if {[string compare "yes" [string tolower $rdbms_info(use_db)]] != 0 } { 
		Enter_log_item $f_info(log_id) "use_database" "Either yes or no for use datbase" 1
		Error_out $f_info(log_id) $p_name
	}
	set sk [string tolower $rdbms]
	if {$sk == "mssql"} {
		set sql_query [ format "use %s;" $rdbms_info(database_name)]
		if {[catch [ set d_query [$hodbc  $sql_query]]] != 1} {
			Enter_log_item $f_info(log_id) "d_query" [format "Returned is ==%d==" $d_query] 1
			Enter_log_item $f_info(log_id) "ERROR" [format "Unable to use database ==%s==" $db_name] 1
			Time_stamp "E" 2
			Error_out $f_info(log_id) $p_name
		}
		return
	}
	if {$sk == "oracle"} {
		set sql_query [ format "connect %s/%s;" $rdbms_info(test_user) $rdbms_info(test_pass) ]
	}
}



proc Do_sql { log_id rdbms file_id sec_name sql_param } {
global rdbms_info f_info xml_info 
	set dbhandle "NOT USED"
	set dbcur    "NOT USED"
	set sk [string tolower $rdbms]
	set use_db [string tolower $rdbms_info(use_db)]
	if {[string compare "system" $use_db] == 0} {
		set good_now 1
	} elseif {[string compare "test" $use_db] != 0} {
		Enter_log_item $log_id "ERROR" "Database requires use_database to be either system or test" 1
		Error_out $log_id $sec_name

	}
	switch $sk {
		mssql  { 
				DB_use $log_id $sec_name $use_db $rdbms $rdbms_info(database_name)\
			       	   $rdbms_info(connect) $rdbms_info(main_db) dbhandle dbcur
	    }
		oracle { 
			set dbhandle "NOT_USED"
			set dbcur    "NOT_USED"
			if {[string compare "system" $use_db] == 0} {
				DB_use $log_id $sec_name $use_db $rdbms $rdbms_info(database_name) \
				        $rdbms_info(sysconnect) $rdbms_info(main_db) dbhandle dbcur
			} elseif {[string compare "test" $use_db] == 0} {
				DB_use $log_id $sec_name $use_db $rdbms $rdbms_info(database_name) \
				       $rdbms_info(connect) $rdbms_info(main_db) dbhandle dbcur
		   	} 
            set c_string [format "%s/%s@%s" $rdbms_info(test_user) $rdbms_info(test_pass) $rdbms_info(server)]
		 	set dbcur [oraopen $dbhandle] 
		 	if {[oramsg $dbhandle rc] !=0} {
				Enter_log_item $log_id "ERROR" [format "%s" [oramsg $dbhandle error]] 1
				Error_out $log_id $sec_name
			 }

		}
		pgsql  { puts "NEED TO ADD OPEN FOR PostgreSQL" }
		mysql  { puts "NEED TO ADD OPEN FOR MySQL" }
	}
	
	
	set sql_cmd ""
	set sql_cnt 1	
	while (1) {
		set line_in [gets $file_id]
		if {[eof $file_id]} { break }
		if {[string compare "yes" [string tolower $rdbms_info(trace_sql)]] == 0 } {
			Enter_log_item $f_info(log_id) "SQL_in" $line_in 1
		}
		if {[string first "-- HAMMERORA GO" $line_in]  >= 0 } {
			if {[string compare "yes" [string tolower $rdbms_info(trace_sql)]] == 0 } {
				Time_stamp $log_id "S" 2	
			}
			if { [string length $sql_cmd] > 0 } { 
				RDBMS_sql $rdbms_info(rdbms) $log_id $sec_name $rdbms_info(sql_sub) \
				          $rdbms_info(main_db) $dbcur $sql_cmd $sql_param $sql_cnt 1 0
			}
			if {[string compare "yes" [string tolower $rdbms_info(trace_sql)]] == 0 } {
				Time_stamp $log_id "E" 2	
				Enter_log_item $f_info(log_id) "SQL_in" $line_in 1
				Time_stamp $log_id "S" 2	
			}
			set  sql_cmd ""
			incr sql_cnt 
			
		} else {
			if {[string first "--" $line_in] < 0 } { 
				append sql_cmd $line_in " "
			}
		}
	}


	if { [string length $sql_cmd] > 0 } { 
		RDBMS_sql $rdbms_info(rdbms) $log_id $sec_name $rdbms_info(sql_sub) \
		          $rdbms_info(main_db) $dbcur $sql_cmd $sql_param $sql_cnt 1 0
	}

	Commit_sql $log_id $rdbms $rdbms_info(main_db) $dbhandle $sec_name 1 2

	if { $sk == "oracle" } { 
		oraclose $dbcur 
                oralogoff $dbhandle
	}
}

proc Do_sql_parallel { log_id rdbms file_id sec_name sql_param max_threads } {
global rdbms_info f_info xml_info 
	set dbhandle "NOT USED"
	set dbcur    "NOT USED"
	set sk [string tolower $rdbms]
	set use_db [string tolower $rdbms_info(use_db)]
	if {[string compare "system" $use_db] == 0} {
		set good_now 1
	} elseif {[string compare "test" $use_db] != 0} {
		Enter_log_item $log_id "ERROR" "Database requires use_database to be either system or test" 1
		Error_out $log_id $sec_name

	}
	switch $sk {
		mssql  { 
				DB_use $log_id $sec_name $use_db $rdbms $rdbms_info(database_name)\
			       	   $rdbms_info(connect) $rdbms_info(main_db) dbhandle dbcur
	    }
		oracle { 
			set dbhandle "NOT_USED"
			set dbcur    "NOT_USED"
			if {[string compare "system" $use_db] == 0} {
				DB_use $log_id $sec_name $use_db $rdbms $rdbms_info(database_name) \
				        $rdbms_info(sysconnect) $rdbms_info(main_db) dbhandle dbcur
			} elseif {[string compare "test" $use_db] == 0} {
				DB_use $log_id $sec_name $use_db $rdbms $rdbms_info(database_name) \
				       $rdbms_info(connect) $rdbms_info(main_db) dbhandle dbcur
		   	} 
            set c_string [format "%s/%s@%s" $rdbms_info(test_user) $rdbms_info(test_pass) $rdbms_info(server)]
		 	set dbcur [oraopen $dbhandle] 
		 	if {[oramsg $dbhandle rc] !=0} {
				Enter_log_item $log_id "ERROR" [format "%s" [oramsg $dbhandle error]] 1
				Error_out $log_id $sec_name
			 }

		}
		pgsql  { puts "NEED TO ADD OPEN FOR PostgreSQL" }
		mysql  { puts "NEED TO ADD OPEN FOR MySQL" }
	}
	
	
	set sql_cmd ""
	set sql_cnt 1	
	while (1) {
		set line_in [gets $file_id]
		if {[eof $file_id]} { break }
		if {[string compare "yes" [string tolower $rdbms_info(trace_sql)]] == 0 } {
			Enter_log_item $f_info(log_id) "SQL_in" $line_in 1
		}
		if {[string first "-- HAMMERORA GO" $line_in]  >= 0 } {
			if {[string compare "yes" [string tolower $rdbms_info(trace_sql)]] == 0 } {
				Time_stamp $log_id "S" 2	
			}
			if { [string length $sql_cmd] > 0 } { 
				RDBMS_sql $rdbms_info(rdbms) $log_id $sec_name $rdbms_info(sql_sub) \
				          $rdbms_info(main_db) $dbcur $sql_cmd $sql_param $sql_cnt 1 0
			}
			if {[string compare "yes" [string tolower $rdbms_info(trace_sql)]] == 0 } {
				Time_stamp $log_id "E" 2	
				Enter_log_item $f_info(log_id) "SQL_in" $line_in 1
				Time_stamp $log_id "S" 2	
			}
			set  sql_cmd ""
			incr sql_cnt 
			
		} else {
			if {[string first "--" $line_in] < 0 } { 
				append sql_cmd $line_in " "
			}
		}
	}


	if { [string length $sql_cmd] > 0 } { 
		RDBMS_sql $rdbms_info(rdbms) $log_id $sec_name $rdbms_info(sql_sub) \
		          $rdbms_info(main_db) $dbcur $sql_cmd $sql_param $sql_cnt 1 0
	}

	Commit_sql $log_id $rdbms $rdbms_info(main_db) $dbhandle $sec_name 1 2

	if { $sk == "oracle" } { 
		oraclose $dbcur 
                oralogoff $dbhandle
	}
}

proc Run_cmd { sec_name rdbms test_name cmd input_file } {
global rdbms_info f_info xml_info 
set xlevel 1

	Enter_log_tag $f_info(log_id) "S" $sec_name  1 xlevel
	Enter_log_tag $f_info(log_id) "S" "params" 0 xlevel
	Enter_log_item $f_info(log_id) "cmd" $cmd $xlevel
	Enter_log_item $f_info(log_id) "input_file" $input_file $xlevel
	set run_log [file join $f_info(log_dir) [format "%s_log.txt" $sec_name]]
	set err_log [file join $f_info(log_dir) [format "%s_err.txt" $sec_name]]
	Enter_log_item $f_info(log_id) "log_file" $run_log $xlevel
	Enter_log_item $f_info(log_id) "err_file" $err_log $xlevel
	Enter_log_tag $f_info(log_id) "E" "params" 0 xlevel

	if {![info exists rdbms_info(component)]} {
		Enter_log_item $f_info(log_id) "ERROR" "component needs to be specified" $xlevel
		puts [info exists rdbms_info(component)]
		puts $rdbms_info(component)
		Error_out $f_info(log_id) $sec_name
	}

	if {[string length $input_file] == 0 } {
		set input 0
	} else {
		set input 1
	}

	set sk [string tolower $rdbms_info(component)]
	if {$sk == "yes"} {
		set cmd_file [file join "components" $input_file] 
		if {![file exists $cmd_file]} {
				set old_cmd $cmd_file
				set cmd_file [file join "components" \
				             [string tolower $test_name] \
							 [string tolower $rdbms] \
							 $input_file]
				if {![file exists $cmd_file]} {
					Enter_log_item $f_info(log_id) "current_directory" [pwd] $xlevel
					Enter_log_item $f_info(log_id) "ERROR" "Component not found in ==$old_cmd ==" $xlevel
					Enter_log_item $f_info(log_id) "ERROR" "Component not found in ==$cmd_file==" $xlevel
			     	Error_out $f_info(log_id) $sec_name 
				}
		}
	} else {
		if {$sk == "no" } {
			set cmd_file [file join $f_info(cmd_dir) $input_file] 
		} else {
			 Enter_log_item "ERROR" "Component must be yes or no" 1
		     Error_out $f_info(log_dir) $sec_name 
	 	}
	}

	if {[llength $cmd] == 1} {
		if {$input} {
			if { [catch {exec $cmd < $cmd_file > $run_log 2> $err_log} msg] } {
				puts "Error returned"
				puts "Error info: $::errorInfo"
			}
		} else {
			if { [catch {exec $cmd > $run_log 2> $err_log} msg] } {
				puts "Error returned"
				puts "Error info: $::errorInfo"
			}
		}
		Enter_log_tag $f_info(log_id) "S" $sec_name  1 xlevel
		return
	}
	set cmd_name [lindex $cmd]
	set cmd      [lreplace $cmd 0 0 ]
	if {$input} {
		if { [catch {exec $cmd_name {expand [glob $cmd]} < $cmd_file > $run_log 2> $err_log} msg] } {
			puts "Error returned"
			puts "Error info: $::errorInfo"
		}
	} else {
		if { [catch {exec $cmd_name {expand [glob $cmd]} > $run_log 2> $err_log} msg] } {
			puts "Error returned"
			puts "Error info: $::errorInfo"
		}
	}
	Enter_log_tag $f_info(log_id) "S" $sec_name  1 xlevel
}


proc Run_sql { sec_name f_name component sql_param } {
global rdbms_info f_info xml_info 
set xlevel 1
	Enter_log_tag $f_info(log_id) "S" $sec_name  1 xlevel
	if {![info exists rdbms_info(sql_sub)]} {
		Enter_log_item $f_info(log_id) "WARNING" "Did not specify sql_sub setting to yes(1)/no(0)" $xlevel 
		set rdbms_info(sql_sub) 0
	}
	if {$rdbms_info(sql_sub)} {
		foreach f $sql_param {
			if { [info exists f_info($f)]     } {continue}
			if { [info exists rdbms_info($f)] } {continue}
			Enter_log_item $f_info(log_id)  "ERROR" [format "You require ===%s=== but didn't define it" $f] $xlevel
			Error_out $f_info(log_id) $sec_name
		}
	}
	set file_id [Get_file_id  $sec_name $f_name $component $sql_param]
	Do_sql $f_info(log_id) $rdbms_info(rdbms) $file_id $sec_name $sql_param
	close $file_id
	Enter_log_tag $f_info(log_id) "E" $sec_name  1 xlevel
}

proc Run_sql_parallel { sec_name f_name component sql_param max_threads} {
global rdbms_info f_info xml_info 
set xlevel 1
	Enter_log_tag $f_info(log_id) "S" $sec_name  1 xlevel
	if {![info exists rdbms_info(sql_sub)]} {
		Enter_log_item $f_info(log_id) "WARNING" "Did not specify sql_sub setting to yes(1)/no(0)" $xlevel 
		set rdbms_info(sql_sub) 0
	}
	if {$rdbms_info(sql_sub)} {
		foreach f $sql_param {
			if { [info exists f_info($f)]     } {continue}
			if { [info exists rdbms_info($f)] } {continue}
			Enter_log_item $f_info(log_id)  "ERROR" [format "You require ===%s=== but didn't define it" $f] $xlevel
			Error_out $f_info(log_id) $sec_name
		}
	}
	set file_id [Get_file_id  $sec_name $f_name $component $sql_param]
	Do_sql $f_info(log_id) $rdbms_info(rdbms) $file_id $sec_name $sql_param
	close $file_id
	Enter_log_tag $f_info(log_id) "E" $sec_name  1 xlevel
}

proc xCreate_log_dir {} {
global rdbms_info f_info xml_info 
	set clock_string [clock format [clock seconds] -format "%Y_%m_%dh%Hm%Ms%S"]
	set log_file [format "%s_%s_%s" $rdbms_info(rdbms) $rdbms_info(test) $clock_string]
	set f_info(log_dir) [file join $f_info(log_loc) $log_file]
	if {[file exists $f_info(log_dir)] } {
		puts stderr [format "ERROR: Log directory ==%s== already exists" $f_info(log_dir)]
		exit
	}
	if {[catch [file mkdir $f_info(log_dir)] file_err] } {
		puts stderr [format "ERROR: Unable to create the log directory ==%s==" $f_info(log_dir)]
		puts stderr [format "       Error code is ==%d==" $file_err]
		exit
	}
	if {[catch [file mkdir [file join $f_info(log_dir) "CONFIG"] file_err]] } {
		puts stderr [format "ERROR: Unable to create the log CONFIG directory ==%s/CONFIG==" $f_info(log_dir)]
		puts stderr [format "       Error code is ==%d==" $file_err]
		exit
	}
	if {[catch [file mkdir [file join $f_info(log_dir) "components"] file_err]] } {
		puts stderr [format "ERROR: Unable to create the log components directory ==%s/components==" $f_info(log_dir)]
		puts stderr [format "       Error code is ==%d==" $file_err]
		exit
	}
	if {[catch [file mkdir [file join $f_info(log_dir) "bin"] file_err]] } {
		puts stderr [format "ERROR: Unable to create the log bin directory ==%s/bin==" $f_info(log_dir)]
		puts stderr [format "       Error code is ==%d==" $file_err]
		exit
	}
	if {[catch [file mkdir [file join $f_info(log_dir) "lib"] file_err]] } {
		puts stderr [format "ERROR: Unable to create the log lib directory ==%s/lib==" $f_info(log_dir)]
		puts stderr [format "       Error code is ==%d==" $file_err]
		exit
	}
	if {[catch [file mkdir [file join $f_info(log_dir) "include"] file_err]] } {
		puts stderr [format "ERROR: Unable to create the log include directory ==%s/include==" $f_info(log_dir)]
		puts stderr [format "       Error code is ==%d==" $file_err]
		exit
	}
# 
# And as long as we are here - create and open the log file
#
	set f_info(log_file) [file join $f_info(log_dir) [format "%s.xml" $f_info(log_dir)]]
	if {[file exists $f_info(log_file)]} {
		puts stderr [format "ERROR: Log file ==%s== aleady exists" $f_info(log_file)]
		exit
	}
	if [catch {open $f_info(log_file) w } f_info(log_id) ] {
		puts stderr [format "ERROR: Unable to open log file ==%s==" $f_info(log_file)]
		exit
	}
}

#RANDOM NUMBER
proc RandomNumber {m M} {return [expr {int($m+rand()*($M+1-$m))}]}

proc Create_log_dir {} {
global rdbms_info f_info xml_info 
	set ranz [ RandomNumber 0 9999 ]
	set clock_string [clock format [clock seconds] -format "%Y_%m_%dh%Hm%Ms%S"]
	set log_file [format "%s_%s_%s_%s" $rdbms_info(test) $rdbms_info(rdbms) $clock_string $ranz]
	set f_info(log_dir) [file join $f_info(log_loc) $log_file]
	if {[file exists $f_info(log_dir)] } {
		puts stderr [format "ERROR: Log directory ==%s== already exists" $f_info(log_dir)]
		exit
	}
	if {[catch [file mkdir $f_info(log_dir)] file_err] } {
		puts stderr [format "ERROR: Unable to create the log directory ==%s==" $f_info(log_dir)]
		puts stderr [format "       Error code is ==%d==" $file_err]
		exit
	}

	foreach c_dir {  "CONFIG" "components" "bin" "lib" "include" } {
		if {[catch [file mkdir [file join $f_info(log_dir) $c_dir] file_err]] } {
			puts stderr [format "ERROR: Unable to create the log $c_dir directory ==%s/$c_dir==" $f_info(log_dir)]
			puts stderr [format "       Error code is ==%d==" $file_err]
			exit
		}
	}
# 
# And as long as we are here - create and open the log file
#
	set f_info(log_file) [file join $f_info(log_dir) [format "%s.xml" $f_info(log_dir)]]
	if {[file exists $f_info(log_file)]} {
		puts stderr [format "ERROR: Log file ==%s== aleady exists" $f_info(log_file)]
		exit
	}
	if [catch {open $f_info(log_file) w } f_info(log_id) ] {
		puts stderr [format "ERROR: Unable to open log file ==%s==" $f_info(log_file)]
		exit
	}
}
proc Log_files {indir logdir} {
global rdbms_info f_info xml_info 
	set outdir [file join $logdir "CONFIG"]
	set inglob [file join $indir *]
	set infiles [glob $inglob]
	foreach f $infiles {
		set f_tail [file tail $f]
		if [catch {open $f r} fin_id ] {
			puts stderr [format "ERROR: Unable to open input file ==%s==" $f]
			exit
		}
		set ftail [file tail $f]
		set fout [file join $outdir $ftail]
		if {[file exists $fout]} {
			puts stderr [format "ERROR: Output file ==%s== already exists" $fout]
			exit
		}
		if [catch {open $fout w } fout_id ] {
			puts stderr [format "ERROR: Unable to open output file ==%s==" $fout]
			exit
		}
		puts -nonewline $fout_id [read $fin_id]
		close $fin_id
		close $fout_id
	}
}


proc Log_config { } {
global rdbms_info f_info xml_info 
	set xlevel 0

	Create_log_dir
	set script_is [info script]
	set script_dir [file dirname $script_is]
	set exec_is   [info nameofexecutable]
	set exec_dir  [file dirname [file dirname $exec_is]]

	Log_files $f_info(cmd_dir) $f_info(log_dir)
#
# Now copy autohammer to the log directory
#
	set fout [file join $f_info(log_dir) "autohammer.tcl"]
	if [catch {file copy $script_is $fout} ] {
        puts stderr [format "ERROR: Unable to log ==%s==" $f" ]
        exit
    }
#
# Now copy the components to the log directory
#

	
	set to_copy_list [glob [file join [file join $script_dir "components"] "*"]]
    foreach f $to_copy_list {
		set fout [file join $f_info(log_dir) [string range $f [string first "components" $f] end]]
        if [catch {file copy $f $fout}] {
            puts stderr [format "ERROR: Unable to open hora-component file ==%s==" $f" ]
            puts stderr [format "ERROR: Unable to log to file ==%s==" $fout" ]
            exit
        }
    }
#
# Now copy the executable directories 
#
	foreach d { "include" "lib" "bin" } {
		set to_copy_list [glob [file join [file join $exec_dir $d] "*"]]
    	foreach f $to_copy_list {
			set fout [file join $f_info(log_dir) [string range $f [string first $d $f] end]]
        	if [catch {file copy $f $fout}] {
            	puts stderr [format "ERROR: Unable to log file in ==%s==" $f" ]
            	puts stderr [format "ERROR: Unable to log to file ==%s==" $fout" ]
            	exit
        	}
    	}
	}

# Now put the header into the file
	puts $f_info(log_id) "<?xml version=\"1.0\" encoding=\"utf-8\"?>"
	Enter_log_tag $f_info(log_id) "S" "autohammer" 1 xlevel
	Enter_log_item $f_info(log_id) "parsing" "run_config.xml" 1
	Enter_log_item $f_info(log_id) "XML-is" "Well Formed" 1

	Enter_log_tag $f_info(log_id) "S" "get_configuration" 0 xlevel
	set info_list [array names rdbms_info]
	foreach f $info_list {
		Enter_log_item $f_info(log_id) $f $rdbms_info($f) 2
	}
	Enter_log_tag $f_info(log_id) "E" "get_configuration" 1 xlevel
}

proc Check_required { p_name call } {
global rdbms_info f_info xml_info 
#
# First set the key and think items
#
	# Now build the call string
	set run_string [lindex $call 0]
	set call       [lreplace $call 0 0]
	for {set i 0} {$i < [llength $call] } { incr i } {
		set check_param [lindex $call $i]
		if { [info exists f_info($check_param)] ==1 } {
			if {[string compare $check_param "log_dir"] == 0 } {
				append run_string " " [Quote_slash $f_info($check_param)]
				continue 
			}
			if {[string compare $check_param "cmd_dir"] == 0 } {
				append run_string " " [Quote_slash $f_info($check_param)]
				continue 
			}
			append run_string " " $f_info($check_param)
			continue
		}
		if { [info exists rdbms_info($check_param)] ==1 } {
			# add check if connect string to put quotes and double slashes
			if {[string compare $check_param "connect"] == 0 } {
				append run_string " " [Quote_slash $rdbms_info($check_param)]
			} else {
				append run_string " " $rdbms_info($check_param)
			}
			continue
		}
		Enter_log_item $f_info(log_id) \
		      "ERROR" [format "Required parameter ===%s=== is not defined" $check_param] 1
		Error_out $f_info(log_id) $p_name
	}
	return $run_string

}

proc Run_tcl { p_name f_name call} {
global rdbms_info f_info xml_info 
set xlevel 1
	Enter_log_tag $f_info(log_id) "S" $p_name  1 xlevel
	Enter_log_item $f_info(log_id) "call_is" $call 2
	set call_params [lrange $call 1 end]
	Source_file $p_name $f_name $call_params
	set call_items [split $call " "]
	#
	# Now build the command
	#
	set RUNSTRING [Check_required  $p_name $call ]

	#puts [format "Built command is ===\n%s\n===" $RUNSTRING]
	eval $RUNSTRING

	Enter_log_tag $f_info(log_id) "E" $p_name 1 xlevel
	return
}

proc Dump_system  {log_dir os_is rdbms test database_name factor connect sysconnect } { 
global rdbms_info f_info xml_info 

	Dump_os $log_dir $os_is

	set log_file [file join $log_dir "rdbms_info.xml"]
	if [catch {open $log_file w} log_id ] {
            puts stderr [format "ERROR: Unable to create ==%s==" $log_file" ]
            exit
   	}
	set sk [string tolower $rdbms]
	switch $sk {
		mysql      { puts "Can't do MySQL yet" }
		mssql      { MSSQL_params $log_id $connect }
		oracle     { Oracle_params $log_id $sysconnect $database_name}
		pgsql      { puts "Can't do PostgreSQL yet"}
		greenplum  { puts "Can't do Greenplum yet"}
		default    { puts "Unknown rdbms $sk " }
	}

	set tk [string tolower $test]
	switch $tk {
		tpcc      { Count_tpcc $log_dir $rdbms $database_name $connect $factor}
		tpch      { Count_tpch $log_dir $rdbms $database_name $connect $factor}
		tpcds     { Enter_log_item $f_info(log_id) "Counted" "See {log_dir}/check_load.xml" 2 }
		default    { puts "Unknown test $tk " }
	}
}
		
#
# Start of main
#
if {$argc == 1} {
	set f_info(cmd_dir) [lindex $argv 0]
	set f_info(log_loc) ""
} else {
	if {$argc != 2 } { set err_flg 1 }
	set f_info(cmd_dir) [lindex $argv 0]
	set f_info(log_loc) [lindex $argv 1]
}
if {$err_flg == 1 } {
	puts stderr "ERROR: Invalid usage"
	puts stderr "\trun_scripts.tcl <directory to execute> <results directory>"
	puts stderr "\t if no second option then the running directory will be used"
	puts stderr "\t as the location of the logging directory"
	exit
}

#
# Set some values that are used by one but not all of the
# RDBMS so that you don't end up with undefined values in
# the calls.
# 
set rdbms_info(admin)         "NOT_USED"
set rdbms_info(admin_pass)    "NOT_USED"
set rdbms_info(connect)       "NOT_USED"
set rdbms_info(sysconnect)    "NOT_USED"
set rdbms_info(test_user)     "NOT_USED"
set rdbms_info(test_pass)     "NOT_USED"
set rdbms_info(database_name) "NOT_USED"
set rdbms_info(main_db)       "db_main"
#
#
# This will read the xml configuration file and set the variables
# including which routine needs to be performed next. So the rest of
# this will be a simple loop:
#

Get_config_xml

while (1) {
	set todo [Parse_xml_config]
	switch $todo {
		config        { Log_config }

		connect       { Connect_to_DB     $f_info(log_id) $rdbms_info(rdbms)}

		disconnect    { Disconnect_from_DB $f_info(log_id) $rdbms_info(rdbms) \
			                           $rdbms_info(main_db) $rdbms_info(dbhandle) 1 }
	    sys_info      { set ts [string tolower $rdbms_info(test)]
						switch $ts {
							tpcc   { set factor $rdbms_info(warehouses) }
							tpch   { set factor $rdbms_info(db_scale)   }	
							tpcds  { set factor $rdbms_info(db_scale)   }
	 	}
					    Dump_system  $f_info(log_dir) $tcl_platform(os) $rdbms_info(rdbms) \
						             $rdbms_info(test) $rdbms_info(database_name) $factor\
			                     	 $rdbms_info(connect) $rdbms_info(sysconnect) }
		end_it        { break }
		run_cmd	      { Run_cmd $rdbms_info(sec_name)  $rdbms_info(rdbms) $rdbms_info(test) \
					            $rdbms_info(cmd) $rdbms_info(input_file) }

		run_sql       { Run_sql $rdbms_info(sec_name)  $rdbms_info(file_in) \
					            $rdbms_info(component) $rdbms_info(sql_params) }

		run_tcl       { Run_tcl $rdbms_info(sec_name)  $rdbms_info(file_in)  \
					            $rdbms_info(call) }

		default       { puts [format "Don't know what we are doing ==%s==" $todo ]}
	}
}

Enter_log_tag $f_info(log_id) "E" "autohammer" 0 xlevel
close $f_info(log_id)
