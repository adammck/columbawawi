class Messages < Application
	before do
    @page_title = "Raw Messages"
	end
	
	def index
    @raw_messages = RawMessage.roots
		@data_from = "all Reporters"
    render :template => "messages"
	end
	
	def reporter(backend, phone)
		
		# there is no canonical source of valid backends (the
		# field is a string), so check for the existance of
		# the reporter by their backend string and phone
		@reporter = Reporter.first(:backend => backend, :phone => phone)
		raise NotFound unless @reporter
		
		@raw_messages = []#RawMessage.all("reporter.id" => @reporter.id)
		@data_from = "#{@reporter.summary} via the #{backend} Backend"
    render :template => "messages"
	end
end
