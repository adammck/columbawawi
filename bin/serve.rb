#!/usr/bin/env ruby
# vim: noet

here = File.dirname(__FILE__)
require "#{here}/../lib/app/columbawawi.rb"

# use the argument(s) as the sms
# backend(s), or default to gsm

if ARGV.length > 0
	ARGV.each do |arg|
		SMS::add_backend arg
	end

else
	# default to a single
	# rubygsm backend
	SMS::add_backend :gsm	
end

SMS::serve
