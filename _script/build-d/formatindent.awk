{
    $0 = gensub( /^    /, "	", "g" );
    $0 = gensub( /^	    /, "		", "g" );
    $0 = gensub( /^		    /, "			", "g" );
    $0 = gensub( /^			    /, "				", "g" );
    $0 = gensub( /^				    /, "					", "g" );
    print $0;
}

# vim: tabstop=2
