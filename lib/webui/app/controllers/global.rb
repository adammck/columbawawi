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
