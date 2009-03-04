class Global < Application
	
	before do
		@children = paginate(Child,  :page=>params[:cp])
		@reports  = paginate(Report, :page=>params[:rp], :order=>[:date.desc])
	end
	
  def index
  	@crumbs << ["Latest Data"]
    @tabs[:national][:active] = true
    
    # fetch all reports for the last 30 days to build stats
    range = {:date.gte => (DateTime.now - 30)}
    @stats = summarize_reports(@districts, range)
    
    render :template => "dashboard"
  end
  
  def sev_mal_graph
  	graph = summarize_graph("% Severe Malnutrition", @districts, :malnourished?, :severe)
  	render graph.to_blob, :format => :png
  end
  
  def mod_mal_graph
  	graph = summarize_graph("% Moderate Malnutrition", @districts, :malnourished?, :moderate)
  	render graph.to_blob, :format => :png
  end
  
  def oedema_graph
  	graph = summarize_graph("% Oedema", @districts, :oedema)
  	render graph.to_blob, :format => :png
  end
  
  def diarrhea_graph
  	graph = summarize_graph("% Diarrhea", @districts, :diarrhea)
  	render graph.to_blob, :format => :png
  end
  
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
  
  def gmcs
  	@all_gmcs = Gmc.all
  	render :template => "gmcs"
  end
  
  def children
  	@crumbs << ["Children"]
  	render :template => "children"
  end
  
  protected
  
  def reports_xls
  	[["Reporter", "Received", "District", "GMC", "Child#", "Age (months)", "Gender", "Weight (kg)", "Height (cm)", "MUAC (cm)", "Oedema?", "Diarrhea?"]] +\
  	Report.all(:order => [:date.desc]).collect do |report|
  		[report.reporter.detail, report.date, report.child.gmc.district.title, report.child.gmc.title, report.child.uid, report.child.age_in_months, report.child.gender, report.weight, report.height, report.muac, report.oedema, report.diarrhea]
  	end
  end
  
  def children_xls
  	[["District", "GMC", "Child#", "Age (months)", "Gender", "Contact"]] +\
  	@children.collect do |child|
  		[child.gmc.district.title, child.gmc.title, child.uid, child.age_in_months, child.gender, child.contact]
  	end
  end
  
  def all_gmc
  	render Gmc.all.to_a.to_json, :format => :json
  end
  
  def map
  	render :template => "map"
  end
end
