class Gmcs < Application
	
	before do
		@children = paginate(Child,  :page=>params[:cp], "gmc.id" => @gmc.id)
		@reports  = paginate(Report, :page=>params[:rp], "child.gmc.id" => @gmc.id, :order => [:date.desc])
	end
	
  def index
  	@crumbs << ["Latest Data"]
    render :template => "dashboard"
  end
end
