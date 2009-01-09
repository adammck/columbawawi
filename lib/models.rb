#!/usr/bin/env ruby
# vim: noet

# import datamapper
require "rubygems"
require "dm-core"
require "dm-types"

# cofigure the dev database
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
	property :ratio, Float
	property :muac, Integer
	#belongs_to :child
end
