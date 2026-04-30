ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

# Stub Solrengine::Rpc::Client.new globally so tests never hit the real network.
# Tests that need fake RPC data register a response with:
#     RpcStubRegistry.responses["<address>"] = { "result" => { "value" => {...} } }
# Setup hooks reset the registry between tests so state does not leak.
module RpcStubRegistry
  class << self
    attr_accessor :responses
  end
  self.responses = {}

  def self.reset!
    self.responses = {}
  end
end

class StubRpcClient
  def initialize(*) end

  def request(method, params)
    return nil unless method == "getAccountInfo"
    address = params.is_a?(Array) ? params.first : nil
    RpcStubRegistry.responses[address]
  end
end

Solrengine::Rpc::Client.singleton_class.send(:define_method, :new) do |*args, **kwargs|
  StubRpcClient.new(*args, **kwargs)
end

class ActiveSupport::TestCase
  # Run tests in parallel with specified workers
  parallelize(workers: :number_of_processors)

  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  setup { RpcStubRegistry.reset! }
end
