class Application < Merb::Controller
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
  		@data_from = "all GMCs in #{@district.title} District"
	  	@crumbs << [@district.title, "/#{@district.slug}/"]
	  	
	  	# display the list of gmcs contained
	  	# by this district in the sidebar
  		@gmcs = @district.gmcs.all
  		
  		
  		# same for the nested
  		# "gmc" parameter
  		if params[:gmc]
  			
  			# load the gmc object and abort if invalid
  			@gmc = Gmc.first( :district_id => @district.id, :slug => params[:gmc])
  			raise NotFound if @gmc.nil?
  			
  			# update the data source again (i'm overwriting the same var all
  			# the time, but it's clearer than a bunch of nested if/else)
  			@data_from = "#{@gmc.title} GMC in #{@district.title} District"
  			@crumbs << [@gmc.title, "/#{@district.slug}/#{@gmc.title}/"]
  		end
		end
  end
end
