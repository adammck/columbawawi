class Messages < Application
	def index
    @raw_messages = RawMessage.roots
    render :index
	end
end
