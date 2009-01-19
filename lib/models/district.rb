#!/usr/bin/env ruby
# vim: noet

class District
	include DataMapper::Resource
	has n, :gmcs
	
	property :id, Integer, :serial=>true
	property :slug, String, :length=>60
	property :title, String, :length=>60
end
