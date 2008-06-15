require 'yaml'

class NotifyController < ApplicationController
  def notify                    
    Run.notify(YAML.load(params[:params]))
    redirect_to :controller => 'summary', :action => 'index'
  end
end