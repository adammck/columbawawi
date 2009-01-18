#!/usr/bin/env ruby
# vim: noet


# import local dependancies
here = File.dirname(__FILE__)
#require "#{here}/../models.rb"

require "#{here}/../models/reporter.rb"
require "#{here}/../models/raw_message.rb"
require "#{here}/../models/district.rb"
require "#{here}/../models/gmc.rb"
require "#{here}/../models/child.rb"
require "#{here}/../models/report.rb"

# monkey patch the incoming message class, to
# add a slot to temporarily store a RawMessage
# object, to be found by Logger#outgoing
class SMS::Incoming
	attr_accessor :raw_message
end


class Logger < SMS::App
	def incoming(msg)
		reporter = Reporter.first_or_create(
			:phone => msg.sender) 

		# create and save the log message
		# before even inspecting it, to be
		# sure that EVERYTHING is logged
		msg.raw_message =\
		RawMessage.create(
			:reporter => reporter,
			:direction => :incoming,
			:text => msg.text,
			:sent => msg.sent,
			:received => Time.now)
		
		# continue processing
		# messages as usual
		super
	end
	
	def outgoing(msg)
		reporter = Reporter.first_or_create(
			:phone => msg.recipient)
		
		# if this message was spawned in response to
		# another, fetch the object, to link them up
		irt = msg.in_response_to
		raw_msg = irt ? irt.raw_message : nil
		
		# create and save the log message
		rm = RawMessage.create(
			:reporter => reporter,
			:direction => :outgoing,
			:in_response_to => raw_msg,
			:text => msg.text,
			:sent => Time.now)
	end
end
