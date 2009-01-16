#!/usr/bin/env ruby
# vim: noet

# import models
here = File.dirname(__FILE__)
require "#{here}/../lib/models.rb"

# list all incoming messages, and
# their nested outgoing messages
RawMessage.all(:direction=>:incoming).each do |m|
	puts m.reporter.phone
	puts m.text
	
	m.responses.all.each do |mm|
		puts "  " + mm.text
	end
end
