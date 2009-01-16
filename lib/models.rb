#!/usr/bin/env ruby
# vim: noet

# import datamapper
require "rubygems"
require "dm-core"
require "dm-types"

# configure the dev database
db_dir = File.expand_path(File.dirname(__FILE__) + "/../db")
DataMapper.setup(:default, "sqlite3:///#{db_dir}/dev.db")


class District
	include DataMapper::Resource
	has n, :gmcs
	
	property :id, Integer, :serial=>true
	property :title, String, :length => 60
end


class Gmc
	include DataMapper::Resource
	belongs_to :district
	has n, :children
	
	property :id, Integer, :serial=>true
	property :uid, String, :key=>true, :format=>/^\d{4}$/, :messages => {
		:format => "GMC UID must be exactly four digits" }
	
	property :title, String, :length => 60
end


class Child
	include DataMapper::Resource
	belongs_to :gmc
	has n, :reports
	
	property :id, Integer, :serial=>true
	property :uid, String, :key=>true, :format=>/^\d{2}$/, :messages => {
		:format => "Child ID must be exactly two digits" }
	
	property :age, DateTime
	property :gender, Enum[:male, :female]
	property :contact, String, :length=>22
end


class Report
	include DataMapper::Resource
	belongs_to :child
	
	property :id, Integer, :serial=>true
	
	property :weight, Float 
	property :height, Float 
	property :muac, Float
	property :oedema, Boolean
	property :diarrhea, Boolean
	
	property :sent, DateTime
	property :received, DateTime
	# TODO issue flag
	belongs_to :child

	
	# Returns the weight to height ratio of
	# this report, or nil, if either fields
	# are missing.
	# TODO calculate this properly
	def ratio
		w = attribute_get(:weight)
		h = attribute_get(:height)
		(w && h) ? sprintf("%.2f", w/h).to_f : nil
	end

	# Returns _true_ if this report indicates a moderately malnourished
	# child. Note that _false_ is returned if we cannot tell (due to the
	# _ratio_ or _muac_ being nil), the child is severely malnourished,
	# or the child is not malnourished at all.
	def moderate?
		(!ratio.nil? and ratio > 0.70 and ratio < 0.79)\
		or (!muac.nil? and muac > 11.0 and muac < 11.9)
	end

	# Returns true if this report indicates a severely malnourished
	# child, or false if we cannot tell (due to _ratio_ or _muac_
	# being nil), or the child is not severely malnourished.
	def severe?
		(!ratio.nil? and ratio <= 0.70)\
		or (!muac.nil? and muac <= 11.0)\
		or (oedema)
	end
end
