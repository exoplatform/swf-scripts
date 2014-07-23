for i in `find . -name "$2"`; do grep -H -i "$1" "$i"; done
