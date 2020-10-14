#!/usr/bin/env ruby
require 'rubygems'
require "json"
require "fileutils"
require "benchmark"
require 'net/http'
require 'net/https'

# Validate inputs
if ENV['GITHUB_USER'].nil?
  abort("[ERROR] GITHUB_USER env var not set !!!\n")
end
if ENV['GITHUB_TOKEN'].nil?
  abort("[ERROR] GITHUB_TOKEN env var not set !!!\n")
end
if ENV['WORKSPACE'].nil?
  abort("[ERROR] WORKSPACE env var not set !!!\n")
end

# retrieves the list of repositories from exodev organization
ContentURI = URI.parse("https://api.github.com/orgs/exodev/repos?per_page=100")
req = Net::HTTP::Get.new(ContentURI.request_uri)
req.add_field('Authorization', "token #{ENV['GITHUB_TOKEN']}")
req.add_field('User-Agent', 'Custom Ruby Script from exo-swf@exoplatform.com')
https = Net::HTTP.new(ContentURI.host, ContentURI.port)
https.use_ssl = true
https.verify_mode = OpenSSL::SSL::VERIFY_NONE
response = https.start() {|http|
  http.get ContentURI.request_uri
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
result = JSON.parse(data)

here = Dir.pwd
FileUtils.mkdir_p ENV['WORKSPACE']

print "[INFO] NB results : ",result.length,"\n"
result.each {
  |repo|
    Dir.chdir ENV['WORKSPACE']
    repoName = repo["name"]
    repoDevURL = repo['ssh_url']
    repoBlessedURL  = String.new(repo['ssh_url'])
    repoBlessedURL ["exodev"] = "exoplatform"
    if File.directory?(repoName)
      Dir.chdir repoName
      print "[INFO] Setting origin url ",repoDevURL," for ",repoName," ...\n"
      s = system("git remote set-url origin #{repoDevURL}") 
      if !s
        abort("[ERROR] Setting origin url of repository #{repoName} failed !!!\n")
      end  
      print "[INFO] Done.\n"      
      print "[INFO] Fetching from origin for ",repoName," ...\n"
      s = system("git fetch origin --prune") 
      if !s
        abort("[ERROR] Fetching from origin for repository #{repoName} failed !!!\n")
      end  
      print "[INFO] Done.\n"
      print "[INFO] Setting blessed url ",repoBlessedURL," for ",repoName," ...\n"
      s = system("git remote set-url blessed #{repoBlessedURL}") 
      if !s
        abort("[ERROR] Setting blessed url of repository #{repoName} failed !!!\n")
      end  
      print "[INFO] Done.\n"      
    else
      print "[INFO] Cloning : ",repoName," from ",repoDevURL," ...\n"
      s = system("git clone --quiet #{repoDevURL}") 
      if !s
        abort("[ERROR] Cloning of repository #{repoName} failed !!!\n")
      end  
      print "[INFO] Done.\n" 
      Dir.chdir repoName     
      print "[INFO] Add blessed repository ",repoBlessedURL," for ",repoName," ...\n"
      s = system("git remote add blessed #{repoBlessedURL}") 
      if !s
        abort("[ERROR] Adding blessed remote of repository #{repoName} failed !!!\n")
      end  
      print "[INFO] Done.\n"      
    end

    print "[INFO] Checkout develop branch (it is perhaps not the default) for ",repoName," ...\n"
    s = system("git checkout develop")
    if !s
      print("[INFO] No develop branch in repository #{repoName}, let's sync master\n")
      print "[INFO] Checkout master branch (it is perhaps not the default) for ",repoName," ...\n"
      s = system("git checkout master")
      if !s
        print("[WARN] Checkout master branch of repository #{repoName} failed !!! Skip this repo\n")
        # No master branch perhaps ? Let's skip #{repoName}.\n")
        next
      end
      print "[INFO] Done.\n"      
      print "[INFO] Reset master to origin/master for ",repoName," ...\n"
      s = system("git reset --hard origin/master") 
      if !s
        abort("[ERROR] Reset master to origin/master for #{repoName} failed !!!\n")
      end
      print "[INFO] Done.\n"
      print "[INFO] Push master branch content from dev repository to blessed repository ...\n"
      s = system("git push blessed master")
      if !s
        abort("[ERROR] Push of master branch updates to repository #{repoName} failed !!!\n")
      end  
      print "[INFO] Done.\n"
      # Let's process the next one
      next
    end
    print "[INFO] Done.\n"      

    print "[INFO] Reset develop to origin/develop for ",repoName," ...\n"
    s = system("git reset --hard origin/develop") 
    if !s
      abort("[ERROR] Reset develop to origin/develop for #{repoName} failed !!!\n")
    end
    print "[INFO] Done.\n"

    print "[INFO] Push develop branch content from dev repository to blessed repository ...\n"
    s = system("git push blessed develop")
    if !s
      abort("[ERROR] Push of develop branch updates to repository #{repoName} failed !!!\n")
    end  
    print "[INFO] Done.\n"

    # Synchronisation of project branches
    s=`git branch -r`
    s.each_line do |remoteBranch|
        remoteBranch.gsub!(/\n/, "")
        if remoteBranch =~ /origin\/project/
            localBranch = "#{remoteBranch}"
            localBranch.slice! "origin/"
    
            print "[INFO] Checkout #{localBranch}\n"
            s = system("git checkout #{localBranch}")
            if !s
                print("[WARN] Checkout #{remoteBranch} branch of repository #{repoName} failed !!! Skip this branch\n")
                next
            end
    
            print "[INFO] Reset #{localBranch} to #{remoteBranch}\n"
            s = system("git reset --hard #{remoteBranch}")
            if !s
                abort("[ERROR] Reset #{localBranch} to #{remoteBranch} for #{repoName} failed !!!\n")
            end
            print "[INFO] Push #{localBranch} branch content from dev repository to blessed repository ...\n"
            s = system("git push --force blessed #{localBranch}")
            if !s
              abort("[ERROR] Push of master branch updates to repository #{repoName} failed !!!\n")
            end  
        end
    end
    
    print "[INFO] Done.\n"
}

Dir.chdir here
