class SummaryController < ApplicationController
  def index
    @summary = Run.finished_summary
    @running = Run.running_summary
    @good = summarize(@summary)
    @title = "LogJam - #{@good ? 'All builds successful' : 'Build(s) broken.'}" 
  end
  
protected
  
  def summarize(runs)
    runs.inject(true) {|good, run| good &= (run.status =~ /^(?:success|running|revived)/); good }
  end
end
