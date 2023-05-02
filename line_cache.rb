class LineCache
  FILE_KEY = 'line_cache_fileanme'

  class OutOfBoundsError < StandardError; end

  def initialize(redis_pool:)
    @redis_pool = redis_pool
  end

  def load(filepath:)
    t_start = Time.now
    self.filepath = filepath
    clear_db
    current_line_number = 0

    # After reading a few articles, this seems like the fastest reasonable method
    # for reading a file by line, without loading the whole file in memory.
    # Furhter optimizations can be made by using IO more direclty, by giving hints about
    # how you are accessing the file (sequentially) and providing a chunk size to read the file
    # that fits the page size of the system.
    # The main key here is that we are reading the file line by line once at boot, and not needing
    # to read the file on subsequent requests.

    File.foreach(filepath) do |line_text|
      current_line_number += 1

      redis_pool.with do |conn|
        # cache key is simply the line number at this time, see below
        conn.set(cache_key_for_line_in_file(current_line_number), line_text)
      end
    end

    puts "LineCache load complete file: #{filepath}, lines: #{current_line_number}, elaspsed: #{Time.now - t_start}"
  end

  def read(line_number:)
    value = redis_pool.with do |conn|
      conn.get(cache_key_for_line_in_file(line_number))
    end

    if value.nil?
      # Not exposing file name or max number of lines. It would be more user friendly,
      # but I'd want to check with product before leaking that data!
      raise OutOfBoundsError, "#{line_number} is out of bounds for current file"
    end

    value
  end

  private

  attr_reader :redis_pool
  attr_accessor :filepath

  def clear_db
    # Assuming that a new file is passed on each run.
    # this could be changed to clear the cache by wildcard, with namespaced keys,
    # if we wanted to preserve other files in cache
    redis_pool.flushdb
  end

  # this trivial method makes it easy to upgrade to support multiple
  # files in the redis db at once
  def cache_key_for_line_in_file(line_number)
    line_number
  end
end
