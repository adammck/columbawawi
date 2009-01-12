#!/usr/bin/env ruby
# vim: noet

# import datamapper
require "rubygems"
require "dm-core"
require "dm-types"

# configure the dev database
db_dir = File.expand_path(File.dirname(__FILE__) + "/../db")
DataMapper.setup(:default, "sqlite3:///#{db_dir}/dev.db")


class Child
	include DataMapper::Resource
	property :uid, String, :key=>true, :format=>/^\d{6}$/, :messages => {
		:format => "Child UID must be exactly six digits" }
	
	property :age, Integer
	property :gender, Enum[:male, :female]
	property :contact, String, :length=>22
	property :village, String, :length=>200
end

class Report
	include DataMapper::Resource
	property :id, Integer, :serial=>true
	property :uid, String
	property :weight, Integer
	property :height, Integer
	property :muac, Integer
	#belongs_to :child

	def ratio
		(attribute_get(:height)).to_f/(attribute_get(:weight)).to_f
	end

	def moderate?
		if(ratio < 0.79)
			if(ratio >= 0.70)
				return true
			end
		end
		if(attribute_get(:muac) < 11.9)
			if(attribute_get(:muac) >= 11.0)
				return true
			end
		end
		return false
	end

	def severe?
		if(ratio < 0.70)
			return true
		end
		if(attribute_get(:muac) < 11.0)
			return true
		end
		return false
	end
end
