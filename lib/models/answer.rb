#!/usr/bin/env ruby
# vim: noet

class Answer 
	include DataMapper::Resource
	belongs_to :question
	has n, :entries

	property :id, Integer, :serial=>true
	property :text, String, :length=>140 

end
