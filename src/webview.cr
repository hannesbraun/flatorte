require "uri"
require "./tcor"

class WebView
  @courses : Array(String)

  def initialize
    @courses = courseList
  end

  ECR.def_to_s "src/webview.ecr"
end
