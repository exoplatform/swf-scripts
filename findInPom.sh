for i in `find . -name pom.xml -not -wholename "*/target/*"`; do grep -H -i $1 $i; done
