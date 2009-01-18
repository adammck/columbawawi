class Report
	include DataMapper::Resource
	belongs_to :reporter
	belongs_to :child
	
	property :id, Integer, :serial=>true
	
	property :weight, Float 
	property :height, Float 
	property :muac, Float
	property :oedema, Boolean
	property :diarrhea, Boolean
	property :date, DateTime
	# TODO issue flag
	
	# Returns the weight to height ratio of
	# this report, or nil, if either fields
	# are missing.
	# TODO calculate this properly
	def ratio
		w = attribute_get(:weight)
		h = attribute_get(:height)
		(w && h) ? sprintf("%.2f", w/h).to_f : nil
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
