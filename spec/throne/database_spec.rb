require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Throne::Database do
  describe "with nothing set" do
    it "should raise an error" do
      lambda { Throne::Database.create }.should raise_error(Throne::Database::NameError)
    end
  end
  
  describe "with a database set" do
    before :all do
      @db_name = "throne-database-set"
      Throne.database = @db_name
      
      begin
        Throne::Database.delete
      rescue RestClient::ResourceNotFound
      end
    end
    
    it "should create the database" do
      Throne::Database.create
      lambda { RestClient.get("http://127.0.0.1:5948/#{@db_name}") }.should_not raise_error(RestClient::ResourceNotFound)
    end
    
    it "should destroy the database" do
      Throne::Database.create
      Throne::Database.delete
      lambda { Throne::Database.delete }.should raise_error(RestClient::ResourceNotFound)
    end
    
    it "should not error when creating a database that exists" do
      Throne::Database.create
      lambda { Throne::Database.create }.should_not raise_error
    end
  end
end
