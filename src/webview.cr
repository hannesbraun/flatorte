require "uri"
require "./tcor"

class WebView
  @courses : Array(String)

  def initialize
    @courses = begin
      courseList
    rescue
      Array(String).new
    end
  end

  ECR.def_to_s "src/webview.ecr"
end
