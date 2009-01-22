class Application < Merb::Controller
  protected
  
  def fetch_district
  	@district = District.first(:slug => params[:district])
  	raise NotFound if @district.nil?    
  end
  
  def fetch_gmc
  	@gmc = Gmc.first(:district_id => @district.id, :slug => params[:gmc])
  	raise NotFound if @gmc.nil?
  end
end
