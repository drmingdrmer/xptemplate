$0 ~ /^ *\\/ {
    t = $0;
    gsub( /^ *\\ */, " ", t );
    last = last t;
}
$0 !~ /^ *\\/ {
    if ( last != "" ) {
        print last;
    }
    last = $0;
}
END{
    print last;
}
