#!/usr/bin/env ruby
# vim: noet

puts "This will auto_migrate your database, which"
puts "will irrevocably destroy all of your data."
print "ARE YOU SURE? [y/n] "

# confirm that we REALLY
# want to destroy everything
unless STDIN.gets =~ /^y/
	puts "Aborted."
	exit
end




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
DataMapper.auto_migrate!




# create the pilot districts and gmcs
Gmc.create(:district => District.create(:title => "Kasungu", :slug => "kasungu"), :uid => 1001, :slug => "tamani",  :title => "Tamani")
Gmc.create(:district => District.create(:title => "Salima",  :slug => "salima"),  :uid => 1101, :slug => "chipoka", :title => "Chipoka")
Gmc.create(:district => District.create(:title => "Dedza",   :slug => "dedza"),   :uid => 1201, :slug => "chikuse", :title => "Chikuse")

# create the example district and gmc, as
# shown on the cheat-sheets and posters
Gmc.create(
	:uid => 1234,
	:title => "Example GMC",
	:slug => "example",
	:district => District.create(
		:title => "Example District",
		:slug => "example"))

puts "Migrated."
