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
	property :cancelled, ParanoidBoolean
	
	property :weight, Float 
	property :height, Float 
	property :muac, Float
	property :oedema, Boolean
	property :diarrhea, Boolean
	property :date, DateTime
	
	# insanity check thresholds
	HEIGHT_CHANGE = 3.0
	TOO_TALL = 100.0
	TOO_SHORT = 10.0

	WEIGHT_CHANGE = 3.0
	TOO_HEAVY = 100.0
	TOO_LIGHT = 5.0

	TOO_SMALL = 6.0
	TOO_BIG = 30.0

	def self.ratio(height, weight)
		
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
	

	def self.malnourished_by_ratio?(height, weight)
		r = ratio(height, weight)
		
		return nil       if r.nil? # unknown
		return false     if r > 80 # healthy
		return :moderate if r > 70 # moderate wasting
		return :severe             # severe wasting
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
	

	def self.malnourished_by_muac?(muac, age)
		return nil if self.insane_muac?(muac, age)
		return false if muac > 11.9 	# healthy
		return :moderate if muac > 11.0 
		return :severe
	end


	# TODO: document this complicated process
	def malnourished?
		# if there is oedema, return severe
		o = attribute_get(:oedema)
		return :severe if o == true

		# analyze muac
		a = self.child.age_in_months
		m = attribute_get(:muac)
		mal_muac = self.class.malnourished_by_muac?(m, a) unless m.nil?

		# analyze ratio
		h = attribute_get(:height)
		w = attribute_get(:weight)
		mal_ratio = self.class.malnourished_by_ratio?(h, w)
		
		# return the most serious level of malnutrition
		if(mal_muac == :severe || mal_ratio == :severe)
			return :severe
		elsif(mal_muac == :moderate || mal_ratio == :moderate)
			return :moderate
		end
		return false
	end


	# Returns true if new report appears to be 
	# replacing the previous report
	def ammend?
		return nil unless self.previous
		# TODO six hours is 21600
		# TODO thirty seconds for development
		if ((Time.now <=> (self.previous.date + 30)) == -1)
			return true 
		end
		# be greedy if we may be replacing insanity
		if((Time.now <=> (self.previous.date + 60)) == -1)
			return true if self.previous.insane?
		end
		return false
	end


	def insane?
		# return true if there is anything left after
		# throwing away falses and nils
		sane = insanities.delete_if{|i| i == false}.empty? 
		return true unless sane 
	end


	def insanities
		return [insane_muac?, insane_height?, insane_weight?].compact
	end


	def self.insane_muac?(muac, age)
		return nil unless (age && muac)

		# only check if older than 6mo
		return :too_young unless age > 6 

		# check for ridiculous MUAC 
		return :too_small if muac < TOO_SMALL
		return :too_big if muac > TOO_BIG
		return false
	end


	def insane_muac?
		m = attribute_get(:muac)
		a = self.child.age_in_months
		self.class.insane_muac?(m, a)
	end


	def self.insane_height?(h, ph=nil)
		# check for ridiculous height
		return :too_tall if h > TOO_TALL 
		return :too_short if h < TOO_SHORT

		# can't tell if no height last time
		return nil if ph.nil?

		# check for wild changes in height since last time
		return :taller if ((ph - h) < -HEIGHT_CHANGE)
		return :shorter if ((ph - h) > HEIGHT_CHANGE)
		return false
	end


	def insane_height?
		# check this report's sanity if there is no prior
		height = attribute_get(:height)
		self.class.insane_height?(height) unless self.previous

		# check and compare this report unless prior report is insane
		# (to suppress issue alerts if sane values 
		# are being compared to insane values)
		previous_height = self.previous.attribute_get(:height)
		self.class.insane_height?(height, previous_height)\
			unless self.previous.class.insane_height?(previous_height)
	end


	def self.insane_weight?(w, pw=nil)
		# check for ridiculous weight
		return :too_light if w < TOO_LIGHT
		return :too_heavy if w > TOO_HEAVY

		# can't tell if no weight last time
		return nil if pw.nil?

		# check for wild changes in weight since last time
		return :lighter if ((pw - w) > WEIGHT_CHANGE)
		return :heavier if ((pw - w) < -WEIGHT_CHANGE)
		return false
	end


	def insane_weight?
		# check this report's sanity if there is no prior
		weight = attribute_get(:weight)
		self.class.insane_weight?(weight) unless self.previous

		# check and compare this report unless prior report is insane
		# (to suppress issue alerts if sane values 
		# are being compared to insane values)
		previous_weight = self.previous.attribute_get(:weight)
		self.class.insane_weight?(weight, previous_weight)\
			unless self.previous.class.insane_weight?(previous_weight)
	end


	def persistent_diarrhea?

		# give up if nil last time
		return nil if self.previous.nil?
		pd = self.previous.attribute_get(:diarrhea)
		return nil if pd.nil?

		# give up if nil this time
		d = attribute_get(:diarrhea)
		return nil if d.nil?

		# return true if shitty both
		# this month and last 
		return true if (pd && d)
		return false
	end


	def previous
		# return report's child's previous noncanceled report
		self.class.first('child.id' => self.child.id, :order => [:date.desc],\
				:date.lt => self.date, :cancelled => false)
	end

end
