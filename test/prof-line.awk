{
    # if it is a time consumption line
    if ( int($1) > 0 ) {
        printf "%5d ns ", int($2*1000*1000*1000/$1)
        print $0
    } else {
        print "----- -- " $0
    }
}
