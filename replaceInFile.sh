SEP="`echo | tr '\n' '\001'`"

case $OSTYPE in
    darwin*)
        find . -name $3 -exec ${EXO_FB_SED:-sed} -i "" "s${SEP}$1${SEP}$2${SEP}g" {} \;
    ;;
    linux*)
        find . -name $3 -exec ${EXO_FB_SED:-sed} -i "s${SEP}$1${SEP}$2${SEP}g" {} \;
    ;;
    default)
        echo "Unsupported OS '${OSTYPE}'"
        exit 1
esac