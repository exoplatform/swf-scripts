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
#  to the remote translation branches which may have been updated too, but translation commits can be lost
#  because they will be re-injected by another process.
#
class SyncTranslationBranches

   # Github eXo Dev organization
   EXODevOrganizationURI = "git@github.com:exodev/"
   EXODevRemoteName = "origin"

   # Github eXo Platform organization
   EXOPlatformOrganizationURI = "git@github.com:exoplatform/"
   EXOPlatformRemoteName = "blessed"

   # Branch name with last modifications
   SourceBranch = "release/4.3.x"
   # Branch name specific to gatein
   GateInSourceBranch = "release/4.3.x"

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

  #
  #
  #
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
             self.configure_project_repo_urls(translation_project["name"], EXOPlatformRemoteName, translation_project["ssh_url_blessed"])
           else
             self.clone_project_repo(translation_project["name"], translation_project["ssh_url_origin"], translation_project["ssh_url_blessed"])
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
            plf_repo["ssh_url_origin"] = "#{EXODevOrganizationURI}#{plf_project_name}.git"
            plf_repo["ssh_url_blessed"] = "#{EXOPlatformOrganizationURI}#{plf_project_name}.git"
            self.log(INFO,plf_repo["name"], "git ssh-url origin/blessed: #{plf_repo["ssh_url_origin"]} / #{plf_repo["ssh_url_blessed"]}")
            @translation_projects.push(plf_repo)
    end
    print "[INFO][TRANSLATION_PROJECTS] --------\n"
  end


  # Configure remote URL for a git repository
  def configure_project_repo_urls(repoName, remoteName, repoURL)
    self.log(INFO,repoName,"Repository #{repoName} already cloned...")
    Dir.chdir repoName
    self.log(INFO,repoName,"Setting #{remoteName} url #{repoURL} for #{repoName}...")
    s = system("git remote add #{remoteName} #{repoURL}")
    if !s
      abort("[ERROR] Setting #{remoteName} url of repository #{repoName} failed !!!\n")
    end
    self.log(INFO,repoName,"Done.")
    self.log(INFO,repoName,"Fetching from #{remoteName} for #{repoName}...")
    s = system("git remote update --prune")
    s = system("git fetch #{remoteName} --prune")
    if !s
      abort("[ERROR] Fetching from #{remoteName} for repository #{repoName} failed !!!\n")
    end
    self.log(INFO,repoName,"Done.")
  end

  # Clone the repo into the worspace filesystem folder
  def clone_project_repo(repoName, repoURL, repoURLBlessed)
    self.log(INFO,repoName,"Cloning : #{repoName} from #{repoURL}...")
    s = system("git clone --quiet #{repoURL}")
    if !s
      abort("[ERROR] Cloning of repository #{repoName} failed !!!\n")
    end
    self.log(INFO,repoName,"Done.")
    Dir.chdir repoName

    if repoName == "gatein-portal"
      self.gatein_portal_specific_code_1(repoName, repoURLBlessed)
    end
  end

  # chechout develop branch in eXo Dev repository and push to the translation remote branch
  def sync_project_branches(repoName)
    if repoName == "gatein-portal"
      self.gatein_portal_specific_code_2(repoName)
    else
      #develop branch
      ok = self.reset_branch(repoName, EXODevRemoteName ,SourceBranch, EXOPlatformRemoteName)
      if ok
        # push force to remote branch
        self.push_force_to_remote_branch(repoName, EXODevRemoteName, SourceBranch, TranslationBranch)
      end
    end
  end

  def reset_branch(repoName, exodevRemoteName, branchName, exoplatformRemoteName)

     # TODO: Choose right remoteName organization based on branch prefix name (ex: release/, stable/..)

    self.log(INFO,repoName,"Checkout #{branchName} branch (it is perhaps not the default) for #{repoName} from #{exoplatformRemoteName} ...")
    s = system("git checkout -b #{branchName} #{exoplatformRemoteName}/#{branchName}")
    if !s
      print("[ERROR] No #{branchName} in #{exoplatformRemoteName} repository #{repoName}, Skip this repo!!!\n")
      self.log(INFO,repoName,"Done.")
      # Let's process the next one
      return false
    else
      self.log(INFO,repoName,"Done.")
      self.log(INFO,repoName,"Reset & Pull #{branchName} to #{exoplatformRemoteName}/#{branchName} for #{repoName} ...")
      s = system("git reset --hard #{exoplatformRemoteName}/#{branchName}")
      if !s
        abort("[ERROR] Reset #{branchName} to #{exoplatformRemoteName}/#{branchName} for #{repoName} failed !!!\n")
        return false
      end
      s = system("git pull")
      if !s
        abort("[ERROR] Pull #{branchName} from #{exoplatformRemoteName}/#{branchName} for #{repoName} failed !!!\n")
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

  # TODO: align this repos with others?
  def gatein_portal_specific_code_1(repoName, repoBlessedURL)

    self.log(INFO,repoName,"Add #{EXOPlatformRemoteName} repository #{repoBlessedURL} for #{repoName} ...")
    s = system("git remote add #{EXOPlatformRemoteName} #{repoBlessedURL}")
    if !s
      abort("[ERROR] Adding #{EXOPlatformRemoteName} remote of repository #{repoName} failed !!!\n")
    end
    self.log(INFO,repoName,"Done.")
    s = system("git fetch #{EXOPlatformRemoteName} --prune")

  end

  # TODO: align this repos with others?
  def gatein_portal_specific_code_2(repoName)
    # branch
    ok = self.reset_branch(repoName, EXOPlatformRemoteName, GateInSourceBranch, EXOPlatformRemoteName)
    if ok
      # push force to remote branch
      self.push_force_to_remote_branch(repoName, EXODevRemoteName, GateInSourceBranch, TranslationBranch)
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
