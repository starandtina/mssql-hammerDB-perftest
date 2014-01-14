catch {console show}
##
# auto_posttpc.tcl -- Post TPC-H logfile parser 
# Produces csv file to past into spreadsheet to automaticly 
# calculate results
#
# Copyright 2012 Timothy D. Witham
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; version 2
# of the License.
# 
# Set to 1 for lots of messages 0 for normal operation
source "components/auto_xml.tcl"
set verbose 0
set refresh1 0.0
set refresh2 0.0
set mvuser 0
set max_query_run 0.0
set runcnt 0
#
# Since this is all one small operation things are set to global
# as it is all one group
#
global queries refresh1 refresh2 max_query_run
#
# Print the csv file
#
proc Putheader {verbose spread_id streams run_cnt } {
global queries refresh1 refresh2 max_query_run

set runcnt [expr {$streams*$run_cnt}]

	puts $spread_id [format "Throughput Maximumn Query Stream Time, %f" $max_query_run]
	puts $spread_id [format "Refresh1, %f" $refresh1]
	puts $spread_id [format "Refresh2, %f" $refresh2]
	puts $spread_id [format "Streams, %d" $streams]
	puts $spread_id [format "Run Count, %d" $runcnt]
	puts $spread_id ",Run Average"

	for {set i 1}  {$i <= 22} {incr i 1} {
		puts $spread_id [format "Query %d, %f"  \
			$i [expr {($queries($i)*1.0)/$runcnt} ] ]
	}
}

proc Not_provided {not_name } {
	puts "\n\nHey, you need to run the $not_name test for these results to be meaningful."
	puts "\tSo go back and run them!"
	puts "\tWork stoppage until management provides required tools."
	exit
}

#
# main of program
#
set log_name "./hammerora.log"
set spread_base "tpc_h_raw.csv"
set error_exit 0
#
# Parse the arguments
#
if {$argc < 1 | $argc > 2 } { Put_error_exit }
if {$argc == 2} {
	if {[string equal -nocase [lindex $argv 1] "-v" ] == 1 } {
		set verbose 1
	} else { Put_error_exit }
}

# Otherwise set use the first argv for the results directory 
# and create a csv output file placed into the results directory.
# The results directory must already exist and the output file
# will be replace if it already exists.
#
set log_dir [lindex $argv 0]
set spread_name [file join $log_dir $spread_base]
if [catch {open $spread_name w 0600} spread_id] {
	puts stderr [format "ERROR: Cannot create output file %s." $spread_name]
	exit
}
if {$verbose} {puts "Successfully created output file"}

set p_throughput [file join $log_dir "power_throughput.xml"]
if {[file exists $p_throughput] == 1 } {
	if {$verbose} {puts "Power Throughput File exists \n\t== $p_throughput"}
	Get_throughput_xml $p_throughput $verbose
	Parse_log_xml $verbose
	set max_query_run [expr {$queries(0)/1000.0}]
	for {set i 0 } {$i <=22 } {incr i } {
		set $queries($i) 0
	}
} else {
	Not_provided "power"
}

if {$verbose} {puts "\nPower Query time is $max_query_run seconds\n"}

set p_log [file join $log_dir "power_log.xml"]
if {[file exists $p_throughput] == 1 } {
	if {$verbose} {puts "Power Log File exists \n\t== $p_log"}
	Get_throughput_xml $p_log $verbose
	Parse_power_log_xml $verbose
	if {$verbose} {puts "Refresh1 is $refresh1 seconds" }
	if {$verbose} {puts "Refresh2 is $refresh2 seconds" }
} else {
	Not_provided "power"
}

set run_dir_cnt 1
set max_threads -1
while {1} {
	set run_dir [file join $log_dir [format "throughput_%05d" $run_dir_cnt]]
	if {[file isdirectory $run_dir] == 0 } break
	if {$verbose} {puts "Directory $run_dir is there!"}
	set run_log_cnt 1
	while {1} {
		set run_log [file join $run_dir [format "tlog_%02d.xml" $run_log_cnt]]
		if {[file exists $run_log] == 0 } break
		if {$verbose} {puts "\tFile $run_log is there!"}
		incr num_threads
		Get_throughput_xml $run_log $verbose
		Parse_log_xml $verbose
		incr run_log_cnt
	}
	if {$max_threads < 0 } {
		set max_threads $run_log_cnt
	} else {
		if {$max_threads != $run_log_cnt } {
			puts "ERROR: For iteration $run_dir_cnt and thread $run_log_cnt."
			puts "       Thread count doesn't match."
			exit
		}
	}
	incr run_dir_cnt
}
if {$max_threads == -1} { Not_provided "throughput" }
if {$verbose} {incr run_dir_cnt -1}
if {$verbose} {incr max_threads -1}
if {$verbose} {puts "Total iterations $run_dir_cnt" }
if {$verbose} {puts "With $max_threads per iteration" }
if {$verbose} {
	for {set i 1} {$i <= 22 } {incr i} {
		puts [format "Sum for query(%2d) is %10d and its average is %10.2f" \
	      	$i $queries($i) [expr {($queries($i) * 1.0) / ( $run_dir_cnt * $max_threads) } ] ]
	}
	puts [format "\nFor the sessions the sum is %10d and the average is %10.2f" \
      		$queries(0) [expr {($queries(0)*1.0) / ( $run_dir_cnt * $max_threads) } ] ]
}
Putheader $verbose $spread_id $max_threads $run_dir_cnt 
puts ".csv file generated"
exit
	
