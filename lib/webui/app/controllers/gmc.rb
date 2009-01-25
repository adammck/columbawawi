class Gmcs < Application
	
	before do
		@children = Child.all("gmc.id" => @gmc.id, :order => [:id.desc])
		@reports  = Report.all("child.gmc.id" => @gmc.id, :order => [:date.desc])
	end
	
  def index
  	@crumbs << ["Latest Data"]
    render :template => "dashboard"
  end
end
