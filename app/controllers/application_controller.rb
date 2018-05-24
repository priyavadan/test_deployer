class ApplicationController < ActionController::Base
  layout "origen"
  @application ||= Application.all
end
