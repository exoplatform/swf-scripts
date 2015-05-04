#!/usr/bin/ruby
require "json";
require "benchmark";
 
JSON.load(STDIN.read).each {
  |repo|
  print "Cloning : ",repo["name"],"\n"
  time = Benchmark.measure do
    system("mkdir -p #{repo['owner']['login']}")
    system("cd #{repo['owner']['login']}; git clone #{repo['ssh_url']}; cd -;")
  end
  print time,"\n"
}
