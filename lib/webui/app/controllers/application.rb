class Application < Merb::Controller
  
  # any route can point to this action in any controller
  # (since it's inherited), and provide custom excel
  # reports by providing a: #{params[:report]}_xls
  # method which returns a two-dimensional array
  def excel
  	str = "#{params[:report]}_xls"
  	raise NotFound unless respond_to?(str)
  	
  	# fetch the data
  	data = method(str).call
  	
  	# rejig the data grid into an html
  	# table, to be interpreted by excel
  	html =\
  	"<table>" + (data.collect do |row|
  		"<tr>" + (row.collect do |cell, n|
  			"<td>#{cell}</td>"
  		end).join("") + "</tr>"
  	end).join("") + "</table>"
  	
  	render html, :format => :xls
  end
  
  protected
  
  before do
  	
  	# initialize an array for actions to
  	# add items to the breadcrumb list
		@data_from = "all GMCs"
  	@crumbs = []
  	
		# every page displays a list of districts
		@districts = District.all(:order => [:title.asc])
		
		
		# pages with a "district" parameter also
		# display a list of the contained gmcs
		if params[:district]
			
			# load the district, abort if it was invalid
  		@district = District.first(:slug => params[:district])
	  	raise NotFound if @district.nil?
	  	
	  	# update the data source (for labels) and breadcrumbs
  		@data_from = "#{@district.title} District"
	  	@crumbs << [@district.title, "/#{@district.slug}/"]
	  	
	  	# display the list of gmcs contained
	  	# by this district in the sidebar
  		@gmcs = @district.gmcs.all
  		
  		
  		# same for the nested
  		# "gmc" parameter
  		if params[:gmc]
  			
  			# load the gmc object and abort if invalid
  			@gmc = Gmc.first(:district_id => @district.id, :slug => params[:gmc])
  			raise NotFound if @gmc.nil?
  			
  			# update the data source again (i'm overwriting the same var all
  			# the time, but it's clearer than a bunch of nested if/else)
  			@data_from = "#{@gmc.title} GMC in #{@data_from}"
  			@crumbs << [@gmc.title, "/#{@district.slug}/#{@gmc.slug}/"]
  			
  			
  			# the highest reporting fidelity
  			# is children (for now...)
  			if params[:child]
  				
  				# load the child or abort
  				@child = Child.first(:gmc_id => @gmc.id, :uid => params[:child])
  				raise NotFound if @child.nil?
  				
  				# update view data AGAIN
  				@data_from = "Child# #{@child.uid} at #{@data_from}"
  				@crumbs << ["Child# #{@child.uid}", "/#{@district.slug}/#{@gmc.slug}/#{@child.uid}"]
  			end
  		end
		end
  end
end
