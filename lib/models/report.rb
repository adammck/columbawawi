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
	
	def self.malnourished?(height, weight)
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
	
	# TODO: document this complicated process
	
	def malnourished?
		h = attribute_get(:height)
		w = attribute_get(:weight)
		return nil unless (h && w)
		self.class.malnourished?(h, w)
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
