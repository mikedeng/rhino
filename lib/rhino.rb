require "rack"
require "slop"
require "socket"
require "time"
require "uri"

require "rhino/cli"
require "rhino/http"
require "rhino/launcher"
require "rhino/logger"
require "rhino/server"
require "rhino/version"

module Rhino
  def self.logger
  	@logger ||= Rhino::Logger.new
  end
end
