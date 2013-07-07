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
if ENV['GITHUB_PWD'].nil?
  abort("[ERROR] GITHUB_PWD env var not set !!!\n")
end

JSON.load(STDIN.read).each { |repo| 
  print "[INFO] ",repo["owner"]["login"]," - ",repo["name"],"\n"
    
  client = Octokit::Client.new(:login => ENV['GITHUB_USER'], :password => ENV['GITHUB_PWD'])
  client.follow(ENV['GITHUB_USER'])
  hook = client.create_hook(
    "#{repo["owner"]["login"]}/#{repo["name"]}",
    'masterbranch',
    {},
    {
      :events => ['push'],
      :active => true
    }
  )   
      
  print "[INFO] Done : ",hook,"\n"       
}