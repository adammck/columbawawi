require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a reporter exists" do
  Reporter.all.destroy!
  request(resource(:reporters), :method => "POST", 
    :params => { :reporter => { :id => nil }})
end

describe "resource(:reporters)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:reporters))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of reporters" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a reporter exists" do
    before(:each) do
      @response = request(resource(:reporters))
    end
    
    it "has a list of reporters" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      Reporter.all.destroy!
      @response = request(resource(:reporters), :method => "POST", 
        :params => { :reporter => { :id => nil }})
    end
    
    it "redirects to resource(:reporters)" do
      @response.should redirect_to(resource(Reporter.first), :message => {:notice => "reporter was successfully created"})
    end
    
  end
end

describe "resource(@reporter)" do 
  describe "a successful DELETE", :given => "a reporter exists" do
     before(:each) do
       @response = request(resource(Reporter.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:reporters))
     end

   end
end

describe "resource(:reporters, :new)" do
  before(:each) do
    @response = request(resource(:reporters, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@reporter, :edit)", :given => "a reporter exists" do
  before(:each) do
    @response = request(resource(Reporter.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@reporter)", :given => "a reporter exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(Reporter.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @reporter = Reporter.first
      @response = request(resource(@reporter), :method => "PUT", 
        :params => { :reporter => {:id => @reporter.id} })
    end
  
    it "redirect to the article show action" do
      @response.should redirect_to(resource(@reporter))
    end
  end
  
end

