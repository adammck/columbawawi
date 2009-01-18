class Child
	include DataMapper::Resource
	belongs_to :reporter
	belongs_to :gmc
	has n, :reports
	
	property :id, Integer, :serial=>true
	property :uid, String, :key=>true, :format=>/^\d{2}$/, :messages => {
		:format => "Child ID must be exactly two digits" }
	
	property :age, DateTime
	property :gender, Enum[:male, :female]
	property :contact, String, :length=>22
end
