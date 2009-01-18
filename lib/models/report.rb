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
	# TODO issue flag
	
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
		return :severe if o==true

		a = self.child.attribute_get(:age)
		m = attribute_get(:muac)
		mal_muac = self.class.malnourished_by_muac?(m, a)

		h = attribute_get(:height)
		w = attribute_get(:weight)
		mal_ratio = self.class.malnourished_by_ratio?(h, w)
		
		if(mal_muac == :severe || mal_ratio == :severe)
			return :severe
		elsif(mal_muac == :moderate || mal_ratio == :moderate)
			return :moderate
		end
	end
	
	def self.insane_muac?(muac, age)
		return nil unless (age && muac)
		# TODO check that child is older than 6mo TODAY
		return :too_young unless age > 6 	# only check if older than 6mo
		return :too_small if muac > 6.0
		return false
	end

	def insane_muac?
		m = attribute_get(:muac)
		a = self.child.attribute_get(:age)
		self.class.insane_muac?(m, a)
	end

	def insane_height?
		# check for ridiculous height
		h = attribute_get(:height)
		return :too_tall if h > 100.0
		return :too_short if h < 10.0

		# check for wild changes in height since last time
		return nil if self.previous.nil?
		ph = self.previous.attribute_get(:height)
		return nil if ph.nil?
		return :gogogadget if ((ph -h ) < 0.0)
		return :shrinkage if ((ph - h) > 2.0)
		return false
	end

	def insane_weight?
		w = attribute_get(:weight)
		return :too_light if w < 2.0
		return :too_fat if w > 100.0

		# check for wild changes in weight since last time
		return nil if self.previous.nil?
		pw = self.previous.attribute_get(:weight)
		return nil if pw.nil?
		return :skinnier if ((pw - w) > 3.0)
		return :plumpier if ((pw - w) < -3.0)
		return false
	end

	def persistent_diarrhea?
		return nil if self.previous.nil?
		pd = self.previous.attribute_get(:diarrhea)
		return nil if pd.nil?
		d = attribute_get(:diarrhea)
		return nil if d.nil?
		return true if (pd && d)
		return false
	end

	def previous
		self.class.first(:order => [:id.desc], :id.lt => self.id)
	end

	# Returns _true_ if this report indicates a moderately malnourished
	# child. Note that _false_ is returned if we cannot tell (due to the
	# _ratio_ or _muac_ being nil), the child is severely malnourished,
	# or the child is not malnourished at all.
	def moderate?
		(!ratio.nil? and ratio > 0.70 and ratio < 0.79)\
		or (!muac.nil? and muac > 11.0 and muac < 11.9)
	end

	# Returns true if this report indicates a severely malnourished
	# child, or false if we cannot tell (due to _ratio_ or _muac_
	# being nil), or the child is not severely malnourished.
	def severe?
		(!ratio.nil? and ratio <= 0.70)\
		or (!muac.nil? and muac <= 11.0)\
		or (oedema)
	end
end
