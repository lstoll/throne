require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Throne::Document do
  before :all do
    Throne.database = "throne-request-specs"
  end
  
  it "should make all requests asking for gzip and deflate" do
    RestClient.should_receive(:put).with("http://127.0.0.1:5984/throne-request-specs", {}, { :accept_encoding  => "gzip, deflate" })
    Throne::Database.create
  end
  
  describe "get"  
  describe "delete"  
  describe "put"
  describe "post"
end