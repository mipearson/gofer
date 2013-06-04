require "rspec"
require "gofer"

require File.expand_path("../support/integration_helpers", __FILE__)

RSpec.configure do |config|
  config.include IntegrationHelpers
end
