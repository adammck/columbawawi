#!/usr/bin/env ruby
# vim: noet

class Reporter
	include DataMapper::Resource
	has n, :children
	has n, :reports
	
	property :id, Integer, :serial=>true
	property :phone, String, :key=>true, :length=>22
	property :language, Enum[:english, :chichewa]
	property :backend, String, :length=>10
	property :name, String
	
	# Return a friendly description of this
	# reporter, using what information we have.
	def summary
		(name ? name.split[0] : nil) or phone
	end
	
	# Return everything we know about this
	# reporter, for debugging and/or logging.
	def detail
		(name ? "#{name}, " : "") + "#{backend}/#{phone}"
	end
end
