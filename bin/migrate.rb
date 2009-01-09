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
require "#{here}/../lib/models.rb"
DataMapper.auto_migrate!
puts "Done."
