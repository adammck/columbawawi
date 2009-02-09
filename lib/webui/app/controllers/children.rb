class Children < Application
	before do
		@reports  = paginate(Report, :page=>params[:rp], "child.id" => @child.id, :order => [:date.desc])
	end

	def index
		@crumbs << ["Latest Data"]
		render :template => "dashboard"
	end
end
