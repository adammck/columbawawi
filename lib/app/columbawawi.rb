#!/usr/bin/env ruby
# vim: noet


# import local dependancies
here = File.dirname(__FILE__)
require "#{here}/../models.rb"
require "#{here}/../parsers.rb"

# import rubysms, which does
# is not a ruby gem yet :(
require "#{here}/../../../rubysms/lib/sms.rb"


class Columbawawi < SMS::App
	
	Messages = {
		:dont_understand => "Sorry, I don't understand.",
		
		:missing_uid => "Please provide a child ID.",
		:invalid_uid => "Please provide a valid child ID (6 numbers).",
		:notyet_uid  => "Sorry, that child ID has not been registerd yet.",
		:already_uid => "Sorry, that child ID has already been registered.",
		
		:help_new    => "To register a child, reply:\nnew child [id] [age] [gender] [contact] [village]",
		:help_report =>  "To report on a child's progress:\nreport [id] [weight] [height] [ratio] [muac]",

		:mal_mod     => " is moderately malnourished. Please refer to Supplementary Feeding Programme (SFP) and counsel caregiver on child nutrition.",
		:mal_sev     => " has severe acute malnutrition. Please refer child to the NRU/ TFP.  Administer 50 ml of 10% sugar to child immediately to prevent hypoglycaemia and explain to caregiver the reason for admission and centre procedures.",
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
	
	serve /\A(?:new\s*child|new|reg|register)(.+)\Z/
	def register(msg, str)
	
		# parse the message, and reject
		# it if no tokens could be found
		unless data = @reg.parse(str)
			msg.respond assemble(:dont_understand, " ", :help_new)
		end
		
		# debug messages
		log "Parsed into: #{data.inspect}", :info
		log "Unparsed: #{@reg.unparsed.inspect}", :info\
			unless @reg.unparsed.empty?
		
		# check that the child UID was
		# provided and valid (may abort)
		err = check_uid(@reg)
		msg.respond assemble(err)\
			unless err.nil?
		
		# check that this child UID
		# hasn't already been registered
		if c = Child.get(data[:uid])
			msg.respond assemble(:already_uid)
		end
		
		# create the new child in db
		c = Child.create(data)
		c.save
		
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
		msg.respond "Thank you for registering Child #{data[:uid]}#{suffix}"
	end
	
	
	serve /\A(?:report\s*on|report|rep|r)(.+)\Z/
	def report(msg, str)
		
		# parse the message, and reject
		# it if no tokens could be found
		unless data = @rep.parse(str)
			msg.respond assemble(:dont_understand, " ", :help_report)
		end
		
		# debug message
		log "Parsed into: #{data.inspect}", :info
		log "Unparsed: #{@rep.unparsed.inspect}", :info\
			unless @rep.unparsed.empty?
		
		# check that the child UID was
		# provided and valid (may abort)
		err = check_uid(@rep)
		msg.respond assemble(err)\
			unless err.nil?
		
		# fetch the child, and abort if
		# none could be found by the UID
		#uid = data.delete(:uid)
		unless c = Child.get(data[:uid])
			msg.respond assemble(:notyet_uid)
		end
		
		#sdata[:child_id] = c.id
		#puts data.inspect
		# creaate the Report object in db
		r = Report.create(data)
		r.save
		
		# build a string summary containing all
		# of the normalized data that we just
		# parsed, as flat key=value pairs
		summary = (@rep.matches.collect do |m|
			unless m.token.name == :uid
				"#{m.token.name}=#{m.value}"
			end
		end).compact.join(", ")
		
		# verify receipt of this registration,
		# including all tokens that we parsed
		suffix = (summary != "") ? ": #{summary}, ratio=#{r.ratio}." : ""
		if(r.severe?)
			advice = " Child #{data[:uid]} #{Messages[:mal_sev]}"
		elsif(r.moderate?)
			advice = " Child #{data[:uid]} #{Messages[:mal_mod]}"
		else
			advice = ""
		end
		msg.respond "Thank you for reporting on Child #{data[:uid]}#{suffix}#{advice}"
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
