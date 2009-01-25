class Globals < Application
	
	before do
		@children = Child.all(:order => [:id.desc])
		@reports  = Report.all(:order => [:date.desc])
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
