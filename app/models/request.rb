class Request < ActiveRecord::Base
  named_scope :controller, lambda { |c| { :conditions => ["controller = ?", c]} }
  named_scope :action, lambda { |a| { :conditions => ["action = ?", a]} }
  named_scope :point, lambda { |p| { :conditions => ["controller = ? and action = ?", p.split("#").first, p.split("#").last] } }
  named_scope :within_last, lambda { |t| { :conditions => ["time > ?", t.ago] } }
  named_scope :in_ip_set, lambda { |set| { :conditions => ["ip IN (?)", set] } }
  named_scope :unique, :select => 'DISTINCT ip'

  serialize :parameters

  validates_uniqueness_of :ip, :scope => :time
  validates_presence_of :ip

  def self.find_by_path( path, options={})
    time = options[:time] || 400.years
    
    hits = []

    path.split(" -> ").each_with_index do |step, counter|
      hits[counter] = []

      if counter == 0
        hits[0] = Request.point( step ).within_last( time ).all
      else
        ips = hits[-2].collect { |h| h.ip }
        hits[counter] = Request.point( step ).in_ip_set( ips ).within_last( time ).all
      end
    end

    return hits
  end

  def next
    Request.find(:first, :conditions => ["id > ? AND ip = ? AND time > ?", id, ip, time], :order => "time ASC")
  end

  def back
    Request.find(:first, :conditions => ["id < ? AND ip = ? AND time < ?", id, ip, time], :order => "time DESC")
  end

  def render_time
    self.view_time + self.db_time
  end
  
  def point
    "#{controller}\##{action}"
  end

  # ----------------------------------------------------------------------------
  # Lab: Functions not ready for public consumption yet
  # ----------------------------------------------------------------------------

  def self.paths_from_yaml( file )
    cf = YAML::load( File.open(file) )

    return cf['paths']["test_path_1"].split(" ").join(' -> ')
  end

  # ----------------------------------------------------------------------------
  # Debugging method
  # ----------------------------------------------------------------------------

  # Follows the ip from the current request until its final entry
  def path_forward
    path = []
    step = self.next

    until step == nil
      path << step.point
      step = step.next
    end

    return path
  end

  # Follows the ip from the current request until its first entry
  def path_back
    path = []
    step = back

    until step == nil
      path << step.point
      step = step.back
    end

    return path
  end

  # Finds all paths back from a given point
  def self.paths_back_from point
    controller, action = point.split("#")
    Request.controller( controller ).action( action ).all.collect { |entry| entry.path_back }
  end
end
