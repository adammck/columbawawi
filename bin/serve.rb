#!/usr/bin/env ruby
# vim: noet

here = File.dirname(__FILE__)
require "#{here}/../lib/app/columbawawi.rb"

# load the appropriate conf, based
# on arguments (or default to dev
conf = (ARGV.length > 0) ? ARGV[0] : "dev"
require "#{here}/../conf/#{conf}.rb"

# at the moment, only the backends
# are configurable. more to come!
$conf[:backends].each_value do |be|
	SMS::add_backend *be
end

SMS::serve
