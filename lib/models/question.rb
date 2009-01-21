#!/usr/bin/env ruby
# vim: noet

class Question 
	include DataMapper::Resource
	has n, :answers

	property :id, Integer, :serial=>true
	property :text, String, :length=>140 

end
