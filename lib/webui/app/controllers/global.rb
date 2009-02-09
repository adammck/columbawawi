class Globals < Application
	
	before do
		@children = paginate(Child,  :page=>params[:cp])
		@reports  = paginate(Report, :page=>params[:rp], :order=>[:date.desc])
	end
	
	
	
  def index
  	@crumbs << ["Latest Data"]
    render :template => "dashboard"
  end
  
  protected
  
  def children_xls
  	[["District", "GMC", "Child#", "Age (months)", "Gender", "Contact"]] +\
  	@children.collect do |child|
  		[child.gmc.district.title, child.gmc.title, child.uid, child.age_in_months, child.gender, child.contact]
  	end
  end
  
  
  
  
  
  
  
  
  
  
  
  
  
  def all_gmc
  	render Gmc.all.to_a.to_json, :format => :json
  end
  
  def map
  	render :template => "map"
  end
end
