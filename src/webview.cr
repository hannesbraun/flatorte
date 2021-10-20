# Flatorte - A WebCal server for courses at the Offenburg University
# Copyright (C) 2021 Hannes Braun
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <https://www.gnu.org/licenses/>.

require "uri"
require "./meta"
require "./tcor"

class WebView
  @courses : Array(String)

  def initialize(@meta : FlatorteMeta)
    @courses = begin
      courseList
    rescue
      Array(String).new
    end
  end

  ECR.def_to_s "src/webview.ecr"
end
