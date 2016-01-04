SEP="`echo | tr '\n' '\001'`"
replaceInPom(){
  find ${WORKSPACE}/sources -name pom.xml -not -wholename "*/target/*" -exec sed -i "s${SEP}$1${SEP}$2${SEP}g" {} \;
}
replaceInPom "<version>${PROJECT_VERSION_IN_GIT}</version>" "<version>${JIPT_VERSION_TO_BUILD}</version>"
replaceInPom "<org.gatein.portal.version>${JIPT_GATEIN_VERSION_IN_GIT}</org.gatein.portal.version>" "<org.gatein.portal.version>${JIPT_GATEIN_VERSION_TO_BUILD}</org.gatein.portal.version>"
replaceInPom "<org.exoplatform.platform-ui.version>${JIPT_PLATFORM_VERSION_IN_GIT}</org.exoplatform.platform-ui.version>" "<org.exoplatform.platform-ui.version>${JIPT_PLATFORM_VERSION_TO_BUILD}</org.exoplatform.platform-ui.version>"
replaceInPom "<org.exoplatform.commons.version>${JIPT_PLATFORM_VERSION_IN_GIT}</org.exoplatform.commons.version>" "<org.exoplatform.commons.version>${JIPT_PLATFORM_VERSION_TO_BUILD}</org.exoplatform.commons.version>"
replaceInPom "<org.exoplatform.ecms.version>${JIPT_PLATFORM_VERSION_IN_GIT}</org.exoplatform.ecms.version>" "<org.exoplatform.ecms.version>${JIPT_PLATFORM_VERSION_TO_BUILD}</org.exoplatform.ecms.version>"
replaceInPom "<org.exoplatform.social.version>${JIPT_PLATFORM_VERSION_IN_GIT}</org.exoplatform.social.version>" "<org.exoplatform.social.version>${JIPT_PLATFORM_VERSION_TO_BUILD}</org.exoplatform.social.version>"
replaceInPom "<org.exoplatform.wiki.version>${JIPT_PLATFORM_VERSION_IN_GIT}</org.exoplatform.wiki.version>" "<org.exoplatform.wiki.version>${JIPT_PLATFORM_VERSION_TO_BUILD}</org.exoplatform.wiki.version>"
replaceInPom "<org.exoplatform.forum.version>${JIPT_PLATFORM_VERSION_IN_GIT}</org.exoplatform.forum.version>" "<org.exoplatform.forum.version>${JIPT_PLATFORM_VERSION_TO_BUILD}</org.exoplatform.forum.version>"
replaceInPom "<org.exoplatform.calendar.version>${JIPT_PLATFORM_VERSION_IN_GIT}</org.exoplatform.calendar.version>" "<org.exoplatform.calendar.version>${JIPT_PLATFORM_VERSION_TO_BUILD}</org.exoplatform.calendar.version>"
replaceInPom "<org.exoplatform.integ.version>${JIPT_PLATFORM_VERSION_IN_GIT}</org.exoplatform.integ.version>" "<org.exoplatform.integ.version>${JIPT_PLATFORM_VERSION_TO_BUILD}</org.exoplatform.integ.version>"
replaceInPom "<org.exoplatform.platform.version>${JIPT_PLATFORM_VERSION_IN_GIT}</org.exoplatform.platform.version>" "<org.exoplatform.platform.version>${JIPT_PLATFORM_VERSION_TO_BUILD}</org.exoplatform.platform.version>"
replaceInPom "<org.exoplatform.platform.distributions.version>${JIPT_PLATFORM_VERSION_IN_GIT}</org.exoplatform.platform.distributions.version>" "<org.exoplatform.platform.distributions.version>${JIPT_PLATFORM_VERSION_TO_BUILD}</org.exoplatform.platform.distributions.version>"
