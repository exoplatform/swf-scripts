#!/usr/bin/env ruby
require 'rubygems'
require "json"
require "fileutils"
require "benchmark"
require 'uri'
require 'net/http'
require 'net/https'
require 'octokit'

# Validate inputs
if ENV['GITHUB_USER'].nil?
  abort("[ERROR] GITHUB_USER env var not set !!!\n")
end
if ENV['GITHUB_TOKEN'].nil?
  abort("[ERROR] GITHUB_TOKEN env var not set !!!\n")
end

JSON.load(STDIN.read).each { |repo| 
  print "[INFO] ",repo["owner"]["login"]," - ",repo["name"],"\n"
    
  client = Octokit::Client.new(:access_token => ENV['GITHUB_TOKEN'])
  client.follow(ENV['GITHUB_USER'])
  #MasterBranch
  #hook = client.create_hook(
  #  "#{repo["owner"]["login"]}/#{repo["name"]}",
  #  'masterbranch',
  #  {},
  #  {
  #    :events => ['push'],
  #    :active => true
  #  }
  #)
  #Fisheye   
  hook = client.create_hook(
    "#{repo["owner"]["login"]}/#{repo["name"]}",
    'fisheye',
    {
      :url_base => 'https://fisheye.exoplatform.org',
      :token => '7a40d066423ed0e62a943876c8d9ffe29d8805ad',
      :repository_name => repo['name']+"-dev"
    },
    {
      :events => ['push'],
      :active => true
    }
  )   
      
  print "[INFO] Done : ",hook,"\n"       
}