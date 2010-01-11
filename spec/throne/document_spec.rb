require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Throne::Document do
  before :all do
    Throne.database = "throne-document-specs"
    Throne::Database.create
  end

  describe "crud" do
    describe "with class methods" do
      before :all do
        @doc = Throne::Document.create(:field => true)
      end
      
      it "should create a document" do
        @doc.should be_an_instance_of(Throne::Document)
        lambda { RestClient.get(URI.join(Throne.base_uri, @doc.id)) }.should_not raise_error
      end

      it "should get a document" do
        Throne::Document.get(@doc.id).should == @doc
      end
      
      it "should get a revision of a document" do
        Throne::Document.get(@doc.id).should == @doc
      end

      it "should delete a document" do
        doc = Throne::Document.create(:field => true)
        Throne::Document.delete(doc.id).should be_true
        lambda { Throne::Document.get(doc.id) }.should raise_error(Throne::Document::NotFound)
      end      
    end
    
    describe "with instance methods" do
      before :each do
        @doc = Throne::Document.new(:field => true)
      end
      
      it "should save the document" do
        @doc.save.should be_an_instance_of(Throne::Document)
      end

      it "should delete the document" do
        @doc.delete.should be_true
        lambda { Throne::Document.get(@doc.id) }.should raise_error(Throne::Document::NotFound)
      end
    end
  end
  
  describe "instance" do
    before :each do
      @doc = Throne::Document.create(:field => true)
    end
    
    it "should be a new_document" do
      Throne::Document.new(:field => true).should be_new_document
    end
    
    it "should not be a new_document" do
      Throne::Document.create(:field => true).should_not be_new_document
    end
    
    it "should have an id" do
      @doc.id.should_not be_nil
    end
    
    it "should have an _id" do
      @doc._id.should_not be_nil
    end
    
    it "id and _id should be the same" do
      @doc.id.should == @doc._id
    end
    
    it "should have a revision" do
      @doc.revision.should_not be_nil
    end
    
    it "should have a _rev" do
      @doc._rev.should_not be_nil
    end
    
    it "revision and _rev should be the same" do
      @doc.revision.should == @doc._rev
    end
    
    it "should be able to update an existing document" do
      @doc.field = false
      @doc.save
      @doc.reload!
      @doc.field.should be_false
    end
    
    %w(id _id revision _rev).each do |m|
      it "should not allow changes to #{m}" do
        lambda { doc.send("#{m}=", "abc") }.should raise_error(Throne::Document::ImmutableProperty)
      end
    end
    
    describe "comparison" do
      it "should be the same" do
        @doc.should == @doc
      end
      
      it "should not be the same" do
        @doc.should != Throne::Document.create(:field => true)
      end
    end
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
