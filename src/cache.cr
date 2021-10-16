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
      if calendar != nil
        @cache[course] = CacheEntry.new(calendar.as(String))
      end
    end

    spawn scheduled_update
  end

  def get(course)
    result = nil

    @mutex.lock
    cache_entry = @cache[course]?
    @mutex.unlock

    if cache_entry == nil
      # Cache miss
      entry = icalendar(course, 2)
      if entry != nil
        @mutex.lock
        @cache[course] = CacheEntry.new(entry.as(String))
        @mutex.unlock
        result = entry
      end
    else
      result = cache_entry.as(CacheEntry).value
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
        @mutex.lock
        @cache.each_key do |course|
          calendar = icalendar(course)
          if calendar != nil
            @mutex.lock
            @cache[course] = CacheEntry.new(calendar.as(String))
            @mutex.unlock
          end
        end
        @mutex.unlock
      end

      sleep duration_3h
    end
  end
end
