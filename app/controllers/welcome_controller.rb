class WelcomeController < ApplicationController

  layout "origen"
  def index
  @application ||= Application.all
  end
end
