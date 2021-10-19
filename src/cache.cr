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

require "time"

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
  def initialize(courses)
    # Cache for every course, containing a cache entry
    @cache = Hash(String, CacheEntry).new
    @mutex = Mutex.new

    # Load initial courses
    courses.each do |course|
      calendar = icalendar(course)
      if !calendar.nil?
        @cache[course] = CacheEntry.new(calendar)
      end
    end

    spawn scheduled_update
  end

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
      entry = icalendar(course, 2)
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
      result = cache_entry.value
    end

    result
  end

  private def calc_init_delay(period)
    current_time = Time.local.to_unix
    duration_1h = Time::Span.new(hours: 1).total_seconds
    duration_1m = Time::Span.new(minutes: 1).total_seconds
    (period - ((current_time + duration_1h) % period)) + duration_1m
  end

  def scheduled_update
    duration_3h = Time::Span.new(hours: 3).total_seconds
    init_delay_3h = calc_init_delay(duration_3h)

    sleep init_delay_3h

    loop do
      # Update each cache entry
      spawn do
        begin
          @mutex.lock
          @cache.each_key do |course|
            calendar = icalendar(course)
            if !calendar.nil?
              begin
                @mutex.lock
                @cache[course] = CacheEntry.new(calendar)
              ensure
                @mutex.unlock
              end
            end
          end
        ensure
          @mutex.unlock
        end
      end

      sleep duration_3h
    end
  end
end
