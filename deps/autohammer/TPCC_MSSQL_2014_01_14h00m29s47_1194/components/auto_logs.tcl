#
#  Copyright Timothy D. Witham 2012
#  Distributed under GPL 2.2
#
proc Create_thread_log { log_id sec_name thread thread_dir file_pattern xlevel} {
	set tlog_name [ file join $thread_dir [format $file_pattern $thread ] ]
	Enter_log_item $log_id "thread_log" $tlog_name  $xlevel
	set tlog_id [open $tlog_name w]
	Put_thread_header $tlog_id $sec_name
	return $tlog_id
}

proc Put_thread_header { log_id sec_name } {
	set xlevel 0
	puts           $log_id "<?xml version=\"1.0\" encoding=\"utf-8\"?>"
	Enter_log_tag  $log_id "S" "autohammer" 1 xlevel
	Enter_log_tag  $log_id "S" $sec_name 1 xlevel
	flush          $log_id
}

proc Put_thread_footer { log_id sec_name } {
	set xlevel 2
	Enter_log_tag  $log_id "E" $sec_name 1 xlevel
	Enter_log_tag  $log_id "E" "autohammer" 1 xlevel
	flush          $log_id
}

#
# Routine to fix a string so it can be passed to a thead.  Needs to have
# quotes in the string also and backslashes need to be changed to two backslashes
#
proc Quote_slash { sin } {
	set split_sin [split $sin {\\} ]
	if { [llength $split_sin] < 2 } {
		return [format "\"%s\"" $sin ]
	} else {
		return [format "\"%s\"" [join $split_sin "\\\\"]]
	}
}
proc MS_tppc_stamp {ts_ms} {
	set ts_sec [expr {$ts_ms/1000}]
	set ts_ts [expr {($ts_ms % 1000)/100}]
	return [format "[clock format $ts_sec -format "%Y-%m-%dT%H:%M:%S"].%1d" $ts_ts]
}
proc MS_rngseed {ts_ms} {
	set ts_sec [expr {$ts_ms/1000}]
	set ts_ts [expr {($ts_ms % 1000)/100}]
	return [format "[clock format $ts_sec -format "%y%m%d%H%M%S"]%1d" $ts_ts]
}
	
proc Time_out { } {
	set ts_ms [clock milliseconds]
	return [MS_tppc_stamp $ts_ms]
}
	

#
#  Routine to place a time stamp in the log 
#  Parameters are: <S|E> <String>
#  Usual usage is "S" "Name" to time stamp the begining of a process
#  or             "E" "Name" to time stamp the ending of a process
#  but any string can be entered.
#

proc Time_stamp { log_id sf_flag ind} {
global rdbms_info f_info xml_info 
	set tabs ""
	for {set i 1 } { $i <= $ind } {incr i } { append tabs "\t" }
	set clock_string  [MS_tppc_stamp [clock milliseconds]]

	if {[string compare "S" $sf_flag] == 0} {
		puts  $log_id [format "%s<time_start>%s</time_start>" $tabs $clock_string]
		flush $log_id
		return
	} 
	if {[string compare "E" $sf_flag] == 0} {
		puts  $log_id [format "%s<time_end>%s</time_end>" $tabs $clock_string]
		flush $log_id
		return
	}
	puts  $log_id "<WARNING>%s Time stamp request neither S or E</WARNING>" 
	flush $log_id
	return
}

#
#
# Routine to place <tag>message</tag> into the log file
# 
# Enter_log_item <log file id> <tag> <string> <indentation level {0|1}>
#

proc Enter_log_item { log_id logtag logstring ind } {
global rdbms_info f_info xml_info 
	set tabs ""
	for {set i 1 } { $i <= $ind } {incr i } { append tabs "\t" }

	puts $log_id [format "%s<%s>%s</%s>" $tabs $logtag $logstring $logtag]
	flush $log_id
	return
}

# 
# To enter a single line into the log
# For be "S" for the start tag and "E" for the end tag
# For ts 1 indicates you want a time stamp 0 you do not
#

proc Enter_log_tag { log_id be logtag ts xlevel} {
global rdbms_info f_info xml_info 
upvar $xlevel ind
	set tabs ""

	if { [string compare "S" $be] == 0 } {
		for {set i 1 } { $i <= $ind } {incr i } { append tabs "\t" }
		puts $log_id [format "%s<%s>" $tabs $logtag]
		incr ind
		if {$ts} {Time_stamp $log_id "S" $ind }
		return
	}
	if { [string compare "E" $be] == 0 } {
		if {$ts} {Time_stamp $log_id "E" $ind }
		incr ind -1 
		for {set i 1 } { $i <= $ind } {incr i } { append tabs "\t" }
		puts $log_id [format "%s</%s>" $tabs $logtag]
		return
	}
	puts $log_id [format "ERROR: tried to create tag but no \"S\" or \"E\" ==%s==" $logtag]
#
# Can't use Error_out because of call loop 
#
	Time_stamp "E" 1
	puts $log_id [format "</%s>" $logtag]
	Time_stamp "E" 0
	puts $log_id "</autohammer>"
	return
}
#
proc xEnter_log_tag_no_ts { log_id be logtag ind} {
global rdbms_info f_info xml_info 
	set tabs ""
	for {set i 1 } { $i <= $ind } {incr i } { append tabs "\t" }

	if { [string compare "S" $be] == 0 } {
		puts $log_id [format "%s<%s>" $tabs $logtag]
		return
	}
	if { [string compare "E" $be] == 0 } {
		puts $log_id [format "%s</%s>" $tabs $logtag]
		return
	}
	puts $log_id [format "ERROR: tried to create tag but no \"S\" or \"E\" ==%s==" $logtag]
#
# Can't use Error_out because of call loop 
#
	Time_stamp "E" 1
	puts $log_id [format "</%s>" $logtag]
	Time_stamp "E" 0
	puts $log_id "</autohammer>"
	return
}

#
# Code to error out and exit if a section
# fails - to try and ensure that the xml is good
#
proc Error_out { log_id routine } {
global rdbms_info f_info xml_info 
set xlevel 1
	Enter_log_tag $log_id "E" $routine 1 xlevel
	Enter_log_tag $log_id "E" "autohammer" 1 xlevel
	exit
}

proc Load_sources { this_thread rdbms test_load} {
	set comp "components"
	set db_src  [file join $comp "auto_db.tcl"  ]
	set log_src [file join $comp "auto_logs.tcl"]
	set run_src [file join $comp $test_load     ]

	eval [subst {thread::send $this_thread {package require Thread }} ]
	set sk [string tolower $rdbms]
	switch $sk {
		mssql  { eval [subst {thread::send $this_thread {package require tclodbc }} ] }
		oracle { eval [subst {thread::send $this_thread {package require Oratcl }} ] }
		pgsql  { eval [subst {thread::send $this_thread {package require pgtcl }} ] }
		mysql  { eval [subst {thread::send $this_thread {package require mysqltcl }} ] }
	}

	eval [subst {thread::send $this_thread {source $db_src   }} ]
	eval [subst {thread::send $this_thread {source $log_src  }} ]
	eval [subst {thread::send $this_thread {source $run_src  }} ]
}

proc Load_source_directory { this_thread rdbms c_dir test_load} {
	set comp "components"
	set db_src  [file join $c_dir $comp "auto_db.tcl"  ]
	set log_src [file join $c_dir $comp "auto_logs.tcl"]
	set run_src [file join $c_dir $comp $test_load     ]

	eval [subst {thread::send $this_thread {package require Thread }} ]
	set sk [string tolower $rdbms]
	switch $sk {
		mssql  { eval [subst {thread::send $this_thread {package require tclodbc }} ] }
		oracle { eval [subst {thread::send $this_thread {package require Oratcl }} ] }
		pgsql  { eval [subst {thread::send $this_thread {package require pgtcl }} ] }
		mysql  { eval [subst {thread::send $this_thread {package require mysqltcl }} ] }
	}

	eval [subst {thread::send $this_thread {source $db_src   }} ]
	eval [subst {thread::send $this_thread {source $log_src  }} ]
	eval [subst {thread::send $this_thread {source $run_src  }} ]
}
