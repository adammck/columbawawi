#!/usr/bin/env ruby
# vim: noet

class Gmc
	include DataMapper::Resource
	belongs_to :reporter
	belongs_to :district
	has n, :children
	
	property :id, Integer, :serial=>true
	property :uid, String, :key=>true, :format=>/^\d{4}$/, :messages => {
		:format => "GMC UID must be exactly four digits" }
	
	property :title, String, :length => 60
end
