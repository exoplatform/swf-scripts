def organization = 'exoplatform'
def contentApi = new URL("https://api.github.com/orgs/${organization}/repos?type=source&per_page=100")
def projects = new groovy.json.JsonSlurper().parse(contentApi.newReader())

def jobNamePrefix = 'addon'
def jobNameSuffix = 'release-ci'
def branchPrefix = 'release'
def mavenGoals = 'install -Pexo-release'

def supportedAddons = ['acme-sample': '4.3.x', 'answers': '1.1.x', 'cas-addon': '1.1.x', 'cmis-addon': '4.3.x', 'josso-addon': '1.1.x', 'openam-addon': '1.1.x', 'saml2-addon': '1.1.x', 'spnego-addon': '1.1.x', 'ide': '1.5.x' ]

projects.each {

    if (supportedAddons.containsKey(it.name)) {
        // All projects attributes
        def projectName = it.name
        def projectVersion = supportedAddons["${projectName}"]
        def gitURL = it.git_url
        def htmlURL = it.html_url

        // Syntax for Release CI Jobs
        mavenJob("${jobNamePrefix}-${projectName}-${projectVersion}-${jobNameSuffix}") {

            logRotator(15, 15)

            authorization {
                permission('hudson.model.Item.Read', 'anonymous')
                permission('hudson.model.Item.Build', 'exo-profile-addons-release-manager')
            }

            jdk('Oracle Java SDK 1.7.0 64bits')

            properties {
                githubProjectUrl("${htmlURL}")
                label('ci')
            }

            triggers {
                snapshotDependencies(true)
                githubPush()
                scm("H * * * *")
                cron("H 13 * * 6")
            }

            scm {
                git {
                    remote {
                        github("${organization}/${projectName}", 'ssh')
                    }
                    branch("origin/${branchPrefix}/${projectVersion}")

                    // Additional Behaviours
                    relativeTargetDir("sources")
                    createTag(true)
                    clean(true)
                    pruneBranches(true)
                    localBranch("${branchPrefix}/${projectVersion}")

                }

            }
            mavenInstallation("maven-3.2.x")
            rootPOM("sources/pom.xml")
            goals("${mavenGoals}")

            wrappers {
                timeout {
                    absolute(120)
                    failBuild()
                    writeDescription('Build timed out (after {0} minutes). Marking the build as failed.')
                }
            }

            postBuildSteps('FAILURE') {
                publishers {
                    deployArtifacts {
                        uniqueVersion(true)
                    }
                    mavenDeploymentLinker('.*zip$')
                    allowBrokenBuildClaiming()
                    extendedEmail('exo-swf-notifications@exoplatform.com', '$DEFAULT_SUBJECT', '$DEFAULT_CONTENT')

                    //
                    configure { project ->
                        project / 'publishers' << 'hudson.plugins.jira.JiraIssueUpdater'(plugin: 'jira@1.39')
                    }
                }
            }
        }

    }
}
