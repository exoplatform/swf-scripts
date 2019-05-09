package main

import (
	"context"
	"fmt"

	"log"

	"github.com/google/go-github/v25/github"
	"github.com/logrusorgru/aurora"
	"golang.org/x/crypto/ssh/terminal"
	"golang.org/x/oauth2"
)

var au aurora.Aurora
var githubClient *github.Client

var repositories []string

var exoplatformRepos map[string]*github.Repository
var exodevRepos map[string]*github.Repository
var exoaddonsRepos map[string]*github.Repository

func init() {
	au = aurora.NewAurora(true)

	repositories = []string{"gatein-dep", "gatein-wci", "social"}
}

func authenticate() *github.Client {
	fmt.Print("Enter your github access token : ")
	token, _ := terminal.ReadPassword(0)
	fmt.Println("")

	ctx := context.Background()
	ts := oauth2.StaticTokenSource(
		&oauth2.Token{AccessToken: string(token)},
	)
	tc := oauth2.NewClient(ctx, ts)

	githubClient = github.NewClient(tc)

	return githubClient
}

func checkQuota(response *github.Response) {
	rate := response.Rate
	log.Println(au.White(fmt.Sprintf("Remaining calls : %d", rate.Remaining)))
}

func loadOrganisationRepos(organisation string) map[string]*github.Repository {
	repositories := make(map[string]*github.Repository)

	opt := &github.RepositoryListByOrgOptions{
		ListOptions: github.ListOptions{PerPage: 100},
	}
	ctx := context.Background()

	for {
		page, resp, err := githubClient.Repositories.ListByOrg(ctx, organisation, opt)
		if err != nil {
			log.Println(err)
			log.Fatal(au.Red("Error getting the current user, check your authentication token"))
		}
		for _, repo := range page {
			repositories[*repo.Name] = repo
		}
		if resp.NextPage == 0 {
			break
		}
		opt.Page = resp.NextPage
	}
	return repositories
}

func main() {
	log.Println(au.Yellow("Github branch protection verifications tools"))
	ctx := context.Background()

	githubClient = authenticate()

	currentUser, response, err := githubClient.Users.Get(ctx, "")
	if err != nil {
		log.Println(err)
		log.Fatal(au.Red("Error getting the current user, check your authentication token"))
	}

	log.Println(au.White(fmt.Sprintf("Authenticated with user %s", *currentUser.Login)))
	checkQuota(response)

	log.Print(au.White("Loading exoplatform projects..."))
	exoplatformRepos := loadOrganisationRepos("exoplatform")
	log.Println(au.Green(fmt.Sprintf("%d repositories loaded", len(exoplatformRepos))))

	log.Print(au.White("Loading exodev projects..."))
	exodevRepos := loadOrganisationRepos("exo-dev")
	log.Println(au.Green(fmt.Sprintf("%d repositories loaded", len(exodevRepos))))

	log.Print(au.White("Loading exoaddons projects..."))
	exoaddonsRepos := loadOrganisationRepos("exo-addons")
	log.Println(au.Green(fmt.Sprintf("%d repositories loaded", len(exoaddonsRepos))))

	for _, repo := range repositories {
		githubRepo := exoplatformRepos[repo]
		log.Println(au.Yellow(fmt.Sprintf("***** Project %s (default branch=%v owner=%s)", au.Green(repo), au.White(*githubRepo.DefaultBranch), *githubRepo.Owner.Login)))
		// githubProject.Peo
		// defaultBranchProtection, _, err := githubClient.Repositories.GetBranchProtection(ctx, githubProject.)
	}

	_, response, _ = githubClient.Users.Get(ctx, "")
	checkQuota(response)
}
