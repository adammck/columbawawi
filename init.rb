#!/usr/bin/env ruby
# vim: noet

# import models and blitz the database
here = File.expand_path(File.dirname(__FILE__))
require "#{here}/lib/models.rb"
DataMapper.auto_migrate!
