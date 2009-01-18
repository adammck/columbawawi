#!/usr/bin/env ruby
# vim: noet

# import datamapper
require "rubygems"
require "dm-core"
require "dm-types"

# import ALL models
here = File.dirname(__FILE__)
require "#{here}/models/reporter.rb"
require "#{here}/models/raw_message.rb"
require "#{here}/models/district.rb"
require "#{here}/models/gmc.rb"
require "#{here}/models/child.rb"
require "#{here}/models/report.rb"
