require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a child exists" do
  Child.all.destroy!
  request(resource(:children), :method => "POST", 
    :params => { :child => { :id => nil }})
end

describe "resource(:children)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:children))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of children" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a child exists" do
    before(:each) do
      @response = request(resource(:children))
    end
    
    it "has a list of children" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      Child.all.destroy!
      @response = request(resource(:children), :method => "POST", 
        :params => { :child => { :id => nil }})
    end
    
    it "redirects to resource(:children)" do
      @response.should redirect_to(resource(Child.first), :message => {:notice => "child was successfully created"})
    end
    
  end
end

describe "resource(@child)" do 
  describe "a successful DELETE", :given => "a child exists" do
     before(:each) do
       @response = request(resource(Child.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:children))
     end

   end
end

describe "resource(:children, :new)" do
  before(:each) do
    @response = request(resource(:children, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@child, :edit)", :given => "a child exists" do
  before(:each) do
    @response = request(resource(Child.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@child)", :given => "a child exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(Child.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @child = Child.first
      @response = request(resource(@child), :method => "PUT", 
        :params => { :child => {:id => @child.id} })
    end
  
    it "redirect to the article show action" do
      @response.should redirect_to(resource(@child))
    end
  end
  
end

