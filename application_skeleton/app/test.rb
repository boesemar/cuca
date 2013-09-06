

class TestController < ApplicationController

def get
  @_content = 'GET: '
  @_content << query_parameters.inspect
end

def post
  @_content = "POST: "
  @_content << request_parameters.inspect
end

end

