#!/usr/bin/ruby

#
#  IRC notifier.  Slightly adapted from the examples for the Ruby-Rice IRC library.
#
#    To post to IRC about the build status of project 'centernet', I run this like:
#       PROJECT=centernet RAILS_ENV=production script/marvin.rb
#
#  Can also filter on ENV['BUILD'] (e.g., all postgres builds)

require File.dirname(__FILE__) + '/../config/boot'
require File.dirname(__FILE__) + '/../config/environment'
require 'rice/irc'
require 'rice/observer'

NICK = 'Marvin'
USER = ENV['USER'] || ENV['USERNAME'] || ENV['LOGNAME'] || NICK
REAL = 'Marvin'
CHANNEL = '#rails'
SLEEP = 15

Thread.abort_on_exception = true   # turn on for debugging

class RICE::Observer
  attr_writer :filter

  # fetch us a fortune
  def build_fortune
    `/usr/games/fortune`
  end

  # build the proper topic
  def build_topic
    summary = Run.finished_summary(@filter)
    last_run = summary.sort_by {|r| r.finished }.last
    broken = summary.inject([]) {|b, r| b << r if r.status =~ /fail|broke/; b } 
    if broken.length > 0
      status = "Broken builds (" + broken.collect {|r| "#{r.project} on #{r.build}"}.join(', ') + ")"
    else
      status = "All builds working"
    end
    status + " after commit \##{last_run.revision} by #{last_run.committer} (#{Time.now})."
  end
end

o = RICE::Observer.new
class << o
  include RICE::Command
  include RICE::Reply

  def uped(subject, message)
    subject.push(nick(::NICK))
    subject.push(user(::USER, '0', '*', ::REAL))
  end

  def response_for_rpl_welcome(subject, message)
    subject.push(join(CHANNEL))
  end

  def response_for_join(subject, message)
    build_fortune.split("\n").each {|f| subject.push(privmsg(CHANNEL, f)) }
    subject.push(topic(CHANNEL, build_topic))
    subject.push(quit)
  end

  def response_for_privmsg(subject, message)
  end

  def message(subject, message)
  end

  def downed(subject, message)
  end
end

# build IRC object, observer, prepare filter
c = RICE::Connection.new('irc.stone', 6667)
filter = {}
filter[:project] = ENV['PROJECT'] if ENV['PROJECT'] and ENV['PROJECT'] != ''
filter[:build] = ENV['BUILD'] if ENV['BUILD'] and ENV['BUILD'] != ''
o.filter = filter
c.add_observer(o)

last_event = Time.now

# periodically poll the build summary to see if there's a new finished build
while true do
  STDERR.puts "Checking (#{Time.now})"
  if Run.finished_summary(filter).detect {|r| r.finished > last_event }
    begin
      c.start
    rescue RICE::Connection::Closed
    end
    last_event = Time.now
  end
  sleep SLEEP
end
