#!/usr/bin/env ruby
# vim: noet

class Child
	include DataMapper::Resource
	belongs_to :reporter
	belongs_to :gmc
	has n, :reports
	has n, :surveys
	
	property :id, Integer, :serial=>true
	property :uid, String, :key=>true, :format=>/^\d{2}$/, :messages => {
		:format => "Child ID must be exactly two digits" }
	
	# child can be destroyed in a variety of ways
	property :cancelled_at, ParanoidDateTime
	property :died_at, ParanoidDateTime
	property :gone_at, ParanoidDateTime

	property :birthday, DateTime
	property :gender, Enum[:male, :female]
	property :contact, String, :length=>22
	
	# Returns the age of this child, in
	# months, based on their birthday.
	def age_in_months
		return nil unless birthday
		n = DateTime.now
		
		((n.year - birthday.year) * 12) +\
			(n.month - birthday.month)
	end
end
