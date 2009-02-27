#!/usr/bin/env ruby
# vim: noet

require "rubygems"
require "json"

class Gmc
	include DataMapper::Resource
	belongs_to :reporter
	belongs_to :district
	has n, :children
	
	property :id, Integer, :serial=>true
	property :uid, String, :key=>true, :format=>/^\d{4}$/, :messages => {
		:format => "GMC UID must be exactly four digits" }
	
	property :slug, String, :length=>60
	property :title, String, :length=>60
	
	# coordinates for mapping
	property :latitude, Float
	property :longitude, Float
	
	# Returns true if this Gmc
	# has both geo-coordinates.
	def coords?
		latitude && longitude
	end
	
	def to_json
		{
			:id => id,
			:slug => slug,
			:title => title,
			:latitude => latitude,
			:longitude => longitude
		}.to_json
	end
	
	# Returns all of the Reports which belong to Children
	# which belong to this GMC, along with any additional
	# filters provided in _opts_.
	def reports(opts={})
		Report.all({ "child.gmc.id" => id }.merge(opts))
	end
end
