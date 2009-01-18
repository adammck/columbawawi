#!/usr/bin/env ruby
# vim: noet


# import local dependancies
here = File.dirname(__FILE__)

# import datamapper
require "rubygems"
require "dm-core"
require "dm-types"
DataMapper.setup(:default, {:host => "localhost", :adapter => "mysql",\
				:database => "columbawawi",\
				:username => "unicef", :password => "m3p3m3p3"})

# import the ugly ratios
require "#{here}/../ratios.rb"

# import models
require "#{here}/../models/reporter.rb"
require "#{here}/../models/raw_message.rb"
require "#{here}/../models/district.rb"
require "#{here}/../models/gmc.rb"
require "#{here}/../models/child.rb"
require "#{here}/../models/report.rb"

# import parsers
require "#{here}/../parsers.rb"

# import rubysms, which
# is not a ruby gem yet :(
require "#{here}/../../../rubysms/lib/sms.rb"



class Columbawawi < SMS::App
	Messages = {
		:dont_understand => "Sorry, I don't understand.",
		:oops => "Oops! ",
		:child => "Child ",
		
		:invalid_gmc     => 'Sorry, "%s" is not a valid GMC#.',
		:invalid_child   => "Sorry, I can't find a child with that child#. If this is a new child, please register before reporting.",
		:ask_replacement => 'Child# %s is already registered at %s. Please reply "%s" or "%s" to confirm replacement.',
		
		:help_new    => "To register a child, reply:\nnew [gmc#] [child#] [age] [gender] [contact]",
		:help_report => "To report on a child's progress:\nreport [gmc#] [child#] [weight] [height] [muac] [oedema] [diarrhea]",
		:help_cancel => "To cancel a new chld or a child's most recent report:\ncancel [gmc#] [child#]",
		:help_remove => "To remove a child:\ndied [gmc#] [child#]\nor: quit [gmc#] [child#]",
		
		:thanks_new => "Thank you for registering Child ",
		:thanks_report => "Thank you for reporting on Child %s",
		:thanks_replace => "Thank you for replacing Child %s.",
		:thanks_remove => "Thank you for removing Child %s.",

		:canceled_new => "New ",
		:canceled_report => "Report sent at ", 
		:canceled => " has been canceled.",

		:mal_mod     => "Child %s is moderately malnourished. Please refer to SFP and counsel caregiver on child nutrition.",
		:mal_sev     => "Child %s has severe acute malnutrition. Please refer to NRU/TFP and administer 50 ml of 10%% sugar immediately.",

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
		@can = UidParser.new
		@gon = UidParser.new
		
		# to store new children while we are waiting
		# for confirmation whether they died or quit
		@replacement_child = {}
	end




	private
	
	
	# Returns a string containing a summary of
	# the data matched by a parser object. The
	# data MUST contain a UID; all other fields
	# are optional, and appended to the output
	# in their humaized form, if present.
	def summarize(parser)

		# the UID is MANDATORY		
		if parser[:uid].nil?
			raise ArgumentError
		end
		
		# concatenate all of the fields other
		# than UID, which always goes first
		summary = (parser.matches.collect do |m|
			unless m.token.name == :uid
				"#{m.token.name}=#{m.humanize}"
			end
		end).compact.join(", ")
		
		# return the mandatory UID, and if any
		# fields were summarized, append them
		suffix = (summary != "") ? ": #{summary}" : ""
		"#{parser[:uid].humanize}#{suffix}"
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
		unless data = @reg.parse(str.to_s) and data[:uid]
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
			died_msg = "DIED #{gmc_uid} #{child_uid}"
			gone_msg = "QUIT #{gmc_uid} #{child_uid}"
			
			# store parser state while we wait for the
			# confirmation, so we create the replacement
			# child object when DIED/GONE is received
			key = "#{gmc_uid}:#{child_uid}"
			@replacement_child[key] = @reg.dup
			
			return msg.respond(
				assemble( :ask_replacement,
					[child_uid, gmc.title, died_msg, gone_msg]))
		end
		
		# create the new child in db
		c = gmc.children.create(
			:reporter=>reporter,
			:uid=>child_uid,
			:age=>data[:age],
			:gender=>data[:gender],
			:contact=>data[:contact])
		
		# verify receipt of this registration,
		# including all tokens that we parsed
		msg.respond(assemble(:thanks_new, summarize(@reg)))
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
			return msg.respond assemble(:invalid_gmc, [gmc_uid])
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
		msg.respond(assemble(:thanks_report, [summarize(@rep)]))
		
		# send advice to the sender if the
		# child appears to be severely or
		# moderately malnourished
		m = r.malnourished?
		msg.respond assemble(:mal_sev, [@rep[:uid].humanize]) if m == :severe
		msg.respond assemble(:mal_mod, [@rep[:uid].humanize]) if m == :moderate
		
		# TODO: fix #issues, and re-enable these alerts
		
		# send alerts if data seems unreasonable
		# or if there are alarming trends
#		alerts = issues(child)
#		if(alerts)
#			alerts.each do |alert|
#				msg.respond assemble(:child, "#{@rep[:uid].humanize}", alert)
#			end
#		end
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

		# otherwise destroy the child by setting
		# the :cancelled_at property - it's a
		# paranoid data/time, so datamapper will
		# pretend that the object doesn't exist
		else
			child.cancelled_at = Time.now
			child.save
			
			# confirm the cancellation
			return msg.respond assemble(:canceled_new, :child ,"#{@can[:uid].humanize}", :canceled)
		end
	end
	
	
	serve /\A(died|dead|quit)(?:\s+(.+))\Z/i
	def remove_child(msg, type, str)
		
		# fetch or create a reporter object exists
		# for this caller, to own the new child
		reporter = Reporter.first_or_create(:phone => msg.sender)
		
		# parse the uid tokens from this message (we use fuzz rather than 
		# a simple regex, to accept a wide range of formatting disasters)
		unless data = @gon.parse(str.to_s)
			return msg.respond(assemble(:oops, :help_remove))
		end
		
		# debug messages
		log "Parsed into: #{data.inspect}"
		log "Unparsed: #{@gon.unparsed.inspect}", :info\
			unless @gon.unparsed.empty?
		
		# TODO: this service shares a lot of code
		# with CANCEL. abstract into a private method
		
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
		
		# destroy the child, and if we have a pending
		# replacement (because NEW was called before
		# DIED/QUIT to remove the existing child),
		# re-run that method to create the object
		m = (type =~ /\Ad/) ? "died" : "gone"
		child.send("#{m}_at=", Time.now)
		child.save
		
		key = "#{gmc_uid}:#{child_uid}"
		if @replacement_child.has_key?(key)
			
			# create the replacement child in db,
			# and remove the record from pending
			rep = @replacement_child.delete(key)
			sum = rep.summary
			
			c = gmc.children.create(
				:reporter=>reporter,
				:uid=>child_uid,
				:age=>sum[:age],
				:gender=>sum[:gender],
				:contact=>sum[:phone])
		
			# verify receipt of this replacment,
			# including all tokens that we parsed
			return msg.respond(assemble(:thanks_replace, [summarize(rep)]))
		end
		
		# no replacement, just thank for the removal
		return msg.respond(assemble(:thanks_remove, [@gon[:uid].humanize]))
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
