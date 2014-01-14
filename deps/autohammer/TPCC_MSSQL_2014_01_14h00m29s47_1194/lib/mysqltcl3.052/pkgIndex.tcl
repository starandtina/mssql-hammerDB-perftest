
proc loadmysqltcl { dir } {
    set oldcwd [pwd]
    cd $dir
    load libmysqltcl[info sharedlibextension]
    cd $oldcwd
}

package ifneeded mysqltcl 3.052 [list loadmysqltcl $dir]
