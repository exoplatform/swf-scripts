#!/usr/bin/env ruby
require 'rubygems'
require "json"
require "benchmark"
require 'net/http'
require 'net/https'

# retrieves the list of repositories from exodev organization
ContentURI = URI.parse("https://api.github.com/orgs/exodev/repos")
req = Net::HTTP::Get.new(ContentURI.path)
req.basic_auth ENV['GITHUB_USER'], ENV['GITHUB_PWD']
https = Net::HTTP.new(ContentURI.host, ContentURI.port)
https.use_ssl = true
https.verify_mode = OpenSSL::SSL::VERIFY_NONE
response = https.start() {|http|
  http.get ContentURI.request_uri, 'User-Agent' => 'MyLib v1.2'
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

result.each {
  |repo|
    if File.directory?(repo["name"])
      print "[INFO] Deleting current copy of : ",repo["name"]," ...\n"
      s = system("rm -rf #{repo['name']}")
      if !s
        print "[ERROR] Deletion of repository ",repo["name"]," failed !!!\n"
        Process.exit 
      end  
      print "[INFO] Done.\n"
    end
    print "[INFO] Cloning : ",repo["name"]," from ",repo['ssh_url']," ...\n"
    s = system("git clone --quiet #{repo['ssh_url']}") 
    if !s
      print "[ERROR] Cloning of repository ",repo["name"]," failed !!!\n"
      Process.exit 
    end  
    print "[INFO] Done.\n"
    Dir.chdir repo["name"]
    print "[INFO] Checkout master branch ...\n"
    s = system("git checkout --quiet -b master-dev origin/master")
    if !s
      print "[ERROR] Checkout of master branch from repository ",repo["name"]," failed !!!\n"
      Process.exit 
    end  
    print "[INFO] Done.\n"
    print "[INFO] Push master branch content from dev repository to blessed repository ...\n"
    s = system("git push git@github.com:exoplatform/#{repo['name']}.git master-dev:master")
    if !s
      print "[ERROR] Push of master branch updates to repository ",repo["name"]," failed !!!\n"
      Process.exit 
    end  
    print "[INFO] Done.\n"
    Dir.chdir here
}
