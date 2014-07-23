SEP="`echo | tr '\n' '\001'`"
find . -name $3 -exec sed -i "" "s${SEP}$1${SEP}$2${SEP}g" {} \;
#find . -name pom.xml -exec sed -i ".sav" "s#$1#$2#g" {} \;
