class Gmcs < Application
	
	before do
		fetch_district
		fetch_gmc
		
		@reports   = Report.all("child.gmc.id" => @gmc.id, :order => [:date.desc])
		@children  = Child.all("gmc.id" => @gmc.id, :order => [:id.desc])
  	@data_from = "#{@gmc.title} GMC in #{@district.title} District"
	end
	
  def index
  	@crumbs << [@district.title, "/#{@district.slug}/"]
  	@crumbs << [@gmc.title, "/#{@district.slug}/#{@gmc.slug}/"]
  	@crumbs << ["Dashboard"]
    render :template => "dashboard"
  end
end
