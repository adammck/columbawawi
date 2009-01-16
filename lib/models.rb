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
	property :id, Integer, :serial=>true
	property :title, String
end

class Gmc
	include DataMapper::Resource
	belongs_to :district
	
	property :id, Integer, :serial=>true
	property :uid, String, :key=>true, :format=>/^\d{4}$/, :messages => {
		:format => "GMC UID must be exactly six digits" }
	
	property :title, String
end

class Child
	include DataMapper::Resource
	belongs_to :gmc

	property :id, Integer, :serial=>true
	property :uid, String, :key=>true, :format=>/^\d{2}$/, :messages => {
		:format => "Child ID must be exactly two digits" }
	
	property :age, DateTime
	property :gender, Enum[:male, :female]
	property :contact, String, :length=>22
	property :village, String, :length=>200
end

class Report
	include DataMapper::Resource
	property :id, Integer, :serial=>true
	property :weight, Float 
	property :height, Float 
	property :muac, Float
	property :oedema, Boolean, :default => false
	property :diarrhea, Boolean
	
	property :sent, DateTime
	property :received, DateTime
	belongs_to :child

	def ratio
		sprintf("%.2f", attribute_get(:weight)/attribute_get(:height)).to_f
	end

	def moderate?
		if(ratio < 0.79)
			if(ratio > 0.70)
				return true
			end
		end
		if(attribute_get(:muac) < 11.9)
			if(attribute_get(:muac) > 11.0)
				return true
			end
		end
		return false
	end

	def severe?
		if(ratio <= 0.70)
			return true
		end
		if(attribute_get(:muac) <= 11.0)
			return true
		end
		if(attribute_get(:oedema))
			return true
		end
		return false
	end
end
