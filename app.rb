require 'rubygems'
require 'bundler'

Bundler.require

require 'sinatra'
require 'redis'
require 'representable'
require 'rack/conneg'
require 'faker'

configure do
  Redis.current = Redis.new(url: ENV['REDIS_URL'])

  set :server, :puma
  set :bind, '0.0.0.0'
end

use(Rack::Conneg) do |conneg|
  conneg.set :accept_all_extensions, false
  conneg.set :fallback, :json
  conneg.provide([:json])
end

before do
  content_type negotiated_type if negotiated?
end

class DataStore
  class << self
    def find id
      result = redis.hmget(key(id), 'shortcode', 'url', 'redirect_count', 'start_date', 'last_seen_date')
      OpenStruct.new(
        shortcode: result[0],
        url: result[1],
        redirect_count: result[2],
        start_date: result[3],
        last_seen_date: result[4]
      )
    end

    def increment model, counter
      redis.hincrby(key(model.shortcode), counter, 1)
    end

    def save model, *attributes
      redis.hmset(
        key(model.shortcode),
        attributes
      )
    end

    private

      def redis
        @redis ||= Redis.current
      end

      def key id
        "DataStore:#{id}"
      end
  end
end

class Shortlink
  attr_accessor :shortcode,
                :url,
                :redirect_count,
                :start_date,
                :last_seen_date

  def initialize shortcode
    @shortcode = shortcode
  end

  def self.find shortcode
    data = DataStore.find(shortcode)
    build_shortlink(data)
  end

  def create
    DataStore.save(
      self,
      'shortcode', self.shortcode,
      'url', self.url,
      'redirect_count', self.redirect_count,
      'start_date', self.start_date,
      'last_seen_date', self.last_seen_date
    )
  end

  def update
    DataStore.save(
      self,
      'shortcode', self.shortcode,
      'url', self.url,
      'start_date', self.start_date,
      'last_seen_date', self.last_seen_date
    )
  end

  def increment
    DataStore.increment(self, 'redirect_count')
    data = DataStore.find(shortcode)
    self.redirect_count = data.redirect_count
  end

  private

    def self.build_shortlink data
      return nil unless data.shortcode
      shortlink = Shortlink.new(data.shortcode)
      shortlink.url = data.url
      shortlink.redirect_count = data.redirect_count
      shortlink.start_date = data.start_date
      shortlink.last_seen_date = data.last_seen_date
      shortlink
    end
end

class CreateShortlink
  attr_reader :params

  def initialize params
    @params = params
  end

  def call
    shortcode = params.fetch(:shortcode, random_shortcode)
    shortlink = Shortlink.new(shortcode)
    shortlink.url = params.fetch(:url)
    shortlink.redirect_count = 0
    shortlink.start_date = Time.now.iso8601
    shortlink.create
    shortlink
  end

  private

    def random_shortcode
      pattern = /[0-9a-zA-Z_]{6}/
      shortcode = Faker::Base.regexify(pattern)
      return shortcode if Shortlink.find(shortcode).nil?
      random_shortcode(pattern)
    end
end

class UpdateShortlink
  attr_reader :shortlink

  def initialize shortlink
    @shortlink = shortlink
  end

  def call
    shortlink.increment
    shortlink.last_seen_date = Time.now.iso8601
    shortlink.update
    shortlink
  end
end

class ShortlinkStatsRepresenter < Representable::Decorator
  include Representable::JSON

  property :start_date
  property :last_seen_date
  property :redirect_count
end

post '/shorten' do
  # Validade params
  if params[:url].nil? || params[:url].empty?
    halt 400, 'url is not present'
  end

  unless params[:shortcode].to_s.empty?
    shortlink = Shortlink.find(params[:shortcode])
    halt 409, 'The the desired shortcode is already in use' unless shortlink.nil?
    unless /^[0-9a-zA-Z_]{4,}$/.match?(params[:shortcode])
      halt 422, 'The shortcode fails to meet the following regexp: ^[0-9a-zA-Z_]{4,}$'
    end
  end

  # Create shortlink
  shortlink = CreateShortlink.new(params).call
  [201, { shortcode: shortlink.shortcode }.to_json]
end

get '/:shortcode' do
  shortlink = Shortlink.find(params[:shortcode])
  halt 404, 'The shortcode cannot be found in the system' if shortlink.nil?
  shortlink = UpdateShortlink.new(shortlink).call
  redirect to(shortlink.url), 303
end

get '/:shortcode/stats' do
  shortlink = Shortlink.find(params[:shortcode])
  halt 404, 'The shortcode cannot be found in the system' if shortlink.nil?
  response = ShortlinkStatsRepresenter.new(shortlink).to_json
  [200, response]
end
