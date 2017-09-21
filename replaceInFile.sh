SEP="`echo | tr '\n' '\001'`"
find . -name $3 -exec ${EXO_FB_SED:-sed} -i "" "s${SEP}$1${SEP}$2${SEP}g" {} \;
