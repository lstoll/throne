require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Throne::Document do
  before :all do
    Throne.database = "throne-request-specs"
  end
  
  it "should raise an error without a database having been set" do
    Throne.database = nil
    lambda { Throne::Request.get }.should raise_error(Throne::Database::NameError)
    Throne.database = "throne-request-specs"
  end
  
  it "should make all requests asking for gzip and deflate" do
    RestClient.should_receive(:put).with("http://127.0.0.1:5984/throne-request-specs", "{}", { :accept_encoding  => "gzip, deflate" })
    Throne::Database.create
  end
  
  shared_examples_for "paramification" do    
    it "should be json encoded" do
      RestClient.should_receive(:get).with("http://127.0.0.1:5984/document?startkey=%5B%22abc%22%2C%22xyz%22%5D", {:accept_encoding=>"gzip, deflate"})
      Throne::Request.get :resource => "document", :params => {:startkey => ["abc", "xyz"]}
    end
    
    it "should uri escape each param value" do
      RestClient.should_receive(:get).with("http://127.0.0.1:5984/document?descending=true", {:accept_encoding=>"gzip, deflate"})
      Throne::Request.get :resource => "document", :params => {:descending => true}
    end
    
    it "should join using an &" do
      RestClient.should_receive(:get).with("http://127.0.0.1:5984/document?descending=true&limit=1", {:accept_encoding=>"gzip, deflate"})
      Throne::Request.get :resource => "document", :params => {:descending => true, :limit => 1}
    end
  end
  
  describe "get" do
    describe "expectations" do
      it_should_behave_like "paramification"
    end
    
    it "should get" do
      RestClient.should_receive(:get).with("http://127.0.0.1:5984/document", {:accept_encoding=>"gzip, deflate"})
      Throne::Request.get(:resource => "document").should be_an_instance_of(Hash)
    end
  end
  
  describe "delete" do
    describe "expectations" do
      it_should_behave_like "paramification"
    end
    
    it "should delete" do
      RestClient.should_receive(:delete).with("http://127.0.0.1:5984/document", {:accept_encoding=>"gzip, deflate"})
      Throne::Request.delete(:resource => "document").should be_an_instance_of(Hash)
    end
  end
  
  describe "put" do
    it "should put" do
      RestClient.should_receive(:put).with("http://127.0.0.1:5984/document", "{}", {:accept_encoding=>"gzip, deflate"})
      Throne::Request.put(:resource => "document").should be_an_instance_of(Hash)
    end
  end
  
  describe "post" do
    it "should post" do
      RestClient.should_receive(:post).with("http://127.0.0.1:5984/document", "{}", {:accept_encoding=>"gzip, deflate"})
      Throne::Request.post(:resource => "document").should be_an_instance_of(Hash)
    end
  end
end