# Ce script supprime toutes les versions SNAPSHOT de plus de 5 jours
# ##
# ## Une version SNAPSHOT se trouve dans une arborescence
# ##   (relative a la racine du repo) du type
# ## "${PACKAGES}/{X.X}-SNAPSHOT/${ARTIFACT}-${X.X}-${TIMESTAMP}-${NUMBUILD}${EXTENSION}.${FILETYPE}"
# ## où##   ${PACKAGES}: est l'arborescence des packages (groupId pour Maven)
# ##   ${X.X}: est le numero de version du logiciel en cours de fabrication
# ##   ${ARTIFACT}: est le nom de l'artifact
# ##   ${TIMESTAMP}: est la date/heure de fabrication de la version snapshot
# ##   ${NUMBUILD}: est un numé incrénte àhaque build
# ##   ${EXTENSION}: correspond au "classifier" Maven, il vaut soit "" pour les jar,
# ##      soit "-client" pour les jar EJB client
# ##   ${FILETYPE} est le type d'artifact d'extension du fichier ("pom", "war", "jar", "ear", "xml", etc.)
# ##
# ## Exemples:
# ##
# ## local_repo/com/gl/app/uainf/uainf-j2ee/1.0-SNAPSHOT/uainf-j2ee-1.0-20070518.090301-277-site.xml
# ## local_repo/com/gl/app/uainf/uainf-j2ee/1.0-SNAPSHOT/uainf-j2ee-1.0-20070518.090301-277.pom
# ## local_repo/com/gl/app/uainf/uainf-i02-ai/1.0-SNAPSHOT/uainf-i02-ai-1.0-20070516.170256-254-client.jar
# ## local_repo/com/gl/app/uainf/uainf-i02-ai/1.0-SNAPSHOT/uainf-i02-ai-1.0-20070516.170256-254.jar
# ## local_repo/com/gl/app/uainf/uainf-poceidon-complet/1.0-SNAPSHOT/uainf-poceidon-complet-1.0-20070516.140619-258.pom
# ## local_repo/com/gl/app/uainf/uainf-pon-ihm/1.0-SNAPSHOT/uainf-pon-ihm-1.0-20070518.090301-280.war
# ##
# ##
# ####################################################################

date

# Purge all files older than 5 days
find /s2ijtdev/mavendata/repo/ch/capbs -mtime +5 -type f | egrep -e "^.+-SNAPSHOT/.*-200[0-9]+\.[0-9]+-[0-9]+.*\..*$" | while read myfile; do echo "$myfile" ; rm "$myfile" ; done

# Purge all WARs and ZIPs older than 24 hours
find /s2ijtdev/mavendata/repo/ch/capbs -mtime +0 -type f -name '*.war' -o -name '*.zip' | egrep -e "^.+-SNAPSHOT/.*-200[0-9]+\.[0-9]+-[0-9]+.*\..*$" | while read myfile; do echo "$myfile" ; rm "$myfile" ; done

echo "BUILD SUCCESSFUL"
exit 0
