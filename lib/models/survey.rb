#!/usr/bin/env ruby
# vim: noet

class Survey 
	include DataMapper::Resource
	belongs_to :reporter
	belongs_to :child
	has n, :entries
	
	property :id, Integer, :serial=>true
	property :date, DateTime
end
