#!/usr/bin/env ruby
# vim: noet

require "dm-is-tree"

class RawMessage
	include DataMapper::Resource
	belongs_to :reporter

	property :id, Integer, :serial=>true
	property :direction, Enum[:incoming, :outgoing]
	property :sent, DateTime
	property :text, Text
	
	# only relevant to incoming
	property :received, DateTime
	
	# allow messages to be nested, to keep track
	# of which were sent in response to another
	property :in_response_to, Integer
	is_tree :order => :id, :child_key => :in_response_to
end
