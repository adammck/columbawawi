#!/usr/bin/env ruby
# vim: noet

$conf = {
	:backends => [
		# serve mootools via the webui, so we can run offline
		[:HTTP, "HTTP", "http://localhost:4000/javascripts/mootools-1.2.1-core-yc.js"],
		:DRB
	],
	
	:database => {
		:adapter => "mysql",
		:host => "localhost",
		:database => "columbawawi",
		:username => "unicef",
		:password => "m3p3m3p3"
	}
}
