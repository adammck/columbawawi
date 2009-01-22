#!/usr/bin/env ruby
# vim: noet


# import the ugly ratio lookup table,
# which we need to calculate whether
# reports indicate malnourishment
here = File.dirname(__FILE__)
require "#{here}/../ratios.rb"


class Report
	include DataMapper::Resource
	belongs_to :reporter
	belongs_to :child
	
	property :id, Integer, :serial=>true
	property :cancelled, Boolean
	
	property :weight, Float 
	property :height, Float 
	property :muac, Float
	property :oedema, Boolean
	property :diarrhea, Boolean
	property :date, DateTime
	
	
	
	# values shouldn't change too quickly
	HEIGHT_CHANGE = 3.0
	WEIGHT_CHANGE = 3.0
	
	# range of sane heights
	# for young children
	TOO_TALL = 100.0
	TOO_SHORT = 10.0

	# same for weights
	TOO_HEAVY = 100.0
	TOO_LIGHT = 5.0

	# and MUACs
	TOO_SMALL = 6.0
	TOO_BIG = 30.0




	# Given a height (in cm) and a weight (in kg), returns the
	# weight as a percentage of the average for children of this height.
	def self.ratio(height, weight)
	
		# abort if either of the
		# arguments are unknown
		return nil if height.nil? or weight.nil?
		
		# round the height and weight to the nearest 0.5 (in a bizarro fasion,
		# since Numeric#round only works to the nearest integer), since that is
		# the best fidelity of the lookup table from NCHS/CDD/WHO
		height = ((height * 2).round.to_f / 2)
		weight = ((weight * 2).round.to_f / 2)
		
		# find the average weight for this height, and
		# return the ratio of THIS WEIGHT to the average
		$ratios.each do |h, w|
			return((weight / w) * 100)\
				if height == h
		end
		
		# no return yet = unknown ratio
		# don't guess, just return nil
		return nil
	end
	
	
	# Given a height and (optionally) previous height, returns
	# a symbol indicating a problem with the value(s), nil if
	# we cannot be sure (due to lack of data), or false if
	# nothing seems to be wrong.
	def self.height_is_insane?(h, ph=nil)
		
		# check for ridiculous height
		return :too_tall if h > TOO_TALL 
		return :too_short if h < TOO_SHORT

		# can't check change limits if no
		# previous height report is available
		return nil if ph.nil?

		# check for wild changes in height since last time
		return :taller if ((ph - h) < -HEIGHT_CHANGE)
		return :shorter if ((ph - h) > HEIGHT_CHANGE)
		
		# nothing appears
		# to be wrong!
		false
	end


	# Same behaviour as _Report.height_is_insane?_
	# for values (current and previous) of _weight_.
	def self.weight_is_insane?(w, pw=nil)
		
		# check for ridiculous weights
		return :too_light if w < TOO_LIGHT
		return :too_heavy if w > TOO_HEAVY

		# can't check change limits if no
		# previous weight report is available
		return nil if pw.nil?

		# check for wild changes in weight since last time
		return :lighter if ((pw - w) > WEIGHT_CHANGE)
		return :heavier if ((pw - w) < -WEIGHT_CHANGE)
		
		# nothing appears
		# to be wrong!
		false
	end
	
	
	# Returns :moderate or :severe to indicate whether a child
	# appears to be malnourished, given their height (in cm)
	# and weight (in kg). Returns false if the child appears
	# to be healthy, or nil if we cannot be sure either way.
	def self.malnourished_by_ratio?(height, weight)
		r = ratio(height, weight)
		
		return nil       if r.nil? # unknown
		return false     if r > 80 # healthy
		return :moderate if r > 70 # moderate wasting
		return :severe             # severe wasting
	end
	
	
	# Returns :moderate or :severe to indicate whether a child
	# appears to be malnourished, given their middle-upper-arm-
	# circumference (MUAC) and age. Returns false if the child
	# appears healthy, or nil if we cannot be sure either way.
	def self.malnourished_by_muac?(muac, age)
		r = muac_is_insane?(muac, age)
		
		return nil       if r.nil?      # uknown
		return false     if muac > 11.9 # healthy
		return :moderate if muac > 11.0 # moderate wasting
		return :severe                  # severe wasting
	end
	
	
	# Returns a symbol indicating any problem with the given
	# MUAC and age, false if nothing is wrong, or nil if we
	# cannot know either way.
	def self.muac_is_insane?(muac, months_old)
		return nil unless (muac && months_old)

		# the MUAC check isn't applicable for
		# children younger than six months
		return :too_young unless months_old > 6 

		# check for ridiculous MUAC s
		return :too_small if muac < TOO_SMALL
		return :too_big   if muac > TOO_BIG
		
		# no problems
		return false
	end
	
	
	

	# Returns the report created previous to this
	# instane, by date, which was not cancelled
	def previous
		self.class.first(
			"child.id" => self.child.id,
			:order => [:date.desc],
			:date.lt => self.date,
			:cancelled => false)
	end
	


	
	# Returns the ratio of the child's weight to
	# the average weight for a child of this height
	def ratio
		h = attribute_get(:height)
		w = attribute_get(:weight)
		return nil unless (h && w)
		
		# get ratio, abort if nil, or
		# crop to two decimal places
		r = self.class.ratio(h, w)
		return nil if r.nil?
		sprintf("%.2f", r).to_f
	end	


	# Returns true if new report appears to be 
	# replacing the previous report
	def looks_like_amendment?
		
		# abort unless we have a previous report
		return nil unless previous && previous.date
		
		# allow a little longer to replace a report
		# if it looks like we're fixing insanity
		time_limit = (previous.insane?) ? 60 : 30
		(DateTime.now > (self.previous.date + time_limit))
	end
	
	


	# Returns true if this report
	# contains any kind of insanity.
	def insane?; not insanities.empty?; end

	# Returns and array of symbols, which may be empty,
	# containing any kinds of insanity reported by the
	# insane_*? methods of this instance.
	def insanities
		(methods.collect do |m|
			(m =~ /^insane_.+\?$/) && (symbol = send(m)) ? symbol : nil
		end).compact
	end
	
	
	# Return true if this report contains
	# any insanity or other red flags.
	def warnings?; not warnings.empty?; end
	
	# Returns the intersection of insanities, persistant
	# diarrhea and malnutrition, to list together (most
	# likely in the webui or other report)
	def warnings
		w = insanities
		
		w << :persistent_diarrhea\
			if persistent_diarrhea?
		
		m = malnourished?
		w << "#{m}_malnurition".to_sym\
			if m.is_a? Symbol
		
		w
	end
	
	


	# since H/W are almost identical, check
	# them both via the same private method
	def insane_height?; sanity_check(:height); end
	def insane_weight?; sanity_check(:weight); end
	
	
	# Returns a symbol (via _Report.muac_is_insane) indicating
	# what is wrong, if anything, with this report's MUAC, false
	# if it appears to be healthy, or nil if we cannot know.
	def insane_muac?
		
		# we can't check the muac without it
		# being reported, and knowing the child's
		# age (in months), so abort if any are missing.
		return nil if muac.nil? or self.child.nil?
		
		# calculate via the static method
		age_months = self.child.age_in_months
		self.class.muac_is_insane?(muac, age_months)
	end
	

	# Returns true if this report, and the previously
	# filed report, both indicate the child has diarrhea.
	def persistent_diarrhea?

		# abort (unknown) unless we have the
		# info on the last report's diarrhea
		return nil if previous.nil?
		pd = previous.diarrhea
		return nil if pd.nil?

		# diarrhea last time AND this
		# time makes for a shitty time
		(pd && diarrhea)
	end
	
	
	# Returns :severe or :moderate if this report appears
	# to indicate malnutrition, or false if it does not.
	def malnourished?
		mal = []
		
		# oedema always indicates
		# severe malnutrtion
		return :severe if oedema

		# check the MUAC for malnutrition,
		# if it (and the age) is available
		if muac && child
			mal.push(self.class.malnourished_by_muac?(
				muac, child.age_in_months))
		end
		
		# same for height/weight ratio,
		# if the fields are available
		if height && weight
			mal.push(self.class.malnourished_by_ratio?(
				height, weight))
		end
		
		# return the most severe
		# degree of malnutrtion
		[:severe, :moderate].each do |x|
			return x if mal.include?(x)
		end
		
		# nothing appears to be
		# wrong with this child
		false
	end


	
	
	private
	
	def sanity_check(sym)
		judge = self.class.method("#{sym}_is_insane?")
		
		# abort if no current value
		# is available for this report
		curr_val = self.send(sym)
		return nil if curr_val.nil?
		
		# if a prior report is available, then we
		# will compare its value to the updaated value
		if self.previous && (prev = self.previous.send(sym))

			# if previous value was insane; return unknown,
			# to suppress alerts from comparing a current
			# sane height to a previously insane value
			if judge.call(prev); nil
			
			# previous value was sane, so return the
			# classes judgement of this report's value
			else; judge.call(curr_val, prev); end
		
		# no prior report available; just
		# check this report for insanity
		else; judge.call(curr_val); end
	end
end
