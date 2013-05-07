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
if ENV['GITHUB_PWD'].nil?
  abort("[ERROR] GITHUB_PWD env var not set !!!\n")
end
if ENV['WORKSPACE'].nil?
  abort("[ERROR] WORKSPACE env var not set !!!\n")
end

# retrieves the list of repositories from exodev organization
ContentURI = URI.parse("https://api.github.com/orgs/exodev/repos?per_page=100")
req = Net::HTTP::Get.new(ContentURI.request_uri)
req.basic_auth ENV['GITHUB_USER'], ENV['GITHUB_PWD']
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
    if File.directory?(repo["name"])
      print "[INFO] Deleting current copy of : ",repo["name"]," ...\n"
      s = system("rm -rf #{repo['name']}")
      if !s
        abort("[ERROR] Deletion of repository #{repo['name']} failed !!!\n")
      end  
      print "[INFO] Done.\n"
    end
    print "[INFO] Cloning : ",repo["name"]," from ",repo['ssh_url']," ...\n"
    s = system("git clone --quiet #{repo['ssh_url']}") 
    if !s
      abort("[ERROR] Cloning of repository #{repo['name']} failed !!!\n")
    end  
    print "[INFO] Done.\n"
    Dir.chdir repo["name"]
    print "[INFO] Checkout master branch ...\n"
    s = system("git checkout --quiet -b master-dev origin/master")
    if !s
      abort("[ERROR] Checkout of master branch from repository #{repo['name']} failed !!!\n")
    end  
    print "[INFO] Done.\n"
    print "[INFO] Push master branch content from dev repository to blessed repository ...\n"
    s = system("git push git@github.com:exoplatform/#{repo['name']}.git master-dev:master")
    if !s
      abort("[ERROR] Push of master branch updates to repository #{repo['name']} failed !!!\n")
    end  
    print "[INFO] Done.\n"
}

Dir.chdir here