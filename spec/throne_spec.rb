require 'spec_helper'

describe Throne do
  it "should respond to server" do
    Throne.should respond_to :server
  end
  
  it "should respond to database" do
    Throne.should respond_to :database
  end
  
  it "should respond to server=" do
    Throne.should respond_to "server="
  end
  
  it "should respond to database=" do
    Throne.should respond_to "database="
  end
  
  it "should default the server to 127.0.0.1:5984" do
    Throne.server.should == "http://127.0.0.1:5984"
  end
  
  it "should set the server" do
    Throne.server = "http://127.0.0.1:5984"
    Throne.server.should == "http://127.0.0.1:5984"
  end

  it "should set the database" do
    Throne.database = "appname_environment"
    Throne.database.should == "appname_environment"
  end
  
  it "should respond to base_uri" do
    Throne.should respond_to :base_uri
  end
  
  it "should be a combination of the server and database strings" do
    Throne.base_uri.should == "http://127.0.0.1:5984/appname_environment"
  end 
  
  it "should raise an error without a database having been set" do
    Throne.database = nil
    lambda { Throne.base_uri }.should raise_error(Throne::Database::NameError)
  end
end