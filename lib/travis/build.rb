require 'dm-core'

module Travis
  class Build
    include DataMapper::Resource
    property :id,         Serial
    property :runner,     String
    property :commit,     String
    property :status,     Boolean
    property :output,     Text
    property :created_at, DateTime
  end
end