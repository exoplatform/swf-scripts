#!/usr/bin/env ruby


require 'rubygems'
require "json"
require "fileutils"
require "benchmark"
require 'net/http'
require 'net/https'

#
# Synchonize develop branches with translation branches for PLF projects.
#
#  The goal is to get last commits on "develop" branches and to push those commits
#  to the translation branches which may have been updated too.
#
class SyncTranslationBranches

   # Github eXo Dev organization
   EXODevOrganizationURI = "git@github.com:exodev/"
   # Branch name with last modifications
   SourceBranch = "develop"
   # Branch name to update with last modifications
   TranslationBranch = "integration/4.3.x-translation"

   # Logs level
   INFO = "INFO"
   ERROR = "ERROR"

   # all PLF projects with translation
   attr_writer :translation_projects

   # Projects names to process
   attr_writer :plf_projects_names

   # required parameters
   attr_reader :workspace

  def initialize
    @plf_projects_names = [ 'commons', 'ecms', 'social' , 'calendar' , 'wiki' , 'forum' , 'integration' , 'platform' , 'gatein-portal' ]
    @translation_projects = []
    @workspace = ENV['WORKSPACE']

    self.check_params
  end

  def check_params
    # Validate inputs
    if @workspace.nil?
      self.error("WORKSPACE")
    end
  end

  # Process the synchronization between addons repositories
  # 1. get all supported addons repositories
  # 2. for each repos,
  # 2.a clone the repo (if needed)
  # 2.b set the fork origin url (parent)
  # 2.c sync develop branch between 2 organizations
  def process
     print "[START] Synchronization process for Translations branches ($#{TranslationBranch}) started...\n\n"

     #create the directory to work on
     here = Dir.pwd
     FileUtils.mkdir_p @workspace
     # get only projects with Translations
     self.get_translation_projects

     if @translation_projects.nil?
       print "[INFO] 0 Repository to process.\n"
     else
       print "[INFO] NB Translation Projects (Repositories to process): ",@translation_projects.length,"\n\n"
       @translation_projects.each {
         |translation_project|
           Dir.chdir @workspace

           self.log(INFO,translation_project["name"], "---STARTED--")
           if File.directory?(translation_project["name"])
             self.configure_project_repo_urls(translation_project["name"], translation_project["ssh_url"])
           else
             self.clone_project_repo(translation_project["name"], translation_project["ssh_url"])
           end
           self.sync_project_branches(translation_project["name"])
           self.log(INFO,translation_project["name"], "---FINISHED---\n")

           Dir.chdir here
         }
     end
     print "\n[STOP] Synchronization process finished."
  end

  # get all PLF repositories from eXo Dev organization
  # which need translations
  def get_translation_projects
    #
    # TODO: it may be interesting to use the GitHub API in order to automaticaly
    # know if a repository needs translation (based on the presence of the dedicated branch)
    #
    print "[INFO][TRANSLATION_PROJECTS] --------\n"
    @plf_projects_names.each do
          |plf_project_name|
            plf_repo = {}
            plf_repo["name"] = plf_project_name
            plf_repo["ssh_url"] = "#{EXODevOrganizationURI}#{plf_project_name}.git"
            self.log(INFO,plf_repo["name"], "git ssh-url: #{plf_repo["ssh_url"]}")
            @translation_projects.push(plf_repo)
    end
    print "[INFO][TRANSLATION_PROJECTS] --------\n"
  end


  # Configure remote URL for a git repository
  def configure_project_repo_urls(repoName, repoURL)
    self.log(INFO,repoName,"Repository #{repoName} already cloned...")
    Dir.chdir repoName
    self.log(INFO,repoName,"Setting origin url #{repoURL} for #{repoName}...")
    s = system("git remote set-url origin #{repoURL}")
    if !s
      abort("[ERROR] Setting origin url of repository #{repoName} failed !!!\n")
    end
    self.log(INFO,repoName,"Done.")
    self.log(INFO,repoName,"Fetching from origin for #{repoName}...")
    s = system("git fetch origin --prune")
    if !s
      abort("[ERROR] Fetching from origin for repository #{repoName} failed !!!\n")
    end
    self.log(INFO,repoName,"Done.")
  end

  # Clone the repo into the worspace filesystem folder
  def clone_project_repo(repoName, repoURL)
    self.log(INFO,repoName,"Cloning : #{repoName} from #{repoURL}...")
    s = system("git clone --quiet #{repoURL}")
    if !s
      abort("[ERROR] Cloning of repository #{repoName} failed !!!\n")
    end
    self.log(INFO,repoName,"Done.")
    Dir.chdir repoName
  end

  # chechout develop branch in exo-addons repository and push to develop branch in exoplatform repository
  def sync_project_branches(repoName)
    #develop branch
    ok = self.resetBranch(repoName, SourceBranch)
    if ok
       #translation branch
       ok = self.resetBranch(repoName, TranslationBranch)
    end
    if ok
      #rebase and push
      self.rebaseBranch(repoName, TranslationBranch, SourceBranch)
    end
  end

  def resetBranch(repoName, branchName)
    self.log(INFO,repoName,"Checkout #{branchName} branch (it is perhaps not the default) for #{repoName}...")
    s = system("git checkout #{branchName}")
    if !s
      print("[ERROR] No #{branchName} in repository #{repoName}, Skip this repo!!!\n")
      self.log(INFO,repoName,"Done.")
      # Let's process the next one
      return false
    else
      self.log(INFO,repoName,"Done.")
      self.log(INFO,repoName,"Reset #{branchName} to origin/#{branchName} for #{repoName} ...")
      s = system("git reset --hard origin/#{branchName}")
      if !s
        abort("[ERROR] Reset #{branchName} to origin/#{branchName} for #{repoName} failed !!!\n")
        return false
      end
      self.log(INFO,repoName,"Done.")
      return true
    end
  end

  def rebaseBranch(repoName, branchToRebase, rebaseFromBranch)
    s = system("git checkout #{branchToRebase}")
    if !s
      print("[ERROR] No #{branchToRebase} in repository #{repoName}, Skip this repo!!!\n")
      self.log(INFO,repoName,"Done.")
      # Let's process the next one
    else
      self.log(INFO,repoName,"Done.")
      self.log(INFO,repoName,"Rebase #{branchToRebase} on #{rebaseFromBranch} for #{repoName} ...")
      s = system("git rebase -m #{rebaseFromBranch} #{branchToRebase}")
      if !s
        r = system("git rebase --skip")
        if !r
          while r == false
            r = system("git rebase --skip")
          end
        end
      end
      self.log(INFO,repoName,"Rebase Done.")
      #s = system("git push --force origin #{branchName}")
    end
  end

  def log(level, repoName, msg)
     print "[#{level}][#{repoName}] #{msg} \n"
  end

  #log the error msg and exit
  def error(msg)
    print "
       You must define a Workspace.
       Error: #{msg} env var not set !!!"
      exit
  end
end

sync = SyncTranslationBranches.new
puts sync.process
