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

require "./spec_helper"

describe "course_to_faculty" do
  it "can handle imaginary courses" do
    course_to_faculty("ABCD5").should eq(Faculty::EMI)
  end

  it "can handle INFM2" do
    course_to_faculty("INFM2").should eq(Faculty::EMI)
  end

  it "can handle AI4" do
    course_to_faculty("AI4").should eq(Faculty::EMI)
  end

  it "can handle AKI3" do
    course_to_faculty("AKI3").should eq(Faculty::EMI)
  end

  it "can handle MW-plus 3" do
    course_to_faculty("MW-plus 3").should eq(Faculty::M)
  end

  # If you think other courses matter, add tests here
end

describe "id_to_time" do
  it "works" do
    id_to_time(0, Faculty::EMI).should eq({8, 0})
  end
end
