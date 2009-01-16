#!/usr/bin/env ruby
# vim: noet

# import fuzz (no gem yet)
projects = File.expand_path(File.dirname(__FILE__) + "/../..")
require "#{projects}/fuzz/lib/fuzz.rb"


# custom fuzz tokens
class UID < Fuzz::Token::Base
	Pattern = '(\d{4})' + '(?:' + Fuzz::Delimiter + ')' + '(\d{1,2})'

	def normalize(gmc_str, child_str)
		child_str.length == 1 ? (child = '0' + child_str) : (child = child_str)
		(gmc_str + child).to_i
	end
	
	def humanize(uid_i)
		gmc = uid_i.to_s.slice(0..3)
		kid = uid_i.to_s.slice(4..6)
		kid << ' at GMC ' << gmc
	end
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
		#add_token "Village", Village
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
		add_token "Oedema", :boolean
		add_token "Diarrhea", :boolean
	end
end
