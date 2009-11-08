class Claruby
  @@grammar = [:processing,
               :parameters,
               :rendering,
               :redirected,
               :completed,
               :actioncontroller_routingerror,
               :sent,
               :filter,
               :failed,
               :activerecord_recordnotfound,
               :actioncontroller_invalidauthenticitytoken,
               :actioncontroller_unknownaction,
               :passenger]
  
  @@processing_regex = /(.*)#(.*) \(for (.*) at (.*)\) \[(.*)\]/
  @@processing_ajax_regex = /(.*)#(.*) to .* \(for (.*) at (.*)\) \[(.*)\]/
  @@redirected_regex = /to (.*)/
  @@completed_regex = /in (\d+)ms \(View: (\d+), DB: (\d+)\) \| (.*) \[(.*)\]/
  @@routing_error_regex = /\(No route matches "(.*)" with (.*)\):/
  @@record_error_regex = /\(Couldn't find (.*) with ID=(.*)\)/

  def parse_log_entry( log_entry )
    @request = Request.new

    # SLOW. Needs profiling
    log_entry.split(/\n/).each do |line|
      line = line.gsub(/^  /, '').gsub("::", '_');
      verb = line.split(' ').first # First word on the line

      unless verb.nil?
        verb       = verb.gsub(/:$/, '').downcase.to_sym  # Strip column off of the verb, e.g. Parameters:
        expression = line.split(' ')[1..-1].join(' ')     # Whole line minus first word

        begin
          self.send( verb, expression ) if self.understands? verb
        rescue Exception => e
          puts "Error parsing this entry. #{ e } (#{ e.class })"
        end
      end
    end

    @request.save
    @request = nil
  end

  def parse_log( log_file )
    log = ''
    puts "opening log #{log_file}"
    File.open( log_file, 'r' ) { |f| log += f.read }

    puts "Entry count: #{log.split(/^\n\n/).count}"
    log.split(/^\n\n/).each_with_index { |entry, counter| parse_log_entry( entry ); print "#{counter}." }
    puts "finished"
  end

  # -----------------------------------
  # Parser portion
  # -----------------------------------

  def understands?( verb )
    @@grammar.include? verb
  end

  def processing string
    # More specific regex first
    matches = string.match( @@processing_ajax_regex )
    matches = string.match( @@processing_regex      ) if matches.nil?

    @request.controller  =      matches[1]
    @request.action      =      matches[2]
    @request.ip          =      matches[3]
    @request.time = Time.parse( matches[4] )
    @request.http_method =      matches[5]
  end

  def parameters string
    # Escape file embedding
    string.gsub!(/(#<File.*>)/, "\"\1\"")

    # eval is evil in this context. Placeholder.
    @request.parameters = eval( string )

    # Site-specific parameters. Need to think about how to extract these.
    @request.embed_key = @request.parameters["embed_key"] || nil
    @request.permalink = @request.parameters["permalink"] || nil
  end

  def rendering string
    # Unsure of the utility of this data.
  end

  def redirected string
    matches = string.match( @@redirected_regex )
    unless matches.nil?
      @request.parameters.merge!({"redirected_url" => matches[1]})
    end
  end

  def completed string
    matches = string.match( @@completed_regex )
    unless matches.nil?
      @request.view_time     = matches[2]
      @request.db_time       = matches[3]
      @request.http_response = matches[4]
      @request.url           = matches[5]
    end
  end

  def actioncontroller_routingerror string
    matches = string.match( @@routing_error_regex )
    unless matches.nil?
      @request.url        =       matches[1]
      @request.parameters = eval( matches[2] )
    end
  end

  def actioncontroller_unknownaction string
    # Not any applicable data in here, url is already set.
  end

  def actioncontroller_invalidauthenticitytoken string
    @request.error = "Invalid Authenticity Token"
  end

  def activerecord_recordnotfound string
    @request.error = string.gsub(/\(|\)/, '')
  end

  def passenger string
    # Unsure of the utility of this data for visualization
    # Could be useful though.
  end

  # In case these need to be tracked
  def filter string
  end

  def failed string
  end

  def sent string
  end
end
