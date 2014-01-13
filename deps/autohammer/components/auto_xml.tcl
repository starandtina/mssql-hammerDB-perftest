#
# NOTE: Origial code came from someplace else but
# I can't find it right now.
# So derived from work written by ....
#
# Distributed under GPL 2.2
# Copyright Steve Shaw 2003-2012
# Copyright Tim Witham 2012
#
#
global rdbms_info f_info xml_info logged 
set err_flg 0
set logged  0
namespace eval ::XML { variable XML "" loc 0 }
proc ::XML::Init {xmlData} {
    variable XML
    variable loc

    set XML [string trim $xmlData];
    regsub -all {<!--.*?-->} $XML {} XML        ;# Remove all comments
    set loc 0
}
# ::XML::IsWellFormed
 #  checks if the XML is well-formed )http://www.w3.org/TR/1998/REC-xml-19980210)
 #
 # Returns "" if well-formed, error message otherwise
 # missing:
 #  characters: doesn't check valid extended characters
 #  attributes: doesn't check anything: quotes, equals, unique, etc.
 #  text stuff: references, entities, parameters, etc.
 #  doctype internal stuff
 #
proc ::XML::IsWellFormed {} {
    set result [::XML::_IsWellFormed]
    set ::XML::loc 0
    return $result
}
proc ::XML::_IsWellFormed {} {
    array set emsg {
        XMLDECLFIRST "The XML declaration must come first"
        MULTIDOCTYPE "Only one DOCTYPE is allowed"
        INVALID "Invalid document structure"
        MISMATCH "Ending tag '$val' doesn't match starting tag"
        BADELEMENT "Bad element name '$val'"
        EOD "Only processing instructions allowed at end of document"
        BADNAME "Bad name '$val'"
        BADPI "No processing instruction starts with 'xml'"
    }

    # [1] document ::= prolog element Misc*
    # [22] prolog ::= XMLDecl? Misc* (doctypedecl Misc*)?
    # [27] Misc ::= Comment | PI | S
    # [28] doctypedecl ::= <!DOCTYPE...>
    # [16] PI ::= <? Name ...?>
    set seen 0                                  ;# 1 xml, 2 pi, 4 doctype
    while {1} {
        foreach {type val attr etype} [::XML::NextToken] break
        if {$type eq "PI"} {
            if {! [regexp {^[a-zA-Z_:][a-zA-Z0-9.-_:\xB7]+$} $val]} {
                return [subst $emsg(BADNAME)]
            }
            if {$val eq "xml"} {                ;# XMLDecl
                if {$seen != 0} { return $emsg(XMLDECLFIRST) }
                # TODO: check version number exist and only encoding and
                # standalone attributes are allowed
                incr seen                       ;# Mark as seen XMLDecl
                continue
            }
            if {[string equal -nocase "xml" $val]} {return $emsg(BADPI)}
            set seen [expr {$seen | 2}]         ;# Mark as seen PI
            continue
        } elseif {$type eq "XML" && $val eq "!DOCTYPE"} { ;# Doctype
            if {$seen & 4} { return $emsg(MULTIDOCTYPE) }
            set seen [expr {$seen | 4}]
            continue
        }
        break
    }

    # [39] element ::= EmptyElemTag | STag content ETag
    # [40] STag ::= < Name (S Attribute)* S? >
    # [42] ETag ::= </ Name S? >
    # [43] content ::= CharData? ((element | Reference | CDSect | PI | Comment) CharData?)*
    # [44] EmptyElemTag ::= < Name (S Attribute)* S? />
    #

    set stack {}
    set first 1
    while {1} {
        if {! $first} {                         ;# Skip first time in
            foreach {type val attr etype} [::XML::NextToken] break
        } else {
            if {$type ne "XML" && $type ne "EOF"} { return $emsg(INVALID) }
            set first 0
        }

        if {$type eq "EOF"} break
        ;# TODO: check attributes: quotes, equals and unique

        if {$type eq "TXT"} continue
        if {! [regexp {^[a-zA-Z_:][a-zA-Z0-9.-_:\xB7]+$} $val]} {
            return [subst $emsg(BADNAME)]
        }

        if {$type eq "PI"} {
            if {[string equal -nocase xml $val]} { return $emsg(BADPI) }
            continue
        }
        if {$etype eq "START"} {                ;# Starting tag
            lappend stack $val
        } elseif {$etype eq "END"} {            ;# </tag>
            if {$val ne [lindex $stack end]} { return [subst $emsg(MISMATCH)] }
            set stack [lrange $stack 0 end-1]
            if {[llength $stack] == 0} break    ;# Empty stack
        } elseif {$etype eq "EMPTY"} {          ;# <tag/>
        }
    }

    # End-of-Document can only contain processing instructions
    while {1} {
        foreach {type val attr etype} [::XML::NextToken] break
        if {$type eq "EOF"} break
        if {$type eq "PI"} {
            if {[string equal -nocase xml $val]} { return $emsg(BADPI) }
            continue
        }
        return $emsg(EOD)
    }
    return ""
 }
 
 # Returns {XML|TXT|EOF|PI value attributes START|END|EMPTY}
 proc ::XML::NextToken {{peek 0}} {
    variable XML
    variable loc

    set n [regexp -start $loc -indices {(.*?)\s*?<(/?)(.*?)(/?)>} \
               $XML all txt stok tok etok]
    if {! $n} {return [list EOF]}
    foreach {all0 all1} $all {txt0 txt1} $txt \
        {stok0 stok1} $stok {tok0 tok1} $tok {etok0 etok1} $etok break

    if {$txt1 >= $txt0} {                       ;# Got text
        set txt [string range $XML $txt0 $txt1]
        if {! $peek} {set loc [expr {$txt1 + 1}]}
        return [list TXT $txt]
    }

    set token [string range $XML $tok0 $tok1]   ;# Got something in brackets
    if {! $peek} {set loc [expr {$all1 + 1}]}
    if {[regexp {^!\[CDATA\[(.*)\]\]} $token => txt]} { ;# Is it CDATA stuff?
        return [list TXT $txt]
    }

    # Check for Processing Instruction <?...?>
    set type XML
    if {[regexp {^\?(.*)\?$} $token => token]} {
        set type PI
    }
    set attr ""
    regexp {^(.*?)\s+(.*?)$} $token => token attr

    set etype START                             ;# Entity type
    if {$etok0 <= $etok1} {
        if {$stok0 <= $stok1} { set token "/$token"} ;# Bad XML
        set etype EMPTY
    } elseif {$stok0 <= $stok1} {
        set etype END
    }
    return [list $type $token $attr $etype]
 }

proc Get_throughput_xml {run_log verbose} {
	if [catch {open $run_log r} run_fd] {
		puts [format "ERROR: Unable to open log file ==%s==" $run_log]
		exit
	}

	set xml_in [read $run_fd]
	::XML::Init $xml_in

	set wellFormed [::XML::IsWellFormed]

 	if {$wellFormed ne ""} {
    		puts "XML-is NOT well-formed - fix the run_config.xml" 
		exit
 	} 
	if {$verbose} { puts "\tXML log \n\t\t==$run_log==\n\tis well-formed" }
	close $run_fd
}

proc Parse_power_log_xml { verbose } {
global queries refresh1 refresh2 max_query_run

	set load_name null
	set refis     0
	set refresh1 -1
	set refresh2 -1
	while {1} {
       	foreach {type val attr etype} [::XML::NextToken] break
		if {$type == "EOF"} {
			return
		}
     	if {$type == "XML" && $etype == "START"} {
			switch $val {
				refresh1   { set refis 1 
                             set load_name null
				}
				refresh2   { set refis 2
                             set load_name null
				}
				msec       { set load_name msec }
				default	   { set refis 0
							 set load_name null
				}
			}
		}
		if {$type == "TXT"} { 
				if { $load_name == "msec" } {
					if {$refis == 1 } { set refresh1 [ expr {$val / 1000.0 } ] }
					if {$refis == 2 } { set refresh2 [ expr {$val / 1000.0 } ] }
			}
		}

     	if {$type == "XML" && $etype == "END"} {
				if {$refis == 1 } {
						if {$refresh1 < 0 } {
								puts "No time value for refresh1 quitting"
								exit
						}
				}
				if {$refis == 2 } {
						if {$refresh2 < 0 } {
								puts "No time value for refresh2 quitting"
								exit
						}
				}
		}
	}

}

proc Parse_log_xml { verbose } {
global queries refresh1 refresh2 max_query_run
	set f_param 0
	set query 0
	set session 0
	set load_name "NULL"
	while {1} {
       	foreach {type val attr etype} [::XML::NextToken] break
		if {$type == "EOF"} {
			return
		}
     	if {$type == "XML" && $etype == "START"} {
			switch $val {
				query   { set qnum -1
					      set msec -1
						  set query 1
						  set session 0
				        }
				msec    { set load_name msec }
				number  { set load_name number }
				session { set qnum -1
					      set msec -1
						  set query 0
						  set session 1
				        }
				default { set qnum -1
						  set msec -1
						  set query 0
						  set session 0
				  		}
			}
		}
		#
		# Now set the data values
		#
		if {$type == "TXT"} { 
			if {$load_name == "msec"} { set msec $val}
			if {$load_name == "number"} { set qnum $val }

		}
		#
		# Add the values and move on
		#
     	if {$type == "XML" && $etype == "END"} {
			switch $val {
				query {
						if {($qnum >= 0) && ($msec >= 0)} {
							incr queries($qnum) $msec
						} else {
								puts "ERROR: QUERY $qnum didn't have both a number or a time"
								exit
						}
				}
		  		session {
						if {($qnum >= 0) && ($msec >= 0)} {
							incr queries(0) $msec
						} else {
							puts "ERROR: SESSION $qnum didn't have both a number or a time"
							exit
						}
						if {$msec > $max_query_run} {set max_query_run $msec}
			  	}
		  	}
		}
	}
}

proc Parse_tpcds_query_log_xml { infile verbose } {
#global queries refresh1 refresh2 max_query_run
	set f_param 0
	set query 0
	set session 0
	set load_name "NULL"
	while {1} {
       	foreach {type val attr etype} [::XML::NextToken] break
		if {$type == "EOF"} {
			return
		}
     	if {$type == "XML" && $etype == "START"} {
			switch $val {
				query   { set qnum -1
					      set msec -1
						  set query 1
						  set session 0
				        }
				msec    { set load_name msec }
				number  { set load_name number }
				session { set qnum -1
					      set msec -1
						  set query 0
						  set session 1
				        }
				default { set qnum -1
						  set msec -1
						  set query 0
						  set session 0
				  		}
			}
		}
		#
		# Now set the data values
		#
		if {$type == "TXT"} { 
			if {$load_name == "msec"} { set msec $val}
			if {$load_name == "number"} { set qnum $val }

		}
		#
		# Add the values and move on
		#
     	if {$type == "XML" && $etype == "END"} {
			switch $val {
				query {
						if {($qnum >= 0) && ($msec >= 0)} {
							incr queries($qnum) $msec
						} else {
								puts "ERROR: QUERY $qnum didn't have both a number or a time"
								exit
						}
				}
		  		session {
						if {($qnum >= 0) && ($msec >= 0)} {
							incr queries(0) $msec
						} else {
							puts "ERROR: SESSION $qnum didn't have both a number or a time"
							exit
						}
						if {$msec > $max_query_run} {set max_query_run $msec}
			  	}
		  	}
		}
	}
}


proc Get_config_xml {} {
global rdbms_info f_info xml_info logged 
	set f_info(xml_name) "run_config.xml"
	set f_info(xml_file) [file join $f_info(cmd_dir) $f_info(xml_name)]
	if [catch {open $f_info(xml_file) r } f_info(xml_fd)] {
		puts [format "ERROR: Unable to open xml_config file ==%s==" $f_info(xml_file)]
		exit
	}
	set xml_info(xml) [read $f_info(xml_fd)]
	::XML::Init $xml_info(xml)

	set wellFormed [::XML::IsWellFormed]

 	if {$wellFormed ne ""} {
    		puts "XML-is NOT well-formed - fix the run_config.xml" 
		exit
 	} 
	close $f_info(xml_fd)
}

proc Parse_xml_config { } {
global rdbms_info f_info xml_info logged 
# FIX - Don't think I need this anymore done through XML config file (run_config.xml)
# lists and dict for config section
#set c_list [list step rdbms background test server port authentication server_id server_pass uid ODBC_driver warehouses database_name ]
#set c_def  [dict create background "no" server_id ""]
#set c_reg [list rdbms background test server port authentication server_id server_pass uid ODBC_driver warehouses database_name ]
# lists and dict for sql with parameters section
#set p_def  [dict create background "no" trace_sql "no"]
#set p_list [list step sec_name file_in param_list]
#set p_reg  [list step sec_name file_in param_list]
# lists and dict for sql section
#set s_def  [dict create background "no" trace_sql "no"]
#set s_list [list step sec_name file_in]
#set s_reg  [list sec_name file_in]
# lists and dict for tcl section
#set t_def  [dict create background "no"]
#set t_list [list step sec_name file_in call background threads]
#set t_reg  [list sec_name file_in call background threads]

	set f_param 0
	while {1} {
       		foreach {type val attr etype} [::XML::NextToken] break
		if {$type == "EOF"} {
			exit
		}
       		if {$type == "XML" && $etype == "START"} {
			switch $val {
				autohammer      { set rdbms_info(h_start) 1 }
				background      { set load_name background }
				backup_file_db  { set load_name backup_file_db }
				backup_file_log { set load_name backup_file_log }
				database_name   { set load_name database_name }
				call            { set load_name call        }
				cmd             { set load_name cmd        }
				component       { set load_name component }
				config	        { }
				connect         { }
				checkpoint_time { set load_name checkpoint_time }
				disconnect      { }
				exit_sql_error  { set load_name exit_sql_error }
				file_log        { set load_name file_log }
				histogram       { set load_name histogram }
				key_and_think   { set load_name key_and_think }
				ms_delay        { set load_name ms_delay }
				ms_repeat       { set load_name ms_repeat }
				p_name          { set load_name p_name }
				p_value		{ set load_name p_value}
				test_params     { set f_param 1 }
				port            { set load_name port }
				ramp_min        { set load_name ramp_min }
				repeat          { set load_name repeat }
				run_cmd         { }
				run_sql         { }
				run_tcl         { }
				rdbms           { set load_name rdbms }
				seconds         { set load_name seconds }
				script          { set load_name script }
				sec_name        { set load_name sec_name }
				sql_params      { set load_name sql_params }
				sys_info        { set load_name sys_info }
				step            { set load_name step        }
				stop            { set load_name stop        }
				test            { set load_name test }
				test_cnt        { set load_name test_cnt }
				test_min        { set load_name test_min }
				user_cnt        { set load_name user_cnt }
				warehouses      { set load_name warehouses }
				default         { 
						if { $f_param == 1 }  { 
							set load_name $val
						} else {		
							puts [format "ERROR: \"%s\" is not a default parameter-Use \<test_param\> to define." $val] 
					        	exit
						}
				}
			}
			continue
		}
		if {$type == "XML" && $etype == "END"} { 
			switch $val {
				autohammer      { return "end_it" }
				connect         { return connect}
				config	        { return "config"}
				disconnect      { return disconnect}
				run_cmd	        { return run_cmd}
				run_sql	        { return run_sql}
				run_tcl	        { return run_tcl }
				sys_info        { return sys_info }
				test_params     { set f_param 0 }
			 }
			if {![info exists rdbms_info($load_name)]} {
				set rdbms_info($load_name) ""
			}
		}
		if {$type == "TXT"} { 
			#
			# will need to add some sort of validation for the parameters that
			# have acceptable ranges
			# need to check $rdbms_info(param_list) against the entered parameters
			#
			set rdbms_info($load_name) $val
		}
		if {$type == "EOF"} {return "end_it"}
			
	}
	puts "You shouldn't see this"
}	

# Don't think I need this any more
# FIX
#
proc Clean_params {list_in def_in } {
global rdbms_info f_info xml_info logged 
	foreach f  $list_in { unset -nocomplain rdbms_info($f) }
	# need dictionary call to set the defaults
	set rdbms_info(c_list) $list_in
}


