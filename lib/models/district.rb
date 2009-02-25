#!/usr/bin/env ruby
# vim: noet

class District
	include DataMapper::Resource
	has n, :gmcs
	
	property :id, Integer, :serial=>true
	property :slug, String, :length=>60
	property :title, String, :length=>60
	
	# Returns all of the Reports which belong to Children
	# which belong to GMCs which belong to this District,
	# along with any additional filters provided. The
	# existence of this method demonstrates the severity
	# of the our need for arbitrarily-nested locations.
	def reports(opts={})
		Report.all({ "child.gmc.district.id" => id }.merge(opts))
	end
end
