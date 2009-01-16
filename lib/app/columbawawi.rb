#!/usr/bin/env ruby
# vim: noet


# import local dependancies
here = File.dirname(__FILE__)
require "#{here}/../models.rb"
require "#{here}/../parsers.rb"

# import rubysms, which
# is not a ruby gem yet :(
require "#{here}/../../../rubysms/lib/sms.rb"


class Columbawawi < SMS::App
	
	Messages = {
		:dont_understand => "Sorry, I don't understand.",
		
		:missing_uid => "Oops, please check the GMC# (4 numbers) and child# (2 numbers) and try again.",
		:invalid_uid => "Oops, please check the GMC# (4 numbers) and child# (2 numbers) and try again.",
		
		:invalid_gmc     => "Sorry, that GMC# is not valid.",
		:invalid_child   => "Sorry, I can't find a child with that child#. If this is a new child, please register before reporting.",
		:ask_replacement => "This child is already registered. If you wish to replace them, please reply: REPLACE",
		
		:help_new    => "To register a child, reply:\nnew [gmc#] [child#] [age] [gender] [contact]",
		:help_report => "To report on a child's progress:\nreport [gmc#] [child#] [weight] [height] [muac] [oedema] [diarrhea]",

		:mal_mod     => " is moderately malnourished. Please refer to SFP and counsel caregiver on child nutrition.",
		:mal_sev     => " has severe acute malnutrition. Please refer to NRU/ TFP. Administer 50 ml of 10% sugar immediately.",
	}
	
	
	def initialize
		@reg = RegistrationParser.new
		@rep = ReportParser.new
	end
	
	
	private
	
	def check_uid(parser, uid=nil)
		
		# the child UID is the only required
		# field, so reject if it is missing
		unless parser[:uid]
			return :missing_uid
		end
		
		# no errors
		# to report
		nil
	end
	
	
	public
	
	serve /\A(?:new\s*child|new|n|reg|register)(?:\s+(.+))?\Z/i
	def register(msg, str)
	
		# parse the message, and reject
		# it if no tokens could be found
		unless data = @reg.parse(str.to_s)
			return msg.respond assemble(:dont_understand, " ", :help_new)
		end
		
		# debug messages
		log "Parsed into: #{data.inspect}", :info
		log "Unparsed: #{@reg.unparsed.inspect}", :info\
			unless @reg.unparsed.empty?
		
		gmc_uid, child_uid = *data.delete(:uid)
		
		# fetch the gmc object; abort if it wasn't valid
		unless gmc = Gmc.first(:uid => gmc_uid)
			return msg.respond assemble(:invalid_gmc)
		end
		
		# check that this child UID hasn't
		# already been registered at this GMC
		unless gmc.children.all(:uid => child_uid).empty?
			return msg.respond assemble(:already_uid)
		end
		
		# create the new child in db
		c = gmc.children.create(
			:uid=>child_uid,
			:age=>data[:age],
			:gender=>data[:gender])
		
		# build a string summary containing all
		# of the normalized data that we just
		# parsed, as flat key=value pairs
		summary = (@reg.matches.collect do |m|
			unless m.token.name == :uid
				"#{m.token.name}=#{m.humanize}"
			end
		end).compact.join(", ")
		
		# verify receipt of this registration,
		# including all tokens that we parsed
		suffix = (summary != "") ? ": #{summary}" : ""
		msg.respond "Thank you for registering Child #{@reg[:uid].humanize}#{suffix}"
	end
	
	
	serve /\A(?:report\s*on|report|rep|r)(?:\s+(.+))?\Z/i
	def report(msg, str)
		
		# parse the message, and reject
		# it if no tokens could be found
		unless data = @rep.parse(str)
			return msg.respond assemble(:dont_understand, " ", :help_report)
		end
		
		# debug message
		log "Parsed into: #{data.inspect}", :info
		log "Unparsed: #{@rep.unparsed.inspect}", :info\
			unless @rep.unparsed.empty?
		
		# split the UIDs back into gmc+child
		gmc_uid, child_uid = *data.delete(:uid)
		
		# fetch the gmc; abort if it wasn't valid
		unless gmc = Gmc.first(:uid => gmc_uid)
			return msg.respond assemble(:invalid_gmc)
		end
		
		# same for the child
		unless child = gmc.children.first(:uid => child_uid)
			return msg.respond assemble(:invalid_child)
		end
		
		# create and save the new
		# report in the database
		r = child.reports.create(
			
			# reported fields (some may be nil,
			# which is okay). TODO: should be
			# able to just pass the data hash
			:weight => data[:weight],
			:height => data[:height],
			:muac => data[:muac],
			:oedema => data[:oedema],
			:diarrhea => data[:diarrhea],
			
			# timestamps
			:sent => msg.sent,
			:received => Time.now)
		
		# build a string summary containing all
		# of the normalized data that we just
		# parsed, as flat key=value pairs
		summary = (@rep.matches.collect do |m|
			unless m.token.name == :uid
				"#{m.token.name}=#{m.humanize}"
			end
		end).compact.join(", ")
		
		# verify receipt of this registration,
		# including all tokens that we parsed,
		# and the w/h ratio, if available
		suffix = (summary != "") ? ": #{summary}" : ""
		suffix += ", w/h%=#{r.ratio}." unless r.ratio.nil?
		msg.respond "Thank you for reporting on Child #{@rep[:uid].humanize}#{suffix}"
		
		# send advice to the sender if the
		# child appears to be severely or
		# moderately malnourished
		if r.severe?
			msg.respond assemble("Child #{@rep[:uid].humanize}", :mal_sev)
			
		elsif r.moderate?
			msg.respond assemble("Child #{@rep[:uid].humanize}", :mal_mod)
		end
	end

	
	serve /\Achildren\Z/
	def children(msg)
		summary = Child.all.collect do |child|
			child.uid
		end.compact.join(", ")
		
		msg.respond "Registered Children: #{summary}"
	end
	
	
	serve /help/
	def help(msg)
		msg.respond assemble(:help_new, "\n---\n", :help_report)
	end
	
	
	serve :anything
	def anything_else(msg)
		msg.respond assemble(:dont_understand)
	end
end
