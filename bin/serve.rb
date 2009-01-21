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

# load the app statically, for now
require "#{here}/../lib/app/columbawawi.rb"

# create the sms router, and
# add each backend from conf
router = SMS::Router.new
seen = []

# TODO: move this conf stuff into RubySMS,
# without turning it into a (gasp!) FRAMEWORK

$conf[:backends].each do |be_conf|
	klass_name, label, *args = *be_conf
	
	# initialize the backend from
	# its constant name (arg#1)
	klass = SMS::Backend.const_get(klass_name)
	inst = klass.new(*args)
	
	# if no label was provided (arg#2 in conf),
	# then assign the class name and it's index
	# (so multiple backends of the same class
	# are labelled EXAMPLE:1, EXAMPLE:2, etc)
	unless label
		index = seen.count(:klass)
		label = "#{klass.to_s.scan(/[a-z]+\Z/i)[0]}:#{index}"
	end
	
	inst.label = label
	seen.push klass
	
	# add this backend
	router.add inst
end

# add the columbawawi app, since
# multiple apps DON'T WORK YET :|
router.add Columbawawi.new

# start waiting for
# incoming messages
router.serve_forever
