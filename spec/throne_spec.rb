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
  
  it "should default the server to localhost:5984" do
    Throne.server.should == "http://localhost:5984"
  end
  
  it "should set the server" do
    Throne.server = "http://localhost:5984"
    Throne.server.should == "http://localhost:5984"
  end
  
  it "should set the database" do
    Throne.database = "appname_environment"
    Throne.database.should == "appname_environment"
  end
end