require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

class TestDocument < Throne::Document
  # property :field
end

describe Throne::Document do
  before :all do
    Throne.database = "throne-document-specs"
    Throne::Database.create
  end

  describe "crud" do
    describe "with class methods" do
      before :all do
        @doc = TestDocument.create(:field => true)
      end
      
      it "should dispatch correctly" do
        RestClient.should_receive(:post).with("http://127.0.0.1:5984/throne-document-specs/", "{\"field\":false}", {:accept_encoding=>"gzip, deflate"})
        TestDocument.create(:field => false)
      end
      
      it "should create a document" do
        @doc.should be_an_instance_of(TestDocument)
        lambda { RestClient.get([Throne.server, Throne.database, @doc.id].join('/')) }.should_not raise_error
      end

      it "should get a document" do
        TestDocument.get(@doc.id).should == @doc
      end
      
      it "should get a revision of a document" do
        TestDocument.get(@doc.id).should == @doc
      end

      it "should delete a document" do
        doc = TestDocument.create(:field => true)
        TestDocument.delete(doc.id).should be_true
        lambda { TestDocument.get(doc.id) }.should raise_error(Throne::Document::NotFound)
      end      
    end
    
    describe "with instance methods" do
      before :each do
        @doc = TestDocument.create(:field => true)
      end
      
      it "should save the document" do
        @doc.save.should be_an_instance_of(TestDocument)
      end

      it "should delete the document" do
        @doc.delete.should be_true
        lambda { TestDocument.get(@doc.id) }.should raise_error(Throne::Document::NotFound)
      end
    end
  end
  
  describe "instance" do
    before :each do
      @doc = TestDocument.create(:field => true)
    end
    
    it "should be a new_document" do
      TestDocument.new(:field => true).new_record?.should be_true
    end
    
    it "should not be a new_document" do
      TestDocument.create(:field => true).new_record?.should be_false
    end
    
    it "should have an _id" do
      @doc._id.should == @doc[:_id]
    end
    
    it "should have a _rev" do
      @doc._rev.should_not be_nil
    end
      
    it "should have a type" do
      @doc.type.should == "TestDocument"
    end
    
    it "should not have 'ok'" do
      @doc.should_not have_key(:ok)
    end
    
    it "should be able to update an existing document" do
      @doc.field = false
      @doc.save
      @doc.reload!
      @doc.field.should be_false
    end
    
    describe "comparison" do
      it "should be the same" do
        @doc.should == @doc
      end
      
      it "should not be the same" do
        @doc.should_not == TestDocument.create(:field => true)
      end
    end
  end
  
  describe "permalinking" do
    it "id and permalink should be the same"
    it "should save to the permalink url"
  end
 
  describe "Design Access" do
    it "should be able to call a design with parameters"
  end
    
    
  it "should save when created called"
  it "should tag its class when saved"
  describe "View Access" do
    it "should be able to query a view"
  end
end
