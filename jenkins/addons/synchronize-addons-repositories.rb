#!/usr/bin/env ruby


require 'rubygems'
require "json"
require "fileutils"
require "benchmark"
require 'net/http'
require 'net/https'

#
#
#
#
#
#
#
#
#
class SyncAddonsRepos

   AddonsReposForksURI = "https://api.github.com/orgs/exo-addons/repos?type=forks"

   INFO = "INFO"
   ERROR = "ERROR"

   #all addons from eXo Addons
   attr_writer :addons_supported

   #option to limit the result per page from github
   attr_writer :github_results_per_page

   # required parameters
   attr_reader :github_user
   attr_reader :github_pwd
   attr_reader :workspace

  def initialize
    @addons_supported = []
    @github_user = ENV['GITHUB_USER']
    @github_pwd = ENV['GITHUB_PWD']
    @workspace = ENV['WORKSPACE']
    #a parameter can be set to limit the result per page, default 100
    @github_results_per_page = ARGV.shift || '100'

    self.check_params
  end

  def check_params
    # Validate inputs
    if @github_user.nil?
      self.error("GITHUB_USER")
    end
    if @github_pwd.nil?
      self.error("GITHUB_PWD")
    end
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
     print "[START] Synchronization process for Supported Addons started...\n\n"

     #create the directory to work on
     here = Dir.pwd
     FileUtils.mkdir_p @workspace
     # get only supported addons
     self.get_supported_addons_from_github
     #self.show_supported_addons

     if @addons_supported.nil?
       print "[INFO] 0 Repository to process.\n"
     else
       print "[INFO] NB SUPPORTED ADDONS (Repositories to process): ",@addons_supported.length,"\n\n"
       @addons_supported.each {
         |addon_repo|
           Dir.chdir @workspace

           self.log(INFO,addon_repo["name"], "---STARTED--")
           if File.directory?(addon_repo["name"])
             self.configure_addon_repo_urls(addon_repo["name"], addon_repo["ssh_url"], addon_repo["ssh_url_fork_parent"])
           else
             self.clone_addon_repo(addon_repo["name"], addon_repo["ssh_url"], addon_repo["ssh_url_fork_parent"])
           end
           self.sync_addon_repo_to_blessed_repo(addon_repo["name"])
           self.log(INFO,addon_repo["name"], "---FINISHED---\n")

           Dir.chdir here
         }
     end
     print "\n[STOP] Synchronization process finished."
  end

  # get all addons repositories from eXo Addons organization
  # which are supported by eXo Platform
  def get_supported_addons_from_github
    uri_per_page = "#{AddonsReposForksURI}&per_page=#{@github_results_per_page}"
    all_forks = execute_request_uri( URI.parse(uri_per_page) )

    print "[INFO] NB Fork Repositories in exo-addons organization (supported and not supported): ",all_forks.length,"\n\n"
    print "[INFO][SUPPORTED_ADDONS] --------\n"
    all_forks.each {
          |fork_repo|
           # Each supported Addon repository is a fork from eXo blessed (exoplatform organization).
           # This method gets the repository details form GitHub to find parent url information.
           result = execute_request_uri( URI.parse(fork_repo["url"]) )
           parent_ssh_url = result["parent"]["ssh_url"];

           #check if the parent is in exoplatform organization
           if(parent_ssh_url.include? "github.com:exoplatform")
              fork_repo["ssh_url_fork_parent"] = parent_ssh_url
              self.log(INFO,fork_repo["name"], "git ssh-url: #{result["parent"]["ssh_url"]}")
              @addons_supported.push(fork_repo)
           end
    }
    print "[INFO][SUPPORTED_ADDONS] --------\n"
  end


  # Configure remote URL for a git repository
  def configure_addon_repo_urls(repoName, repoAddonURL, repoBlessedURL)
    self.log(INFO,repoName,"Repository #{repoName} already cloned...")
    Dir.chdir repoName
    self.log(INFO,repoName,"Setting origin url #{repoAddonURL} for #{repoName}...")
    s = system("git remote set-url origin #{repoAddonURL}")
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
    self.log(INFO,repoName,"Setting blessed url #{repoBlessedURL} for #{repoName} ...")
    s = system("git remote set-url blessed #{repoBlessedURL}")
    if !s
      abort("[ERROR] Setting blessed url of repository #{repoName} failed !!!\n")
    end
    self.log(INFO,repoName,"Done.")
  end

  # Clone the addon repo in the worspace filesystem folder
  def clone_addon_repo(repoName, repoAddonURL, repoBlessedURL)
    self.log(INFO,repoName,"Cloning : #{repoName} from #{repoAddonURL}...")
    s = system("git clone --quiet #{repoAddonURL}")
    if !s
      abort("[ERROR] Cloning of repository #{repoName} failed !!!\n")
    end
    self.log(INFO,repoName,"Done.")
    Dir.chdir repoName
    self.log(INFO,repoName,"Add blessed repository #{repoBlessedURL} for #{repoName} ...")
    s = system("git remote add blessed #{repoBlessedURL}")
    if !s
      abort("[ERROR] Adding blessed remote of repository #{repoName} failed !!!\n")
    end
    self.log(INFO,repoName,"Done.")
  end

  # chechout develop branch in exo-addons repository and push to develop branch in exoplatform repository
  def sync_addon_repo_to_blessed_repo(repoName)
    self.log(INFO,repoName,"Checkout develop branch (it is perhaps not the default) for #{repoName}...")
    system("git config user.email 'mgreau@exoplatform.com' ")
    s = system("git checkout develop")
    if !s
      print("[ERROR] No develop branch in repository #{repoName}, Skip this repo!!!\n")
      self.log(INFO,repoName,"Done.")
      # Let's process the next one
    else
      self.log(INFO,repoName,"Done.")
      self.log(INFO,repoName,"Reset develop to origin/develop for #{repoName} ...")
      s = system("git reset --hard origin/develop")
      if !s
        abort("[ERROR] Reset develop to origin/develop for #{repoName} failed !!!\n")
      end
      self.log(INFO,repoName,"Done.")
      self.log(INFO,repoName,"Push develop branch content from exo-addons repository to blessed repository ...")
      #s = system("git push blessed develop")
      if !s
        abort("[ERROR] Push of develop branch updates to repository #{repoName} failed !!!\n")
      end
      self.log(INFO,repoName,"Done.")
    end
  end

  def show_supported_addons
      print @addons_supported
  end

  # Execute the HTTP request and return JSON data to native Ruby
  # data structure - a hash
  def execute_request_uri(uri)
    req = Net::HTTP::Get.new(uri.request_uri)
    req.basic_auth @github_user, @github_pwd
    req.add_field('User-Agent', 'Custom Ruby Script from exo-swf@exoplatform.com')
    https = Net::HTTP.new(uri.host, uri.port)
    # to debug HTTP request
    #https.set_debug_output($stdout)
    https.use_ssl = true
    https.verify_mode = OpenSSL::SSL::VERIFY_NONE
    response = https.start() {|http|
      http.get uri.request_uri
      http.request(req)
    }

    case response
      when Net::HTTPRedirection
        # repeat the request using response['Location']
      when Net::HTTPSuccess
        repo_info = JSON.parse response.body
      else
        # response code isn't a 200; raise an exception
        response.error!
    end

    data = response.body

    # we convert the returned JSON data to native Ruby
    # data structure - a hash
    return JSON.parse(data)
  end

  def log(level, repoName, msg)
     print "[#{level}][#{repoName}] #{msg} \n"
  end

  #log the error msg and exit
  def error(msg)
    print "
       You must define the GitHub user, GitHub password and the Workspace.
       Error: #{msg} env var not set !!!"
      exit
  end
end

sync = SyncAddonsRepos.new
puts sync.process
