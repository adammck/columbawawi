class GmcApp < Application
	provides :json
	
  def index
    @data_from = "all GMCs"
    @reports = Report.all(:order => [:date.desc])
    @children = Child.all(:order => [:id.desc])
    render :index
  end
  
  def district
  	fetch_district
  	
  	@data_from = "all GMCs in #{@district.title} District"
  	@reports = Report.all("child.gmc.district.id" => @district.id)
  	@children = Child.all("gmc.district.id" => @district.id)
  	render :index
  end
  
  def gmc
  	fetch_district
  	fetch_gmc
  	
  	@data_from = "#{@gmc.title} GMC in #{@district.title} District"
  	@reports = Report.all("child.gmc.id" => @gmc.id)
  	@children = Child.all("gmc.id" => @gmc.id)
  	
  	render :index
  end
end
