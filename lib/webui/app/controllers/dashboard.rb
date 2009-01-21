class Dashboard < Application
	
  def index
    @reports = Report.all(:order => [:date.desc], :cancelled=>[true, false])
    @children = Child.all
    render :index
  end
  
  def district
  	fetch_district
  	
  	@reports = Report.all("child.gmc.district.id" => @district.id)
  	render :index
  end
  
  def gmc
  	fetch_district
  	fetch_gmc
  	
  	@reports = Report.all("child.gmc.id" => @gmc.id)
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
