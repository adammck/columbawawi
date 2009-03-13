#!/usr/bin/env ruby
# vim: noet

$conf = {
	:backends => [
		# serve mootools via the webui, so we can run offline
		[:HTTP, "HTTP", 1270, "http://localhost:4000/javascripts/mootools-1.2.1-core-yc.js"],
		[:GSM, "Zain", "/dev/ttyUSB0"],
		[:GSM, "TNM", "/dev/ttyUSB1"]
	],
	
	:database => {
		:adapter => "mysql",
		:host => "localhost",
		:database => "columbawawi-prod",
		:username => "root",
		:password => ""
	}
}
