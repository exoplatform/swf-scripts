#!/usr/bin/env ruby


require 'rubygems'
require "json"
require "fileutils"
require "benchmark"
require 'net/http'
require 'net/https'

#
# Synchonize integration/4.3.x-translation branches with translation JIPT branches for PLF projects.
#
#
class SyncTranslationJIPTBranches

   # Github eXo Dev organization
   EXODevOrganizationURI = "git@github.com:exodev/"
   EXODevRemoteName = "origin"

   # Branch name with last modifications
   TranslationBranch = "integration/4.3.x-translation"

   # Branch name to update with last modifications
   TranslationJIPTBranch = "integration/4.3.x-translation-jipt"

   #String Key from commit message for cherry-pick
   CommitMessageKey = "Crowdin JIPT Fix"

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

  #
  #
  #
  def process
     print "[START] Synchronization process for Translations JIPT branches ($#{TranslationJIPTBranch}) started...\n\n"

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
             self.configure_project_repo_urls(translation_project["name"], EXODevRemoteName, translation_project["ssh_url_origin"])
           else
             self.clone_project_repo(translation_project["name"], translation_project["ssh_url_origin"])
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
    print "[INFO][TRANSLATION_JIPT_PROJECTS] --------\n"
    @plf_projects_names.each do
          |plf_project_name|
            plf_repo = {}
            plf_repo["name"] = plf_project_name
            plf_repo["ssh_url_origin"] = "#{EXODevOrganizationURI}#{plf_project_name}.git"
            self.log(INFO,plf_repo["name"], "git ssh-url origin: #{plf_repo["ssh_url_origin"]}")
            @translation_projects.push(plf_repo)
    end
    print "[INFO][TRANSLATION_JIPT_PROJECTS] --------\n"
  end


  # Configure remote URL for a git repository
  def configure_project_repo_urls(repoName, remoteName, repoURL)
    self.log(INFO,repoName,"Repository #{repoName} already cloned...")
    Dir.chdir repoName
    self.log(INFO,repoName,"Setting #{remoteName} url #{repoURL} for #{repoName}...")
    s = system("git remote set-url #{remoteName} #{repoURL}")
    if !s
      abort("[ERROR] Setting #{remoteName} url of repository #{repoName} failed !!!\n")
    end
    self.log(INFO,repoName,"Done.")
    self.log(INFO,repoName,"Fetching from #{remoteName} for #{repoName}...")
    s = system("git fetch #{remoteName} --prune")
    if !s
      abort("[ERROR] Fetching from #{remoteName} for repository #{repoName} failed !!!\n")
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

  # chechout branch in eXo Dev repository and push to the translation remote branch
  def sync_project_branches(repoName)
    ok = self.reset_branch(repoName, EXODevRemoteName, TranslationJIPTBranch)
    if ok
      ok = self.reset_branch(repoName, EXODevRemoteName, TranslationBranch)
      if ok
        commitId = `git log --all --grep='#{CommitMessageKey}' --pretty=format:%H`
        ok = self.cherry_pick(repoName, TranslationBranch, commitId)
        if ok
          # push force to remote branch
          self.push_force_to_remote_branch(repoName, EXODevRemoteName, TranslationBranch, TranslationJIPTBranch)
        end
      end
    end
  end

  def reset_branch(repoName, remoteName, branchName)
    self.log(INFO,repoName,"Checkout #{branchName} branch (it is perhaps not the default) for #{repoName}...")
    s = system("git checkout #{branchName}")
    if !s
      print("[ERROR] No #{branchName} in repository #{repoName}, Skip this repo!!!\n")
      self.log(INFO,repoName,"Done.")
      # Let's process the next one
      return false
    else
      self.log(INFO,repoName,"Done.")
      self.log(INFO,repoName,"Reset & Pull #{branchName} to #{remoteName}/#{branchName} for #{repoName} ...")
      s = system("git reset --hard #{remoteName}/#{branchName}")
      if !s
        abort("[ERROR] Reset #{branchName} to #{remoteName}/#{branchName} for #{repoName} failed !!!\n")
        return false
      end
      s = system("git pull")
      if !s
        abort("[ERROR] Pull #{branchName} from #{remoteName}/#{branchName} for #{repoName} failed !!!\n")
        return false
      end
      self.log(INFO,repoName,"Done.")
      return true
    end
  end

  def push_force_to_remote_branch(repoName, remoteName, sourceBranch, remoteBranch)
    s = system("git checkout #{sourceBranch}")
    if !s
      print("[ERROR] No #{sourceBranch} in repository #{repoName}, Skip this repo!!!\n")
      self.log(INFO,repoName,"Done.")
      # Let's process the next one
    else
      self.log(INFO,repoName,"Done.")
      self.log(INFO,repoName,"Push force #{sourceBranch} to #{remoteName} #{remoteBranch} for #{repoName} ...")
      s = system("git push --force #{remoteName} #{sourceBranch}:#{remoteBranch}")
      self.log(INFO,repoName,"Push Done.")
    end
  end

  def cherry_pick(repoName, sourceBranch, hashCommit)
      self.log(INFO,repoName,"Cherry pick commit #{hashCommit} to #{sourceBranch} for #{repoName}...")
      s = system("git checkout #{sourceBranch}")
      s = system("git cherry-pick #{hashCommit}")
      if !s
        print("[ERROR] Problem with #{hashCommit} commit in repository #{repoName}, Skip this repo!!!\n")
        self.log(INFO,repoName,"Done.")
        return false
        # Let's process the next one
      else
        self.log(INFO,repoName,"Done.")
        return true
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

sync = SyncTranslationJIPTBranches.new
puts sync.process
