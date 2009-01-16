#!/usr/bin/env ruby
# vim: noet


# import local dependancies
here = File.dirname(__FILE__)
require "#{here}/../models.rb"
require "#{here}/../parsers.rb"

# import rubysms, which
# is not a ruby gem yet :(
require "#{here}/../../../rubysms/lib/sms.rb"


# monkey patch the incoming message class, to
# add a slot to temporarily store a RawMessage
# object, to be found by Columbawawi#outgoing
class SMS::Incoming
	attr_accessor :raw_message
end

class Columbawawi < SMS::App
	
	Messages = {
		:dont_understand => "Sorry, I don't understand.",
		:oops => "Oops! ",
		:child => "Child ",
		
		:invalid_gmc     => 'Sorry, "%s" is not a valid GMC#.'
		:invalid_child   => "Sorry, I can't find a child with that child#. If this is a new child, please register before reporting.",
		:ask_replacement => "This child is already registered.",
		
		:help_new    => "To register a child, reply:\nnew [gmc#] [child#] [age] [gender] [contact]",
		:help_report => "To report on a child's progress:\nreport [gmc#] [child#] [weight] [height] [muac] [oedema] [diarrhea]",
		:help_cancel => "To cancel a new chld or a child's most recent report:\ncancel [gmc#] [child#]",

		:thanks_new => "Thank you for registering Child ",
		:thanks_report => "Thank you for reporting on Child ",

		:canceled_new => "New ",
		:canceled_report => "Report sent at ", 
		:canceled => " has been canceled.",

		:mal_mod     => " is moderately malnourished. Please refer to SFP and counsel caregiver on child nutrition.",
		:mal_sev     => " has severe acute malnutrition. Please refer to NRU/TFP and administer 50 ml of 10% sugar immediately.",

		:issue_shrinkage => " seems to be much shorter than last month. Please recheck the height measurement.",
		:issue_gogogadget=> " seems to be much taller than last month. Please recheck the height measurement.",
		:issue_skinnier => " seems to have lost more than 5kg since last month. Please recheck the weight measurement.",
		:issue_plumpier => " seems to have gained more than 5kg since last month. Please recheck the weight measurement.",
		:issue_pencil => " seems to have a very small MUAC. Please recheck the MUAC measurement.",
		:issue_shitty => " also had diarrhea last month. Please refer the child to a clinician.",
	}
	
	
	def initialize
		@reg = RegistrationParser.new
		@rep = ReportParser.new
		@can = CancelParser.new
	end
	
	
	
	
	def incoming(msg)
		reporter = Reporter.first_or_create(
			:phone => msg.sender)

		# create and save the log message
		# before even inspecting it, to be
		# sure that EVERYTHING is logged
		msg.raw_message =\
		RawMessage.create(
			:reporter => reporter,
			:direction => :incoming,
			:text => msg.text,
			:sent => msg.sent,
			:received => Time.now)
		
		# continue processing as usual
		super
	end
	
	def outgoing(msg)
		reporter = Reporter.first_or_create(
			:phone => msg.recipient)
		
		# if this message was spawned in response to
		# another, fetch the object, to link them up
		irt = msg.in_response_to ? msg.in_response_to.raw_message : nil
		
		# create and save the log message
		RawMessage.create(
			:reporter => reporter,
			:direction => :outgoing,
			:in_response_to => irt,
			:text => msg.text,
			:sent => Time.now)
	end




	private
	
	# Returns a Reporter object for the given phone
	# number, automatically creating it if necessary.
	def reporter(phone)
		Reporter.first_or_create(:phone => phone)
	end
	
	# check the childs recent history for alarming
	# trends and also sanity check data points 
	# by comparing childs past data
	def issues(child)
		# gather all reports most recent to oldest
		reports = child.reports.all(:order => [:date.desc]) 

		# remove the one just sent in
		report = reports.shift

		# a place to put issues, since
		# there can be several
		issues = []

		# check that MUAC is reasonable
		if(report.muac < 5.0)
			issues << :issue_pencil
		end

		# dont check for historical trends
		# if there are no other reports
		# to compare
		return issues unless reports

		# compare this months height to last months
		hd = reports.first.height - report.height

		# go go gadget legs
		if(hd < 0.0)
			issues << :issue_gogogadget

		# losing height
		elsif(hd > 2.0)
			issues << :issue_shrinkage
		end
		
		# compare this months weight to last months
		wd = reports.first.weight - report.weight

		# losing weight
		if(wd > 5.0)
			issues << :issue_skinnier

		# gaining weight
		elsif(wd < -5.0)
			issues << :issue_plumpier
		end

		# check for shitty months
		# (persistant diarrhea)
		if(report.diarrhea)
			if(reports.first.diarrhea)
				issues << :issue_shitty
			end
		end

		return issues	
	end
	
	
	public
	
	serve /\A(?:new\s*child|new|n|reg|register)(?:\s+(.+))?\Z/i
	def register(msg, str)
		
		# fetch or create a reporter object exists for
		# this caller, to own any objects that we create
		reporter = Reporter.first_or_create(:phone => msg.sender)
		
		# parse the message, and reject
		# it if no tokens could be found
		unless data = @reg.parse(str.to_s)
			return msg.respond assemble(:oops, :help_new)
		end
		
		# debug messages
		log "Parsed into: #{data.inspect}", :info
		log "Unparsed: #{@reg.unparsed.inspect}", :info\
			unless @reg.unparsed.empty?
		
		# split the UIDs back into gmc+child
		gmc_uid, child_uid = *data.delete(:uid)
		
		# fetch the gmc object; abort if it wasn't valid
		unless gmc = Gmc.first(:uid => gmc_uid)
			return msg.respond assemble(:invalid_gmc, [gmc_uid])
		end
		
		# if this child has already been registered, then there
		# is trouble afoot. we must ask what has happened, and
		# wait for a response
		if gmc.children.first(:uid => child_uid)
			return msg.respond assemble(:ask_replacement)
		end
		
		# create the new child in db
		c = gmc.children.create(
			:reporter=>reporter,
			:uid=>child_uid,
			:age=>data[:age],
			:gender=>data[:gender],
			:contact=>data[:phone])
		
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
		msg.respond assemble(:thanks_new, "#{@reg[:uid].humanize}#{suffix}")
	end
	
	
	serve /\A(?:report\s*on|report|rep|r)(?:\s+(.+))?\Z/i
	def report(msg, str)
		
		# parse the message, and reject
		# it if no tokens could be found
		unless data = @rep.parse(str)
			return msg.respond assemble(:oops, :help_report)
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
			:date => msg.sent)
		
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
		msg.respond assemble(:thanks_report, "#{@rep[:uid].humanize}#{suffix}")
		
		# send advice to the sender if the
		# child appears to be severely or
		# moderately malnourished
		if r.severe?
			msg.respond assemble(:child, "#{@rep[:uid].humanize}", :mal_sev)
			
		elsif r.moderate?
			msg.respond assemble(:child, "#{@rep[:uid].humanize}", :mal_mod)
		end
		
		# send alerts if data seems unreasonable
		# or if there are alarming trends
		alerts = issues(child)
		if(alerts)
			alerts.each do |alert|
				msg.respond assemble(:child, "#{@rep[:uid].humanize}", alert)
			end
		end
	end
	

	serve /\A(?:cancel|can|c)(?:\s+(.+))?\Z/i
	def cancel(msg, str)
		# parse the message, and reject
		# it if no tokens could be found
		unless data = @can.parse(str.to_s)
			return msg.respond assemble(:oops, :help_cancel)
		end
		
		# debug message
		log "Parsed into: #{data.inspect}", :info
		log "Unparsed: #{@can.unparsed.inspect}", :info\
			unless @can.unparsed.empty?
		
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

		# try to find the child's most recent report and destroy it
		if(report = child.reports.first(:order => [:date.desc]))

			# TODO 'on' and 'for' should be messages before this is i18n-ed
			latest = report.sent.strftime("%I:%M%p on %m/%d/%Y for ")
			report.destroy
			return msg.respond assemble(:canceled_report,"#{latest}", :child ,"#{@can[:uid].humanize}", :canceled)

		# otherwise destroy the child
		else
			child.destroy
			return msg.respond assemble(:canceled_new, :child ,"#{@can[:uid].humanize}", :canceled)
		end
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
