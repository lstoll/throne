require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Smeg2::Database do
  before :all do
    @dburl =  'http://localhost:5984/smeg2_test'
    begin
      RestClient.delete(@dburl)
    rescue
    end
    @db = Smeg2::Database.new(@dburl)
  end

  describe "creating/deleting databases" do
    it "should be able to force delete/create a database" do
      @db.create!
      lambda {RestClient.get(@dburl)}.
        should_not raise_error(RestClient::ResourceNotFound)
    end

    it "should be able to delete a database" do
      @db.create!
      @db.delete!
      lambda {RestClient.get(@dburl)}.
        should raise_error(RestClient::ResourceNotFound)
    end

    it "should be able to create a database" do
      @db.delete!
      @db.create
      lambda {RestClient.get(@dburl)}.
        should_not raise_error(RestClient::ResourceNotFound)
    end

    it "should not error when creating a database that exists" do
      @db.delete!
      @db.create
      lambda {@db.create}.
        should_not raise_error(Exception)
    end
  end

  it "should be able to get a doc by it's ID"
  it "should be able to post a new doc"
  it "should be able to update an existing doc"
  it "should be able to get a view"
end
