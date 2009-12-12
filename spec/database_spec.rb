require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Smeg2::Database do
  before :all do
    @dburl =  'http://localhost:5984/smeg2_test'
    begin
      RestClient.delete(@dburl)
    rescue
    end
    @db = Smeg2::Database.new(@dburl)
    # some kind of fixtures loading?
  end

  describe "creating/deleting databases" do
    it "should be able to delete a database" do
      @db.create_database
      @db.delete_database
      lambda {RestClient.get(@dburl)}.
        should raise_error(RestClient::ResourceNotFound)
    end

    it "should be able to create a database" do
      @db.delete_database
      @db.create_database
      lambda {RestClient.get(@dburl)}.
        should_not raise_error(RestClient::ResourceNotFound)
    end

    it "should not error when creating a database that exists" do
      @db.delete_database
      @db.create_database
      lambda {@db.create_database}.
        should_not raise_error(Exception)
    end

    it "shoudld automatically create the database" do
      @db.delete_database
      @db = Smeg2::Database.new(@dburl)
      lambda {RestClient.get(@dburl)}.
        should_not raise_error(RestClient::ResourceNotFound)
    end
  end

  describe "working with documents" do
    before :all do
      @db = Smeg2::Database.new(@dburl)
    end

    it "should return a valid ID when creating" do
      id = @db.save(:testfield => 'true')
      id.should_not be_empty
      lambda {RestClient.get(@dburl + '/' + id)}.
        should_not raise_error(Exception)
    end

    it "should be able to get a doc by it's ID" do
      id = @db.save(:testfield => 'true')
      doc = @db.get(id)
      doc.should_not be_nil
      doc['testfield'].should_not be_nil
    end

    it "should be able to update an existing doc" do
      id =  @db.save(:testfield => 'true')
      doc = @db.get(id)
      doc['testerfield'] = 'false'
      @db.save(doc)
      @db.get(id)['testerfield'].should eql('false')
    end

    it "should be able to delete a document when given a document" do
      id = @db.save(:testfield => 'true')
      doc = @db.get(id)
      @db.delete(doc)
      lambda {@db.get(id)}.
        should raise_error(RestClient::ResourceNotFound)
    end

    it "should be able to delete a document when given a document id" do
      id = @db.save(:testfield => 'true')
      @db.delete(id)
      lambda {@db.get(id)}.
        should raise_error(RestClient::ResourceNotFound)
    end
  end

  it "should be able to get a view"
end
