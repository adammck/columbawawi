#!/usr/bin/env ruby
# vim: noet

$conf = {
	:backends => {
		"Zain" => [:gsm, "/dev/ttyUSB0"],
		"TNM"  => [:gsm, "/dev/ttyUSB0"],
		"HTTP" => [:http]
	},
	
	:database => {
		:adapter => "mysql",
		:host => "localhost",
		:database => "columbawawi",
		:username => "unicef",
		:password => "m3p3m3p3"
	}
}
