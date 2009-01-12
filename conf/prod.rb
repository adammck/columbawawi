#!/usr/bin/env ruby
# vim: noet

$conf = {
	:backends => {
		"Zain" => [:gsm, "/dev/ttyUSB0"],
		"TNM"  => [:gsm, "/dev/ttyUSB0"],
		"HTTP" => [:http]
	}
}
