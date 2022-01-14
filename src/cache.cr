# Flatorte - A WebCal server for courses at the Offenburg University
# Copyright (C) 2021-2022 Hannes Braun
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

require "time"
require "./meta"

# This is a blatant copy of the TCoR caching mechanism (almost) ;)
# But it works, it fits and I like it

# A cache entry containing the value and the according timestamp
class CacheEntry
  getter value, timestamp

  def initialize(@value : String)
    @timestamp = Time.local
  end
end

class Cache
  def initialize(courses, @meta : FlatorteMeta)
    # Cache for every course, containing a cache entry
    @cache = Hash(String, CacheEntry).new
    @mutex = Mutex.new

    # Load initial courses
    courses.each do |course|
      calendar = icalendar(course, @meta)
      if !calendar.nil?
        @cache[course] = CacheEntry.new(calendar)
      end
    end

    spawn scheduled_update
  end

  # Returns the timetable for the given course
  #
  # In most cases, this is a cache entry. If the cache doesn't contain the timetable,
  # a request is going to be made to retrieve it. In that case, only the current and next week
  # will be available until the cache updates itself for the next time. Then, the full timetable
  # will be available.
  def get(course)
    result = nil

    begin
      @mutex.lock
      cache_entry = @cache[course]?
    ensure
      @mutex.unlock
    end

    if cache_entry.nil?
      # Cache miss
      # Only get the next two weeks for a fast response
      entry = icalendar(course, @meta, 2)
      if !entry.nil?
        begin
          @mutex.lock
          @cache[course] = CacheEntry.new(entry)
        ensure
          @mutex.unlock
        end
        result = entry
      end
    else
      # Cache hit
      result = cache_entry.value
    end

    result
  end

  # Calculates the initial delay for the first scheduled update
  private def calc_init_delay(period)
    current_time = Time.local.to_unix
    duration_1h = Time::Span.new(hours: 1).total_seconds
    duration_10m = Time::Span.new(minutes: 10).total_seconds
    (period - ((current_time + duration_1h) % period)) + duration_10m
  end

  def scheduled_update
    duration_3h = Time::Span.new(hours: 3).total_seconds
    init_delay_3h = calc_init_delay(duration_3h)

    sleep init_delay_3h

    loop do
      # Update each cache entry
      spawn do
        # Get list of courses
        courses_list = Array(String).new
        begin
          @mutex.lock
          @cache.each_key do |course|
            courses_list << course
          end
        ensure
          @mutex.unlock
        end

        # Get updated iCalendars
        courses_list.each do |course|
          calendar = icalendar(course, @meta)
          if !calendar.nil?
            begin
              @mutex.lock
              @cache[course] = CacheEntry.new(calendar)
            ensure
              @mutex.unlock
            end
          end
        end
      end

      # Schedule next update
      sleep duration_3h
    end
  end
end
