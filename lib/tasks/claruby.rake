require 'ruby-prof'

namespace :claruby do
  def load_config
    @config ||= YAML::load_file("#{RAILS_ROOT}/config/claruby.yml")
  end
  
  desc "Parses the log into Request objects and saves them to the db for filtering."
  task :load_log => :environment do
    claruby = Claruby.new
    claruby.parse_log( ENV["LOG"] || "log/#{RAILS_ENV}.log" )
  end

  desc "Display all counters"
  task :counters => :environment do
    load_config
    
    @counters = []
    @config["counters"].each do |name, point|
      @counters << {
        :name => name,
        :point => point,
        :results => {
          :overall => {
            :unique => Request.unique.point( point ).length,
            :total => Request.point( point ).length },
          :recent => {
            :unique => Request.within_last( 30.days ).unique.point( point ).count,
            :total => Request.within_last( 30.days ).point( point ).count }}}
    end
  end

  desc "Display all path information"
  task :paths => :environment do
    load_config

    @paths = []
    @config["paths"].each do |name, path|
      @paths << {
        :name => name,
        :path => path.gsub(" ", " -> "),
        :results => {
          :overall => Request.find_by_path( path.gsub(" ", " -> ") ),
          :recent => Request.find_by_path( path.gsub(" ", " -> "), :time => 30.days) }}
    end
  end

  desc "Analytics"
  task :analyze => [:environment, :counters, :paths] do


  # Profile the code
    # Is there a cleaner way for this?
    @output = '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd"><html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en"><head><meta http-equiv="Content-type" content="text/html;charset=UTF-8" /><title>Claruby Analysis</title><style type="text/css"> table { border: 1px solid black; padding: 2px; margin: 5px; float: left; } td, th { text-align: left } tr:hover { background-color:#FE9A2E; </style></head><body><h1>Claruby Analysis Output</h1><div>'

    @output += "<table width='45%'><tr><th>Path Name</th><th>Overall</th><th>Past 30 days</th></tr>"
    @paths.each do |path|
      @output += "<tr><td>#{path[:name]}</td><td>#{path[:results][:overall].collect { |r| r.count }.join(', ')}</td><td>#{path[:results][:recent].collect { |r| r.count }.join(', ')}</td></tr>"
    end
    @output += "</table>"

    @output += "<table width='45%'><tr><th>Counter Name (point)</th><th>Overall</th><th>Past 30 days</th></tr>"
    @counters.each do |counter|
      @output += "<tr><td>#{counter[:name]} (#{counter[:point]})</td><td>U: #{counter[:results][:overall][:unique]}, T: #{counter[:results][:overall][:total]}</td><td> U: #{counter[:results][:recent][:unique]}, T: #{counter[:results][:recent][:total]}</td></tr>"
    end
    @output += "</table>"

    @output += "<h2 style='clear:both;'>Path Legend</h2><ul>"
    @paths.each do |path|
      @output += "<li>#{path[:name]}: #{path[:path]}</li>"
    end
    @output += "</ul>"
    

    @output += "</div></body></html>"

    File.open("#{RAILS_ROOT}/notes/claruby.html", 'w') { |f| f.write( @output ) }
    
  end
end
