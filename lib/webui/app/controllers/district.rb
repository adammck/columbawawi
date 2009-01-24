class Districts < Application
	
	before do
		fetch_district
		@gmcs      = Gmc.all("district.id" => @district.id, :order => [:id.desc])
		@reports   = Report.all("child.gmc.district.id" => @district.id, :order => [:date.desc])
		@children  = Child.all("gmc.district.id" => @district.id, :order => [:id.desc])
		@data_from = "all GMCs in #{@district.title} District"
	end
	
  def index
  	@crumbs << [@district.title, "/#{@district.slug}/"]
  	@crumbs << ["Dashboard"]
    render :template => "dashboard"
  end
end
