class Districts < Application
	
	before do
		@children = Child.all("gmc.district.id" => @district.id, :order => [:id.desc])
		@reports  = Report.all("child.gmc.district.id" => @district.id, :order => [:date.desc])
	end
	
  def index
  	@crumbs << ["Latest Data"]
    render :template => "dashboard"
  end
end
