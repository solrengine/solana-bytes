class ApplicationController < ActionController::Base
  include Solrengine::Auth::Concerns::ControllerHelpers
  allow_browser versions: :modern
end
