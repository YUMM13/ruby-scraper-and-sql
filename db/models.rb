require_relative 'db_setup'
require 'active_record'

# define our database models
# has_many tells ActiveRecord that this table can have many of that item (each repository can have many pull request)
# belongs_to tells ActiveRecord that this item is a foreign key (each review belongs to one pull request)

class Repository < ActiveRecord::Base
  has_many :pull_requests, dependent: :destroy
end

class PullRequest < ActiveRecord::Base
  has_many :reviews, dependent: :destroy
  belongs_to :repository
end

class Review < ActiveRecord::Base
  belongs_to :pull_request
end