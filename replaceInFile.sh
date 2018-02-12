SEP="`echo | tr '\n' '\001'`"
if [ "${OSTYPE}" == darwin* ]; then
    find . -name $3 -exec ${EXO_FB_SED:-sed} -i "" "s${SEP}$1${SEP}$2${SEP}g" {} \;
elif [ "${OSTYPE}" == linux* ]; then
    find . -name $3 -exec ${EXO_FB_SED:-sed} -i "s${SEP}$1${SEP}$2${SEP}g" {} \;
else
    echo "Unsupported OS '${OSTYPE}'"
    exit 1
fi