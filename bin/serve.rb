#!/usr/bin/env ruby
# vim: noet

here = File.dirname(__FILE__)

# load the appropriate conf, based
# on arguments (or default to dev
conf = (ARGV.length > 0) ? ARGV[0] : "dev"
require "#{here}/../conf/#{conf}.rb"

# load ALL models automatically
require "#{here}/../lib/models.rb"

# configure the database from conf
db_dir = File.expand_path("#{here}/../db")
DataMapper.setup(:default, $conf[:database])

# load all applications statically, for now
require "#{here}/../lib/app/columbawawi.rb"
#require "#{here}/../lib/app/logger.rb"

# at the moment, only the backends
# are configurable. more to come!
$conf[:backends].each_value do |be|
	SMS::add_backend *be
end

SMS::serve
