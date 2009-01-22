#!/usr/bin/env ruby
# vim: noet


here = File.dirname(__FILE__)

# load the appropriate conf, based
# on arguments (or default to dev
conf = (ARGV.length > 0) ? ARGV[0] : "dev"
require "#{here}/../conf/#{conf}.rb"

# load all models
require "#{here}/../lib/models.rb"

# configure the database from conf
db_dir = File.expand_path("#{here}/../db")
DataMapper.setup(:default, $conf[:database])

# DESTROY THE CHILDREN
DataMapper.auto_upgrade!

29.times{|i| Question.create }
Question.all.each{|m| 10.times{|a| Answer.create(:question => m)}}

puts "Migrated."
