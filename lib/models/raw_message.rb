#!/usr/bin/env ruby
# vim: noet

class RawMessage
	include DataMapper::Resource
	belongs_to :reporter
	
	property :id, Integer, :serial=>true
	property :direction, Enum[:incoming, :outgoing]
	property :sent, DateTime
	property :text, Text
	
	# only relevant to incoming
	property :received, DateTime
	
	# for linking raw messages recursively
	belongs_to :in_response_to, :class_name => "RawMessage"
	has n, :responses, :class_name => "RawMessage"
end
