class Districts < Application
	
	before do
		@children = paginate(Child,  :page=>params[:cp], "gmc.district.id" => @district.id)
		@reports  = paginate(Report, :page=>params[:rp], "child.gmc.district.id" => @district.id, :order => [:date.desc])
	end
	
  def index
  	@crumbs << ["Latest Data"]
    render :template => "dashboard"
  end
end
