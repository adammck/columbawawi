#!/usr/bin/env ruby
# vim: noet

puts "This will auto_migrate your database, which"
puts "will irrevocably destroy all of your data."
print "ARE YOU SURE? [y/n] "

unless STDIN.gets =~ /^y/
	puts "Aborted."
	exit
end

here = File.dirname(__FILE__)
#require "#{here}/../lib/models.rb"

# import datamapper
require "rubygems"
require "dm-core"
require "dm-types"
DataMapper.setup(:default, {:host => "localhost", :adapter => "mysql",\
				:database => "columbawawi",\
				:username => "unicef", :password => "m3p3m3p3"})
# import models
require "#{here}/../lib/models/reporter.rb"
require "#{here}/../lib/models/raw_message.rb"
require "#{here}/../lib/models/district.rb"
require "#{here}/../lib/models/gmc.rb"
require "#{here}/../lib/models/child.rb"
require "#{here}/../lib/models/report.rb"
DataMapper.auto_migrate!

# create the pilot districts and gmcs
Gmc.create(:district => District.create(:title => "Kasungu"), :uid => 1001, :title => "Tamani")
Gmc.create(:district => District.create(:title => "Salima"),  :uid => 1101, :title => "Chipoka")
Gmc.create(:district => District.create(:title => "Dedza"),   :uid => 1201, :title => "Chikuse")

# create the example district and gmc, as
# shown on the cheat-sheets and posters
Gmc.create(
	:uid => 1234,
	:title => "Example GMC",
	:district => District.create(
		:title => "Example District"))

puts "Migrated."
