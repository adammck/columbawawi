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


  # Returns a rendered graph (using the Gruff gem), ready to be returned
  # as a PNG. Accepts a _title_, which is rendered as part of the image,
  # an array of _places_, which can be anything that has a #reports and
  # a #title method, but will usually be Districts or Gmcs), and the same
  # _meth_ and _value_ arguments as #percentage, which are passed on verbatim.
  def summarize_graph(title, places, meth, value=nil)
  	width = params[:width] || 400
		g = Gruff::Line.new(width.to_i)
		
		# all graphs start on jan 1st of THIS YEAR.
		# obviously this will need to be updated one day
		start_date = DateTime.new(Date.today.year, 1, 1)
		
		# a hash of all months, to be used to fetch
		# reports for each month, and label the x-axis
		months = {
			0 => "Jan", 1  => "Feb",  2 => "Mar",
			3 => "Apr", 4  => "May",  5 => "Jun",
			6 => "Jul", 7  => "Aug",  8 => "Sep",
			9 => "Oct", 10 => "Nov", 11 => "Dec" }
		
		# theme copied roughly from ray's webui
		# mockups in "WebUI Template.pdf"
		g.theme = {
			:colors => ["#416fa6", "#a8423f", "#86a44a", "#6e548d", "#3d96ae", "#da8137"],
			:background_colors => "#fff",
			:marker_color => "#eee" }

		# iterate places (anything that has a #reports
		# method, (like District, Gmc), and #title)
		places.each do |place|
			data = []
			
			# iterate months (x-axis)
			months.keys.sort.each do |offset|
				
				# fetch all reports for this place in this
				# month. this will trigger an ugly SQL query
				# (and this will be hit (places.length * 12)
				# times), so is rather heavy...
				# 
				#   TODO: cache the results of this. there is almost
				#   no value in instantly updating the graph every time
				reports = place.reports({
					:date.gte => (start_date >> offset),
					:date.lte => (start_date >> (offset+1))
				})
				
				# get the percentage of reports during this month
				# that _meth_ equals _value_ (or is non-false, if
				# _value_ is nil); convert to float unless _perc_
				# is nil, to avoid useless dots on the baseline (0)
				perc = percentage(reports, meth, value)
				perc = perc.to_f unless perc.nil?
				data.push(perc)
			end
			
			# add the data for this place to
			# the graph, as a separate series
			g.data(place.title, data)
		end
		
		# more theming from mockups
		g.minimum_value = 0
		g.maximum_value = 10
		g.labels = months
		g.title = title
		
		g
  end
  
  # Returns an array of summarys for each of _places_,
  # (which can be anything that has #reports, but will
  # probably be an array of District, GMC, or Child),
  # to be rendered as a pivot-ish table.
  def summarize_reports(places, range)
    stats = {}
    
    places.each do |place|
    	reports = place.reports(range)
    	
    	stats[place.title] = {
    		:mod_mal  => percentage(reports, :malnourished?, :moderate),
    		:sev_mal  => percentage(reports, :malnourished?, :severe),
    		:oedema   => percentage(reports, :oedema),
    		:diarrhea => percentage(reports, :diarrhea)
    	}
    end
    
    stats
  end
  
	# Returns the percentage of _reports_ for which the method
	# named _meth_ returns true, or if _value_ is provided, the
	# percentage which returns it. If _reports_ is an empty array
	# (indicating that there are no relevant reports, for whatever
	# reason), returns nil.
	def percentage(reports, meth, value=nil)
		return nil if\
			reports.empty?
		
		n = 0
		reports.each do |report|
			v = report.send(meth)
			n += 1 if (value.nil? && v) || (value==v)
		end
	
		# calculate the percentage of reports for which
		# report.send(_meth_) was true, and crop it to
		# two decimal places. this belongs in the view :|
		ratio = n.to_f / reports.length
		sprintf("%0.2f", ratio * 100)
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
  			
  			# display the list of children
  			# for this gmc in the sidebar
  			@the_children = @gmc.children.all
  			
  			
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
		
#		now = DateTime.now
#		fmt = "%Y-%m-%d"
#		
#		if params.has_key?(:from)
#			from = DateTime.strptime(params[:from], fmt)	
#				
#			if params.has_key?(:to)
#				to = DateTime.strptime(params[:to], fmt)
#			else
#				
#			end
#			@range = { :from => from }
#			
#		else
#			@range = {
#				:from => (DateTime.now - 30),
#				:to   => (DateTime.now + 1),
#				:desc => "Last 30 days"
#			}
#		end
#	
#		if @range[:to] > now
#			n = (now - @range[:from]).to_i
#			@range[:desc] = "Last #{n} days"
#		
#		else
#			
#		end
  end
end
