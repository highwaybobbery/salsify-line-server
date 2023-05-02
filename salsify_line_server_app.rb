require 'sinatra'
require 'redis'
require 'connection_pool'

require './line_cache'


class SalsifyLineServer < Sinatra::Base

  def initialize
    super
    # Using a connection pool here should keep sinatra from opening new connections for each request.
    # The pool size should be configured externally. size option will have a large impact on performace.
    #
    # Note: This initialize method isn't called until the first request comes in, so for very large files you would
    # want to "warm" the server by hitting an arbitrary page after launch. Sinatra doesn't seem to have a good mechanic for this
    # out of the box.

    @redis_pool = ConnectionPool::Wrapper.new(size: 5, timeout: 3) { Redis.new }
    @line_cache = LineCache.new(redis_pool: @redis_pool)
    @line_cache.load(filepath: ENV['SALSIFY_LINE_SERVER_FILE'])
  end

  get /\/(\d+)/ do
    @line_cache.read(line_number: params['captures'].first)
  rescue LineCache::OutOfBoundsError => e
    status 413
    body e.message
  end
end
