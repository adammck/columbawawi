#!/usr/bin/env ruby
# vim: noet

here = File.dirname(__FILE__)
require "#{here}/../lib/app/columbawawi.rb"

# use the first argument as the
# sms backend, or default to gsm
backend = (ARGV.length == 0) ? (:gsm) : ARGV[0]
SMS::serve_forever(backend)
