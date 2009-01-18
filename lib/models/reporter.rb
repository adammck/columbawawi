#!/usr/bin/env ruby
# vim: noet

class Reporter
	include DataMapper::Resource
	has n, :children
	has n, :reports
	
	property :id, Integer, :serial=>true
	property :phone, String, :key=>true, :length=>22
end
