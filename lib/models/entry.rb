#!/usr/bin/env ruby
# vim: noet

class Entry 
	include DataMapper::Resource
	belongs_to :survey
	belongs_to :answer

	property :id, Integer, :serial=>true
	property :date, DateTime
end
