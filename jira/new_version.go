package main

/*
Creation :
Post https://jira.exoplatform.org/rest/api/2/version
name	swf-2017-W37 (Current)
project	SWF
userStartDate	11/Sep/17
userReleaseDate	17/Sep/17
expand	operations

Rename :
POST https://jira.exoplatform.org/rest/api/2/version/26999
id	26999
name	swf-2017-W36
userStartDate	4/Sep/17
expand	operations


Release :
PUT https://jira.exoplatform.org/rest/api/2/version/26999
id	26976
userReleaseDate	10/Sep/17
released	true
expand	operations
moveUnfixedIssuesTo	26982
*/

import (
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"regexp"
	"strconv"
	"strings"
	"time"

	jira "github.com/andygrunwald/go-jira"
	survey "gopkg.in/AlecAivazis/survey.v1"
	kingpin "gopkg.in/alecthomas/kingpin.v2"
)

var (
	username   = kingpin.Flag("username", "Jira user name").Short('u').String()
	password   = kingpin.Flag("password", "Jira password (not recommanded to put the password on the command line").Short('p').String()
	jiraURL    = kingpin.Flag("jiraUrl", "the url to reach jira").Default("https://jira.exoplatform.org").String()
	project    = kingpin.Arg("project", "the project to upgrade").String()
	firstDay   string
	lastDay    string
	jiraClient *jira.Client
)

func createOrGetVersion(project *jira.Project, newVersionName string, newFullVersionName string) (newVersion jira.Version) {
	fmt.Println("Searching if current version exists...")
	newVersion, err := searchProjectVersion(project, newVersionName)
	if err != nil {
		fmt.Println("Version " + newVersionName + " not found")
		newVersion, err = searchProjectVersion(project, newFullVersionName)
		if err != nil {
			fmt.Println("Version " + newFullVersionName + " not found")
			fmt.Println("Creating version " + newFullVersionName)
			projectID, _ := strconv.Atoi(project.ID)
			newVersion = jira.Version{Name: newFullVersionName, Archived: false, Released: false, ProjectID: projectID, StartDate: firstDay, ReleaseDate: lastDay}
			jiraClient.Version.Create(&newVersion)
		} else {
			fmt.Println("Version " + newFullVersionName + " already exists")
		}
	} else {
		fmt.Println("Version " + newVersionName + "found, it needs to be renamed to " + newFullVersionName)
		newVersion.Name = newFullVersionName
		newVersion.StartDate = firstDay
		newVersion.ReleaseDate = lastDay
		jiraClient.Version.Update(&newVersion)
	}
	return
}

func changeIssuesVersion(previousVersion jira.Version, newVersion jira.Version) error {
	return nil
}

func releaseVersion(version jira.Version) error {
	return nil
}

func connectToJira(url string, u string, p string) *jira.Client {
	jiraClient, err := jira.NewClient(nil, *jiraURL)
	if err != nil {
		panic(err)
	}
	jiraClient.Authentication.SetBasicAuth(*username, *password)
	return jiraClient
}

func getProject(client *jira.Client, projectName string) (project *jira.Project) {
	project, _, err := client.Project.Get(projectName)
	if err != nil {
		panic(err)
	}
	return
}

func getCurrentProjectVersion(project *jira.Project) (currentVersion jira.Version) {
	// Find the first unreleased version matching the pattern projectname-YYYY-
	re := regexp.MustCompile(fmt.Sprintf("%s-[0-9]{4}-", strings.ToLower(project.Key)))

	for _, version := range project.Versions {
		// fmt.Println(fmt.Sprintf("version=%s archived=%t released=%t releasedDate=%s, userReleaseDate=%s", version.Name, version.Archived, version.Released, version.ReleaseDate, version.UserReleaseDate))
		if version.Released == false && currentVersion.Name == "" {
			// fmt.Println("Checking " + version.Name)
			// fmt.Println(re.MatchString(version.Name))
			if re.MatchString(version.Name) {
				currentVersion = version
			}
		}
	}

	return
}

func searchProjectVersion(project *jira.Project, name string) (result jira.Version, err error) {

	for _, version := range project.Versions {
		if version.Name == name {
			result = version
		}
	}
	if result.Name == "" {
		err = errors.New("Version not found")
	}
	return
}

func getFirstWeekDay(d time.Time) (firstDay string) {
	wd := d.Weekday()
	daysFromFirstDay := int(wd) - 1

	firstDayTime := d.AddDate(0, 0, -daysFromFirstDay)
	firstDay = fmt.Sprintf("%d-%02d-%02d", firstDayTime.Year(), firstDayTime.Month(), firstDayTime.Day())

	return
}

func getLastWeekDay(d time.Time) (lastDay string) {
	wd := d.Weekday()
	daysToLastDay := 7 - int(wd)

	lastDayTime := d.AddDate(0, 0, daysToLastDay)
	lastDay = fmt.Sprintf("%d-%02d-%02d", lastDayTime.Year(), lastDayTime.Month(), lastDayTime.Day())

	return
}

func main() {

	kingpin.Parse()

	if *username == "" {
		envValue, present := os.LookupEnv("username")
		if present {
			*username = envValue
		} else {
			prompt := &survey.Input{
				Message: "Please type your jira username ",
			}
			survey.AskOne(prompt, username, nil)
		}
	}
	if *password == "" {
		envValue, present := os.LookupEnv("password")
		if present {
			*password = envValue
		} else {
			prompt := &survey.Password{Message: fmt.Sprintf("Please type your jira password for user [%s] : ", *username)}
			survey.AskOne(prompt, password, nil)
		}
	}

	if *project == "" {
		prompt := &survey.Input{Message: fmt.Sprintf("Add a version on which project : ")}
		survey.AskOne(prompt, project, nil)
	}

	d := time.Now()

	_, wd := d.ISOWeek()

	firstDay = getFirstWeekDay(d)
	lastDay = getLastWeekDay(d)

	jiraClient = connectToJira(*jiraURL, *username, *password)

	project := getProject(jiraClient, *project)

	fmt.Println("project : " + project.Key)

	newVersionName := fmt.Sprintf("%s-%d-W%d", strings.ToLower(project.Key), d.Year(), wd)
	newFullVersionName := fmt.Sprintf("%s (current)", newVersionName)

	currentVersion := getCurrentProjectVersion(project)

	fmt.Println("")
	fmt.Println("Current version : " + currentVersion.Name)
	fmt.Println("New version : " + newVersionName)
	fmt.Println("First day : " + firstDay)
	fmt.Println("Last day : " + lastDay)
	fmt.Println("")

	newVersion := createOrGetVersion(project, newVersionName, newFullVersionName)

	fmt.Println("New version " + newVersion.Name + " prepared")
	fmt.Println("Searching for issue to move from version " + currentVersion.Name)

	issues, _, err := jiraClient.Issue.Search("project = "+project.ID+" AND resolution = Unresolved AND fixVersion = \""+currentVersion.Name+"\"", nil)
	if err != nil {
		fmt.Println("Unable to retrieve issues on current version")
		panic(err)
	}
	for _, issue := range issues {
		fmt.Println(fmt.Sprintf("Found issue %s %s", issue.Key, issue.Fields.Summary))
		fmt.Println("  Updating issue...")

		uri := fmt.Sprintf("rest/api/2/issue/%v", issue.ID)

		bodyJSON := fmt.Sprintf("{ \"update\": { \"fixVersions\": [ { \"set\": [ { \"name\" : \"%s\" } ] } ] } }", newFullVersionName)
		var body interface{}
		err := json.Unmarshal([]byte(bodyJSON), &body)

		fmt.Println(body)
		req, err := jiraClient.NewRequest("PUT", uri, body)
		if err != nil {
			fmt.Println("[ERROR] Error updating issue " + issue.Key)
			fmt.Println(err)
		} else {
			resp, err := jiraClient.Do(req, nil)
			if err != nil {
				fmt.Println("[ERROR] Error updating issue " + issue.Key)
				fmt.Println(err)
				fmt.Println(resp)
			}
		}
	}

	fmt.Println()

	newName := strings.Replace(currentVersion.Name, " (current)", "", 1)
	fmt.Println("Updating previous version name to |" + newName + "| and releasing it ...")
	currentVersion.Name = newName
	currentVersion.Released = true
	currentVersion.UserReleaseDate = ""
	_, resp, err := jiraClient.Version.Update(&currentVersion)
	if err != nil {
		fmt.Println("[ERROR] Error updating previous version")
		fmt.Println(err)
		fmt.Println(resp)
	}

}
