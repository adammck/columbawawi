#!/usr/bin/env ruby
# vim: noet


# import parsers
here = File.dirname(__FILE__)
require "#{here}/../parsers.rb"

# import rubysms, which
# is not a ruby gem yet :(
require "#{here}/../../../rubysms/lib/rubysms.rb"


# monkey patch the incoming message class, to
# add a slot to temporarily store a RawMessage
# object, to be found by Columbawawi#outgoing
class SMS::Incoming
	attr_accessor :raw_message
end


class Columbawawi < SMS::App
	Messages = {
		:dont_understand => 'Sorry, I do not understand "%s"',
		:oops => "Oops! ",
		:child => "Child ",
		
		:invalid_gmc     => 'Sorry, "%s" is not a valid GMC#.',
		:invalid_child   => "Sorry, I can't find a Child# %s. If this is a new child, please register before reporting.",
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
		:canceled => "Child %s has been canceled.",

		:mal_mod     => "Child %s is moderately malnourished. Please refer to SFP and counsel caregiver on child nutrition.",
		:mal_sev     => "Child %s has severe acute malnutrition. Please refer to NRU/TFP and administer 50 ml of 10%% sugar immediately.",

		:issue_shorter => "Child %s seems to be much shorter than last time. Please recheck the height measurement.",
		:issue_taller => "Child %s seems to be much taller than last time. Please recheck the height measurement.",
		:issue_too_tall => "Child %s seems to be very tall. Please recheck height measurement.",
		:issue_too_short => "Child %s seems to be very short. Please recheck height measurement.",

		:issue_lighter => "Child %s seems to have lost more than 3kg since last time. Please recheck the weight measurement.",
		:issue_heavier => "Child %s seems to have gained more than 3kg since last time. Please recheck the weight measurement.",
		:issue_too_light => "Child %s seems to be very light. Please recheck weight measurement.",
		:issue_too_heavy => "Child %s seems to be very heavy. Please recheck weight measurement.",

		:issue_too_big => "Child %s seems to have a very large MUAC. Please recheck the MUAC measurement.",
		:issue_too_small => "Child %s seems to have a very small MUAC. Please recheck the MUAC measurement.",
		:issue_too_young => "Child %s is too young for MUAC measurements. Only collect MUAC if child is older than 6 months.",
		:issue_diarrhea => "Child %s also had diarrhea last time. Please refer the child to a clinician.",
	}
	
	
	def initialize
		@reg = RegistrationParser.new
		@rep = ReportParser.new
		@can = UidParser.new
		@gon = UidParser.new
		@sur = UidParser.new

		# to store new children while we are waiting
		# for confirmation whether they died or quit
		@replacement_child = {}
	end
	
	
	def incoming(msg)
		reporter = identify(msg)

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
		
		# continue processing
		# messages as usual
		super
	end
	
	def outgoing(msg)
		reporter = identify(msg)
		
		# if this message was spawned in response to
		# another, fetch the object, to link them up
		irt = msg.in_response_to
		obj = irt ? irt.raw_message.children : RawMessage
		
		# create and save the log message
		obj.create(
			:reporter => reporter,
			:direction => :outgoing,
			:text => msg.text,
			:sent => Time.now)
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
	def issues(report)

		# gather insanities and transform into :issue_insanity
		issues = (report.insanities.collect do  |insanity| 
			("issue_" + insanity.to_s).to_sym if insanity
		end).compact

		# check for shitty months
		# (persistent diarrhea)
		issues << :issue_diarrhea if report.persistent_diarrhea?

		return issues 
	end
	

	# finds or creates a reporter from a number
	def identify(msg)


		# fetch or create a reporter object exists for
		# this caller, to own any objects that we create
		reporter = Reporter.first_or_create(:phone => msg.number.to_s)

		# set backend in separate step so a backend
		# will be added to existing reporters
		reporter.update_attributes(:backend => msg.backend.label.to_s) unless reporter.backend

		return reporter
	end
	
	public
	
	serve /\A(?:new)(?:\s+(.+?)\s*)?(?=new|\Z)/i
	def register(msg, str)
		
		reporter = identify(msg)	

		# parse the message, and reject
		# it if no tokens could be found
		unless data = @reg.parse(str.to_s) and data[:uid]
			return msg.respond(assemble(:oops, :help_new))
		end

		# debug messages
		log "Parsed into: #{data.inspect}", :info
		log "Unparsed: #{@reg.unparsed.inspect}", :info\
			unless @reg.unparsed.empty?

		# split the UIDs back into gmc+child
		gmc_uid, child_uid = *data.delete(:uid)

		# fetch the gmc object; abort if it wasn't valid
		unless gmc = Gmc.first(:uid => gmc_uid)
			return msg.respond(assemble(:invalid_gmc, [gmc_uid]))
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
			:birthday=>data[:age],
			:gender=>data[:gender],
			:contact=>data[:contact])

		# verify receipt of this registration,
		# including all tokens that we parsed
		msg.respond(assemble(:thanks_new, summarize(@reg)))
	end
	
	
	serve /\A(?:report)(?:\s+(.+?)\s*)?(?=report|\Z)/i
	def report(msg, str)
		
		reporter = identify(msg)

		# parse the message, and reject
		# it if no tokens could be found
		unless data = @rep.parse(str)
			return msg.respond(assemble(:oops, :help_report))
		end
		
		# debug message
		log "Parsed into: #{data.inspect}", :info
		log "Unparsed: #{@rep.unparsed.inspect}", :info\
			unless @rep.unparsed.empty?
		
		# split the UIDs back into gmc+child
		gmc_uid, child_uid = *data.delete(:uid)
		
		# fetch the gmc; abort if it wasn't valid
		unless gmc = Gmc.first(:uid => gmc_uid)
			return msg.respond(assemble(:invalid_gmc, [gmc_uid]))
		end
		
		# same for the child
		unless child = gmc.children.first(:uid => child_uid)
			return msg.respond(assemble(:invalid_child, [@rep[:uid].humanize]))
		end
		
		# create and save the new
		# report in the database
		r = child.reports.create(
			
			:reporter => reporter,
			# reported fields (some may be nil,
			# which is okay). TODO: should be
			# able to just pass the data hash
			:weight => data[:weight],
			:height => data[:height],
			:muac => data[:muac],
			:oedema => data[:oedema],
			:diarrhea => data[:diarrhea],
			:date => msg.sent)
		

		ratio = ", w/h%=#{r.ratio}" unless r.ratio.nil?
		msg.respond(assemble(:thanks_report, [summarize(@rep) + ratio]))
		
		# send advice to the sender if the
		# child appears to be severely or
		# moderately malnourished
		m = r.malnourished?
		msg.respond(assemble(:mal_sev, [@rep[:uid].humanize])) if m == :severe
		msg.respond(assemble(:mal_mod, [@rep[:uid].humanize])) if m == :moderate
		
		
		# send alerts if data seems unreasonable
		# or if there are alarming trends
		alerts = issues(r)
		if(alerts)
			alerts.each do |alert|
				msg.respond(assemble(alert, [@rep[:uid].humanize]))
			end
		end

		# silently cancel previous report if this
		# report appears to be a replacement for it
		r.previous.attribute_set(:cancelled => true)\
			if r.looks_like_amendment?
	end


	serve /\A(?:survey|sur|s)\s+(\d{4}\s+\d{2})\s+([\*\d\s]+)\Z/i
	def survey(msg, uid, str) 

		reporter = identify(msg)	

		# parse the message, and reject
		# it if no tokens could be found
		unless data = @sur.parse(uid.to_s)
			return msg.respond(assemble(:oops, :help_survey))
		end
		
		# debug message
		log "Parsed into: #{data.inspect}", :info
		log "Unparsed: #{@sur.unparsed.inspect}", :info\
			unless @sur.unparsed.empty?
		
		# split the UIDs back into gmc+child
		gmc_uid, child_uid = *data.delete(:uid)
		
		# fetch the gmc; abort if it wasn't valid
		unless gmc = Gmc.first(:uid => gmc_uid)
			return msg.respond(assemble(:invalid_gmc, [gmc_uid]))
		end
		
		# same for the child
		unless child = gmc.children.first(:uid => child_uid)
			return msg.respond(assemble(:invalid_child, [@sur[:uid].humanize]))
		end

		section_names = [" ", "Income sources: ", "Food available: ", "Food consumption patterns: ", "Shocks: ", "Changes in household: "] 

		# break up captured string into sections by *
		# (the strings leading space means that the first
		# section is blank, hence the blank element in
		# section_names above)
		sections = str.split("*") 

		# split each section string into an array by spaces
		answers =  sections.collect{|s| s.split}.flatten
		num_answers = answers.length
		
		s = child.surveys.create(
			:reporter => reporter,
			:date => msg.sent)
		
		# each question has 10 answers in the db,
		# (once bin/add_questions.rb is run)
		# so the answer's id can be computed by its
		# order and content. answer content + 1 times
		# answer position (aka question) + 1 gives us
		# the answers id. we have to add 1 because
		# arrays start with 0 while mysql starts with 1
		answers.each_with_index do |a,i| Entry.create(	
			:date => msg.sent,
			:answer => Answer.get(((i+1) * (a.to_i+1)))
		)end

		# counter as we return confirmation
		answer_num = 0

		# return one message per section confirming question number and answer pairs
		(1..5).each{|n| msg.respond assemble(section_names[n] + sections[n].split.collect{|s| "Q" + (answer_num = answer_num + 1).to_s + ". " + s } * ", ")}
	end


	serve /\A(?:cancel)(?:\s+(.+?)\s*)?(?=cancel|\Z)/i
	def cancel(msg, str)
		
		# parse the message, and reject
		# it if no tokens could be found
		unless data = @can.parse(str.to_s)
			return msg.respond(assemble(:oops, :help_cancel))
		end
		
		# debug message
		log "Parsed into: #{data.inspect}", :info
		log "Unparsed: #{@can.unparsed.inspect}", :info\
			unless @can.unparsed.empty?
		
		# split the UIDs back into gmc+child
		gmc_uid, child_uid = *data.delete(:uid)
		
		# fetch the gmc; abort if it wasn't valid
		unless gmc = Gmc.first(:uid => gmc_uid)
			return msg.respond(assemble(:invalid_gmc))
		end
		
		# same for the child
		unless child = gmc.children.first(:uid => child_uid)
			return msg.respond(assemble(:invalid_child))
		end

		# try to find the child's most recent report and destroy it
		if(report = child.reports.first(:order => [:date.desc]))

			# TODO 'on' and 'for' should be messages before this is i18n-ed
			latest = report.date.strftime("%I:%M%p on %m/%d/%Y for ")
			report.destroy
			return msg.respond(assemble(:canceled_report,"#{latest}", :canceled, [@can[:uid].humanize]))

		# otherwise destroy the child by setting
		# the :cancelled_at property - it's a
		# paranoid data/time, so datamapper will
		# pretend that the object doesn't exist
		else
			child.cancelled_at = Time.now
			child.save
			
			# confirm the cancellation
			return msg.respond(assemble(:canceled_new, :canceled, [@can[:uid].humanize]))
		end
	end
	
	
	serve /\A(died|dead|quit)(?:\s+(.+?)\s*)?(?=died|dead|quit|\Z)/i
	def remove_child(msg, type, str)
		
		reporter = identify(msg)	
		
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
			return msg.respond(assemble(:invalid_gmc))
		end
		
		# same for the child
		unless child = gmc.children.first(:uid => child_uid)
			return msg.respond(assemble(:invalid_child))
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
				:birthday=>sum[:age],
				:gender=>sum[:gender],
				:contact=>sum[:phone])
		
			# verify receipt of this replacment,
			# including all tokens that we parsed
			return msg.respond(assemble(:thanks_replace, [summarize(rep)]))
		end
		
		# no replacement, just thank for the removal
		return msg.respond(assemble(:thanks_remove, [@gon[:uid].humanize]))
	end
	
	
	serve /\Ahelp/i
	def help(msg)
		msg.respond(assemble(:help_new, "\n---\n", :help_report))
	end
	
	
	serve :anything
	def anything_else(msg, str)
		msg.respond(assemble(:dont_understand, [str]))
	end
end
