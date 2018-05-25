class LivestreamController < ApplicationController

  include ActionController::Live

  def index
        response.headers['Content-Type'] = 'text/event-stream'
    100.times {
      response.stream.write "hello world\n"
      sleep 1
    }
  ensure
    response.stream.close
  end

end
