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
	
	# a handy paginator, since our pagination needs are
	# minimal, and i don't feel like depending on yet
	# another gem. call it in any controller, like:
	#
	#   @items = paginate(Model, :page=>param[:page])
	#
	# then in the view,
	#
	#   <% for item in @items[:data] %>
	#     <li><%= item[:name] %></li>
	#   <% end %>
	#
	#   Page <%= @items[:this_page] %> of <%= @items[:page_count] %>
	#
	def paginate(model, options={})
		
		# if this method was called with 'nil', return a mock object. since templates
		# will expect the keys to be present in the output of this method, this is a
		# handy way to temporarily remove the data from a table without errors
		if model.nil?
			return({
				:this_page  =>1,
				:per_page   =>20,
				:page_count =>1,
				:data       =>[]
			})
		end
		
		this_page  = (options.delete(:page)     || 1).to_i
		per_page   = (options.delete(:per_page) || 20).to_i
		
		# make sure we're sorting to *something*, to make
		# sure the data doesn't come out in arbitrary order
		# (note that :id might not actually exist, but it's
		# a pretty sane default)
		unless options.has_key?(:order)
			options[:order] = [:id.desc]
		end
		
		# fetch the total number of models, to calculate
		# the number of pages we'll need to list them all
		page_count = (model.count(options).to_f / per_page).ceil
		
		# add the boundary options, leaving any other
		# options (conditions, orders, etc) intact
		options.merge!({
			:offset => (this_page-1) * per_page,
			:limit  => per_page
		})
		
		# return a whole bunch of data, to
		# be shunted straight into the view
		{ :this_page=>this_page, :per_page=>per_page, :page_count=>page_count, :data=>model.all(options) }
	end
  
  
  
  
  before do
  	
		@data_from = "all GMCs"
		
  	# initialize an array for actions to
  	# add items to the breadcrumb list
  	@crumbs = []
  	
  	# initialize a hash of the tabs which will be displayed on this page, which can be patched
  	# by individual actions (to update the title, url, or which one is active), but default to
  	# something sane without explictly doing it. we're using a hash here, rather than an array,
  	# so actions can patch by name. ie: @tabs[:gmc][:active] = true
  	@tabs = {
  		:national => { :title => "National", :href => "/",          :active => false, :order => 1 },
  		:district => { :title => "District", :href => "/districts", :active => false, :order => 2 },
  		:gmc      => { :title => "GMC",      :href => "/gmcs",      :active => false, :order => 3 },
  		:child    => { :title => "Child",    :href => "/children",  :active => false, :order => 4 },
  		:hsa      => { :title => "HSA",      :href => "/reporters", :active => false, :order => 5 },
  	}
  	
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
