#!/usr/bin/env ruby
# vim: noet

$conf = {
	:backends => [
		[:GSM, "Zain", "/dev/ttyUSB0"],
		[:GSM, "TNM", "/dev/ttyUSB1"],
		:HTTP
	]
	
	:database => {
		:adapter => "mysql",
		:host => "localhost",
		:database => "columbawawi",
		:username => "unicef",
		:password => "m3p3m3p3"
	}
}
