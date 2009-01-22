class GlobalApp < Application
	
	before do
		@data_from = "all GMCs"
		@districts = District.all(:order => [:title.asc])
		@reports = Report.all(:order => [:date.desc])
		@children = Child.all(:order => [:id.desc])
		@gmcs     = Gmc.all(:order => [:id.desc])
	end
	
  def index
    render :template => "dashboard"
  end
  
  def all_gmc
  	render Gmc.all.to_a.to_json, :format => :json
  end
  
  def map
  	render :template => "map"
  end
end
