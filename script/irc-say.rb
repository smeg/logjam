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
require 'open-uri'

NICK = 'RUBYCONF'
USER = ENV['USER'] || ENV['USERNAME'] || ENV['LOGNAME'] || NICK
REAL = 'RUBYCONF'
CHANNEL = '#rails'
SLEEP = 180 

Thread.abort_on_exception = true   # turn on for debugging

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
    subject.push(privmsg(CHANNEL, "RUBYCONF UPDATED!!!"))
    subject.push(topic(CHANNEL, "RUBYCONF has been updated!!!!"))
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
c = RICE::Connection.new('svn.stone', 6667)
c.add_observer(o)

last = nil
recent = nil
open('http://www.rubyconf.com') {|f| last =  f.last_modified }

puts "Rubyconf last modified on [#{last.to_s}]"

# periodically poll the build summary to see if there's a new finished build
while true do
  STDERR.puts "Checking (#{Time.now})"
  open('http://www.rubyconf.com') {|f| recent =  f.last_modified }
  puts "Rubyconf most recently modified on [#{recent.to_s}]"

  if recent > last
    begin
      c.start
    rescue RICE::Connection::Closed
    end
  end
  sleep SLEEP
end
