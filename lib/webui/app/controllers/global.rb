class Globals < Application
	
	before do
		#@districts = District.all(:order => [:title.asc])
		@reports   = Report.all(:order => [:date.desc])
		@children  = Child.all(:order => [:id.desc])
		#@gmcs      = Gmc.all(:order => [:id.desc])
		@data_from = "all GMCs"
	end
	
  def index
  	@crumbs << ["Latest Data"]
    render :template => "dashboard"
  end
  
  def all_gmc
  	render Gmc.all.to_a.to_json, :format => :json
  end
  
  def map
  	render :template => "map"
  end
end
