class Dashboard < Application
	
  def index
    @data_from = "all GMCs"
    @reports = Report.all(:order => [:date.desc], :cancelled=>[true, false])
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
  
  private
  
  def fetch_district
  	@district = District.first(:slug => params[:district])
  	raise NotFound if @district.nil?    
  end
  
  def fetch_gmc
  	@gmc = Gmc.first(:district_id => @district.id, :slug => params[:gmc])
  	raise NotFound if @gmc.nil?
  end
end
