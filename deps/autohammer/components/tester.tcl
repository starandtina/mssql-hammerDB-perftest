#  tools/dsdgen -scale 1 -parallel 16 -delimiter \| -dir 1G_DEL_P16 -child 16 &
#  #  tools/dsdgen -scale 1 -parallel 16 -delimiter \| -dir 1G_DEL_P1 -child 1 &
#  #  tools/dsdgen -scale 1 -delimiter \| -dir 1G &
#  #  tools/dsdgen -scale 1 -parallel 16 -delimiter \| -dir 1G_16P5 -child 5 &
#  #  history | grep dsd
#  #
#  # 
#  # Distributed under GPL 2.2
#  # Copyright Steve Shaw 2003-2012
#  # Copyright Tim Witham 2012
#  #
#  # for all of this

#  proc Gen_tpcds { sec_name rdbms database_name log_id parallel db_scale base_log_dir connect dsgen_dir } {

package require Thread
package require platform

set sec_name      "run_query"
set rdbms         "oracle"
set database_name "tpcds"
set log_file      "woofer.xml"
set parallel      10
set db_scale      1
set base_log_dir  "TEST_DIRECTORY"
set connect      "NOT_USED"
set query_dir    "T_DSGen"
set current_dir [pwd]


set sources {"auto_xml.tcl" "auto_db.tcl" "auto_logs.tcl" "auto_info.tcl" "auto_dbinfo.tcl"}
set comp "components"
foreach f $sources {
	set fn_in [file join $comp $f]
	if [catch [source $fn_in] ] {
		puts [format "ERROR: can't find %s" $fn_in]
		exit
	}
}

# -- start query 1 in stream 0 using template query36.tpl
# -- end query 1 in stream 0 using template query36.tpl

proc Run_query_stream {qsnum rdbms databasename connect query_id log_id } {

	set sec_name "query_stream" 
	set verbose 0
	set q_time 0.00
	set t_time 0.00
	Put_thread_header $log_id $sec_name
	set xlevel 2
	Enter_log_item $log_id "stream_number" $qsnum $xlevel
	set start_total_ms [clock clicks -milliseconds]
	while {[gets $query_id line_in] >= 0 } {
		if {[string first "-- start query " $line_in] >= 0 } {
			set in_items [split $line_in " "]
			Enter_log_tag $log_id "S" "query" 0 xlevel
			Enter_log_item $log_id "count" [lindex $in_items 3] $xlevel
			scan [lindex $in_items 9]] "query%d.tpl" temp_num
			Enter_log_item $log_id "template" $temp_num $xlevel
			set query_in ""
			continue
		}
		if {[string first "-- end query " $line_in] >= 0 } {
			if {$verbose} {Enter_log_item $log_id "query_string" $query_in $xlevel}
			set start_query_ms [clock clicks -milliseconds]
			after [expr {int(rand() * 10)}]
			set end_query_ms [clock clicks -milliseconds]
			set q_time [expr { $end_query_ms - $start_query_ms}]
			Enter_log_item $log_id "msec" $q_time $xlevel
			Enter_log_tag $log_id "E" "query" 0 xlevel
			continue
		}

		append query_in $line_in

	}
	set end_total_ms [clock clicks -milliseconds]
	set t_time [expr { $end_total_ms - $start_total_ms}]
	Enter_log_item $log_id "total_msec" $t_time $xlevel
	Put_thread_footer $log_id $sec_name
	return
}
#
# Begin main
#

set query_out_dir [file join $base_log_dir "Q_RUN"]
if {[catch [file mkdir $query_out_dir] file_err ] } {
		puts "ERROR: Unable to make query run output directory"
		exit
}
#
# Set mutex so that nobody starts before they are all ready
#
set run_cond  [tsv::set tasks run_cond  [thread::cond create]]
set run_mutex [tsv::set tasks run_mutex [thread::mutex create]]
thread::mutex lock $run_mutex

for {set qsnum 0} {$qsnum < $parallel} {incr qsnum } {

	set log_file  [file join $query_out_dir [format "query_%04d.xml" $qsnum]]
	if [catch {open $log_file w} log_id] {
		puts "ERROR: UNABLE TO OPEN LOGFILE $log_file"
		exit
	}

	set query_file [file join $query_dir [format "query_%d.sql" $qsnum]]
	if [catch {open $query_file r} query_id] {
		puts "ERROR: UNABLE TO OPEN THE QUERY FILE $query_file"
		exit
	}
    set t_list($qsnum) [thread::create -joinable {thread::wait}]
    #
	# The load up the source code do this sync so that they happen one after another
	#   
    thread::transfer $t_list($qsnum) $log_id
	Load_sources $t_list($qsnum) $rdbms "tester.tcl"
    #
    # And run the database thread -async so they happen together
	#                                                                                    #

	eval [subst {thread::send -async $t_list($qsnum) {   \
		Run_query_stream $qsnum $rdbms $database_name $connect $query_id $log_id } r_id } ]

}
#
# OK, now send for everybody to start at the same time
#
tsv::set tasks predicate 1
thread::cond notify $run_cond
thread::mutex unlock $run_mutex
#
# Wait for everybody (threads) before repeating
#
while {[llength [thread::names]] > 1} {
	after 500
}
thread::cond destroy  $run_cond
thread::mutex destroy $run_mutex
puts "that's all folks"
exit





#
# If you only have one stream
#

Enter_log_item $log_id "parallel" $parallel $xlevel
if {$parallel == 1 } {
		cd $dsdgen_dir
		set dsdgen_params [format " -scale %d -delimiter \\: -dir %s" $db_scale [file join $current_dir $gen_out_dir]]
		if { [catch {exec "./dsdgen" "-SCALE" $db_scale "-delimiter" "\\:" "-dir" [file join $current_dir $gen_out_dir]} msg ]} {
			if { [string first "Warning" $::errorInfo] < 0 } { 
				puts "ERROR returned from dsdgen"
				puts "ERROR info: $::errorInfo"
				exit
			}
		}
		cd $current_dir
		Put_thread_footer $log_id $sec_name
		exit
}

#
# And if you are going parallel
#

for {set l_thread 1 } { $l_thread <= $parallel } {incr l_thread} {
		set gen_out_dir [file join $base_log_dir "DSDGEN" [format $subdir_template $parallel $l_thread] ]
		if {[catch [file mkdir $gen_out_dir] file_err ] } {
			puts "ERROR: Unable to make data generation output directory"
			exit
		}
		set t_list($l_thread) [thread::create -joinable {thread::wait}]
		Load_sources $t_list($l_thread) $rdbms "tester.tcl"
		cd $dsdgen_dir
		Enter_log_item $log_id "child" $l_thread $xlevel
		eval [subst {thread::send -async $t_litt($l_thread) \
				    {exec "./dsdgen" "-SCALE" $db_scale "-delimiter" "\\:" "-parallel" $parallel "-child" $l_thread "-dir" [file join $current_dir $gen_out_dir]}} ]
	
		cd $current_dir
}
 
#
# Wait until all of the threads go away
# 
while {[llength [thread::names]] > 1} {
	after 500
}

Put_thread_footer $log_id $sec_name
exit 
		if { [catch {exec "./dsdgen" "-SCALE" $db_scale "-delimiter" "\\:" "-parallel" $parallel "-child" $l_thread "-dir" [file join $current_dir $gen_out_dir]} msg ]} {
			if { [string first "Warning" $::errorInfo] < 0 } { 
				puts "ERROR returned from dsdgen"
				puts "ERROR info: $::errorInfo"
				exit
			}
		}
