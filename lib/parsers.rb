#!/usr/bin/env ruby
# vim: noet

# import fuzz (no gem yet)
projects = File.expand_path(File.dirname(__FILE__) + "/../..")
require "#{projects}/fuzz/lib/fuzz.rb"


# custom fuzz tokens
class UID < Fuzz::Token::Base
	Pattern = '(?:child\s*)?(?:u?id\s*)?(\d{1,10})\s*[:;\.]?'
end


class RegistrationParser < Fuzz::Parser
	def initialize
		super
		
		# create a form to parse all
		# of the model fields for Child
		add_token "UID", UID
		add_token "Gender", :gender
		add_token "Age", :age
		add_token "Contact", :phone
		add_token "Village", :letters, { :last => true }
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
		add_token "Ratio", :ratio
		add_token "MUAC", :length
	end
end
