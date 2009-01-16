#!/usr/bin/env ruby
# vim: noet

# import fuzz (no gem yet)
projects = File.expand_path(File.dirname(__FILE__) + "/../..")
require "#{projects}/fuzz/lib/fuzz.rb"


# custom fuzz tokens
class UID < Fuzz::Token::Base
	Pattern = '(\d{4})' + '(?:' + Fuzz::Delimiter + ')' + '(\d{1,2})'

	def normalize(gmc_str, child_str)
	
		# regardless of what we received, add leading zeroes
		# to pad the gmc and child uids to the correct length
		["%04d" % gmc_str, "%02d" % child_str]
	end
	
	def humanize(uids)
		g, c = *uids
		
		# fetch the Gmc object, so we can include its
		# string title in the output. can't do this
		# for child, because it may not exist yet
		gmc = Gmc.first(:uid => g)
		"#{c} at #{gmc.title}"
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
