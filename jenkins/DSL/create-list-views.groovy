def nestedViewName = "${NESTED_VIEW_NAME}"
def list =  "${LIST_VIEW_NAMES}"
def listViewNames = list.split()
def jenkinsDSLJobName = "${DSL_JOB_NAME}"


nestedView(nestedViewName) {
  description("<b><span style='color:red'>DO NOT EDIT HERE!</span></b> <br/> View generated by Groovy DSL @ <a href='https://ci.exoplatform.org/job/${jenkinsDSLJobName}'>${jenkinsDSLJobName}</a>")
  views {
    for (view in listViewNames) {
      listView("${view}") {
        description("<b><span style='color:red'>DO NOT EDIT HERE!</span></b> <br/> View generated by Groovy DSL @ <a href='https://ci.exoplatform.org/job/${jenkinsDSLJobName}'>${jenkinsDSLJobName}</a>")
        jobs {
          regex(".*-${view}-.*")
        }
        columns {
          status()
          weather()
          name()
          lastSuccess()
          lastFailure()
          lastDuration()
          buildButton()
        }
      }
    }
  }
}
