package ifneeded Oratcl 4.5 \
    [list load [file join $dir Oratcl45.dll]]
package ifneeded Oratcl::utils 4.5 \
    [list source [file join $dir oratcl_utils.tcl]]
