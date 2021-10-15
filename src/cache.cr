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
  def initialize
    # Cache for every course, containing a cache entry
    @cache = Hash(String, CacheEntry).new
    @mutex = Mutex.new
    # TODO launch scheduled update
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
end
