class Run < ActiveRecord::Base
  validates_presence_of :project, :build, :revision
  validates_uniqueness_of :revision, :scope => [ :project, :build ]
                 
  # Post a notification about the status of a build
  def self.notify(params = {})
    raise "notify requires a :project, :build, and :revision" unless params[:project] and params[:build] and params[:revision]
    run = self.find_by_project_and_build_and_revision(params[:project], params[:build], params[:revision])

    if run
      params.keys.each {|p| run.send("#{p}=".to_sym, params[p]) }
      run.finished = Time.now
    else
      run = Run.new({ :started => Time.now }.merge(params))
    end
    
    run.save
    run
  end
  
  def self.finished_summary(params = {})
    matches = self.connection.select_all("select distinct project, build from #{table_name} order by project, build").collect do |row|
      self.find(:first, :conditions => ["project = ? and build = ? and finished is not null", row['project'], row['build']], 
                        :order => 'revision desc')
    end.compact
    filter(matches, params)
  end
  
  def self.running_summary(params = {})
    matches = self.connection.select_all("select distinct project, build from #{table_name} order by project, build").collect do |row|
      self.find(:first, :conditions => ["project = ? and build = ? and finished is null", row['project'], row['build']], 
                        :order => 'revision desc')
    end.compact
    filter(matches, params)
  end
     
protected
  
  def self.filter(list, params)
    list = list.clone
    params.keys.each {|key| list = list.select {|r| r.send(key.to_sym) == params[key] } if params[key] }
    list
  end
end