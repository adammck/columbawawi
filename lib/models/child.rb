#!/usr/bin/env ruby
# vim: noet

class Child
	include DataMapper::Resource
	belongs_to :reporter
	belongs_to :gmc
	has n, :reports
	
	property :id, Integer, :serial=>true
	property :uid, String, :key=>true, :format=>/^\d{2}$/, :messages => {
		:format => "Child ID must be exactly two digits" }
	
	# child can be destroyed in a variety of ways
	property :cancelled_at, ParanoidDateTime
	property :died_at, ParanoidDateTime
	property :gone_at, ParanoidDateTime

	property :age, DateTime
	property :gender, Enum[:male, :female]
	property :contact, String, :length=>22
end
