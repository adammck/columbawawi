#!/usr/bin/env ruby
# vim: noet


# import rspec
require "rubygems"
require "spec"

# import the application
here = File.dirname(__FILE__)
require "#{here}/../lib/app/columbawawi.rb"


# re-configure the database to our own, and
# auto migrate it to clear existing data
db_dir = File.expand_path(File.dirname(__FILE__) + "/../db")
DataMapper.setup(:default, "sqlite3:///#{db_dir}/test.db")
DataMapper.auto_migrate!




# add a simple test facility to all applications,
# which accepts an incoming message, and returns
# the first outgoing message triggered by it
class SMS::App
	def self.test(text, sender=1234)
		caught = catch(:sent_sms) do
			self.new.incoming(
				SMS::Incoming.new(
					nil, sender, Time.now, text))
			return nil
		end
	end
end

# disable screen logging
module SMS
	def self.log(*args)
		nil
	end
end

# monkeypatch the outgoing sms handler,
# to prevent messages from really being
# sent. instead, throw them to be caught
# by the App.test method, above
class SMS::Outgoing
	def send!
		throw :sent_sms, text
	end
end




describe Columbawawi do
	it "rejects junk data" do
		[
			# a bunch of junk data, which should
			# all be responded to in the same way
			"blah blah blah",
			"what is this",
			"wheeeee"
		].each do |junk|
			Columbawawi.test(junk).should == "Sorry, I don't understand."
		end
	end
	
	describe "(registration)" do
		it "accepts the cheat-sheet example" do
			Columbawawi.test("new 1234 70 M 21 09555123").should =~ /thank you for registering/i
			
			# check that the Child
			# object was created
			c = Child.get("123470")
			c.gender.should == :male
			c.contact.should == "09555123"
			
			# age might be a few days off, but it
			# should be at least year/month accurate!
			x21_months_ago = Chronic.parse("21 months ago")
			c.age.year == x21_months_ago.year
			c.age.month == x21_months_ago.month
		end
	end
	
	describe "(reporting)" do
		it "accepts the cheat-sheet example" do
			Columbawawi.test("report 1234 70 35.1 25.4 6.5 N N").should =~ /thank you for reporting/i
			
			# check that the Report
			# object was created
			r = Report.first(:uid => "123470")
			r.weight.should == 35.1
			r.height.should == 25.4
			r.muac.should == 6.5
			r.oedema.should == false
			r.diarrhea.should == false
		end
	end
end
