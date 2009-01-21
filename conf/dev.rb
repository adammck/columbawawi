#!/usr/bin/env ruby
# vim: noet

$conf = {
	:backends =>\
		[:HTTP, :DRB],
	
	:database => {
		:adapter => "mysql",
		:host => "localhost",
		:database => "columbawawi-dev",
		:username => "unicef",
		:password => "m3p3m3p3"
	}
}
