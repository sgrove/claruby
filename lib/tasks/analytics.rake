namespace :claruby do
  desc "Parses the log into Request objects and saves them to the db for filtering."
  task :load_log => :environment do
    claruby = Claruby.new

    log = ENV["LOG"] || "log/#{RAILS_ENV}.log"
    claruby.parse_log( log )
  end
end

namespace :counters do
  desc "Hits on the weebly embed page"
  task :weebly_page => :environment do
    unique = Request.weebly_embedded.unique.length
    total = Request.weebly_embedded.length
    puts "Unique: #{unique}, Total: #{total}"
  end
end

namespace :paths do
  task :publishers => :environment do
    step3 = Request.find_by_path("HomeController#index then PublishersController#new_site then PublishersController#get_embed")
    step3.each do |step|
      puts "#{counter}: #{step.length}"
    end
  end

  desc "Find out the developer funnel"
  task :developers => :environment do
    # Inefficient. Should probably build a paths tree while parsing all requests objects.
    
    path1 = Request.find_by_path("HomeController#index then DevelopersController#index then DevelopersController#import_games")
    path2 = Request.find_by_path("HomeController#index then DevelopersController#index then DevelopersController#new_inventory_item")
    path3 = Request.find_by_path("HomeController#index then DevelopersController#index then DevelopersController#upload_game_simple")
    path4 = Request.find_by_path("HomeController#index then DevelopersController#index then nowhere#nowhere")

    path1[0..-2].each_with_index do |step, counter|
      puts "#{counter}: #{step.length}"
    end

    puts "\t->import_games: #{path1.last.length}"
    puts "\t->new_inventory_item: #{path2.last.length}"
    puts "\t->upload_game_simple: #{path3.last.length}"
    puts "\t->nil: #{path4.last.length}"

    puts "-----------------------------------"

    puts "P1: #{path1.collect{ |pe| pe.length }.join(', ')}"
    puts "P2: #{path2.collect{ |pe| pe.length }.join(', ')}"
    puts "P3: #{path3.collect{ |pe| pe.length }.join(', ')}"
    puts "P4: #{path4.collect{ |pe| pe.length }.join(', ')}"
  end

  desc "Trace all paths back from a given point"
  task :path_back => :environment do
    paths = Request.paths_back_from "DevelopersController#new_inventory_item"
    puts paths.inspect
  end

  desc "Trace user-defined YAML file for paths"
  task :trace_yaml => :environment do
    paths = {}
    file = ENV["PATHS"]
    path_set = YAML::load( File.open( file ) )
    path_set.to_a.each do |path_pair|
      puts "Finding path '#{path_pair[0]}': #{path_pair[1].split(' ').join(' -> ')}"

      path_name = path_pair[0]
      path = Request.find_by_path( path_pair[1] )
      paths.merge!( {path_name => path } )
    end

    puts paths.inspect
  end
end
