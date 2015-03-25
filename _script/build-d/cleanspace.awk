/^[^"']*$/ {
    gsub( /(\> +\<)/, " " );
    $0 = gensub( /(\w) +(\w)/, "\\1 \\2", "g" );
    $0 = gensub( /([^ 0-9a-z_]) +/, "\\1 ", "g" );
    $0 = gensub( /(\w) +(\W)/, "\\1 \\2", "g" );

    # space after brackets
    $0 = gensub( /([\[{(,]) +/, "\\1", "g" );

    # space before brackets
    $0 = gensub( / +([\]})])/, "\\1", "g" );

    # space at line end
    $0 = gensub( / +$/, "", "g" );

    print $0;
}
/['"]/ {
    $0 = gensub( /^ *(\\ *'[^']+') *: */, "\\1:", "g" );
    print $0;
}

# vim: tabstop=2
