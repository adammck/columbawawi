class Districts < Application
	
	before do
		@children = paginate(Child,  :page=>params[:cp], "gmc.district.id" => @district.id)
		@reports  = paginate(Report, :page=>params[:rp], "child.gmc.district.id" => @district.id, :order => [:date.desc])
	end
	
  def index
  	@crumbs << ["Latest Data"]
    @tabs[:district][:active] = true
    
    # fetch all reports for the last 30 days to build stats
    range = {:date.gte => (DateTime.now - 30)}
    @stats = summarize_reports(@gmcs, range)
    
    render :template => "dashboard"
  end
end
