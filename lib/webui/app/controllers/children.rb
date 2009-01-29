class Children < Application
	before do
		@reports  = Report.all("child.id" => @child.id, :order => [:date.desc])
	end

	def index
		@crumbs << ["Latest Data"]
		render :template => "dashboard"
	end
end
