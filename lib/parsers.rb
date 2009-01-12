#!/usr/bin/env ruby
# vim: noet

# import fuzz (no gem yet)
projects = File.expand_path(File.dirname(__FILE__) + "/../..")
require "#{projects}/fuzz/lib/fuzz.rb"


# custom fuzz tokens
class UID < Fuzz::Token::Base
	Pattern = '(?:child\s*)?(?:u?id\s*)?(\d{1,10})\s*[:;\.]?'
end

class Village < Fuzz::Token::Base
	Pattern = '(?:from|of)?([a-z]+)'
	
	# because it's very loose, the village
	# name must come at the end of the msg
	Options = {
		:last => true }
end


class RegistrationParser < Fuzz::Parser
	def initialize
		super
		
		# create a form to parse all
		# of the model fields for Child
		add_token "UID", UID
		add_token "Gender", :gender
		add_token "Age", :age, { :default_unit => :month, :humanize_unit => :month }
		add_token "Contact", :phone
		add_token "Village", Village
	end
end

class ReportParser < Fuzz::Parser
	def initialize
		super
		
		# as above, for the
		# Report model form
		add_token "UID", UID
		add_token "Weight", :weight
		add_token "Height", :height
		add_token "MUAC", :length
	end
end
