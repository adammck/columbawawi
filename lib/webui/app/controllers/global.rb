class Global < Application
	
	before do
		@children = paginate(nil)#Child,  :page=>params[:cp])
		@reports  = paginate(nil)#Report, :page=>params[:rp], :order=>[:date.desc])
	end
	
  def index
  	@crumbs << ["Latest Data"]
    @tabs[:national][:active] = true
    
    # fetch all reports for the last 30 days to build stats
    range = {:date.gte => (DateTime.now - 30)}
#    @stats = {}
    
#    @districts.each do |district|
#    	reports = district.reports(range)
#    	
#    	@stats[district.id] = {
#    		:mod_mal  => percentage(reports, :malnourished?, :moderate),
#    		:sev_mal  => percentage(reports, :malnourished?, :severe),
#    		:oedema   => percentage(reports, :oedema),
#    		:diarrhea => percentage(reports, :diarrhea)
#    	}
#    end
    
    render :template => "dashboard"
  end
  
  
  
  
  
  
  
  def children
  	@crumbs << ["Children"]
  	render :template => "children"
  end
  
  protected
  
  def reports_xls
  	[["Reporter", "Received", "District", "GMC", "Child#", "Age (months)", "Gender", "Weight (kg)", "Height (cm)", "MUAC (cm)", "Oedema?", "Diarrhea?"]] +\
  	Report.all(:order => [:date.desc]).collect do |report|
  		[report.reporter.detail, report.date, report.child.gmc.district.title, report.child.gmc.title, report.child.uid, report.child.age_in_months, report.child.gender, report.weight, report.height, report.muac, report.oedema, report.diarrhea]
  	end
  end
  
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
  
	# Returns the percentage of _reports_ for which the method
	# named _meth_ returns true, or if _value_ is provided, the
	# percentage which returns it. If _reports_ is an empty array
	# (indicating that there are no relevant reports, for whatever
	# reason), returns nil.
	def percentage(reports, meth, value=nil)
		return nil if\
			reports.empty?
		
		n = 0
		reports.each do |report|
			v = report.send(meth)
			n += 1 if (value.nil? && v) || (value==v)
		end
	
		# calculate the percentage of reports for which
		# report.send(_meth_) was true, and crop it to
		# two decimal places. this belongs in the view :|
		ratio = n.to_f / reports.length
		sprintf("%0.2f", ratio * 100)
	end
end
