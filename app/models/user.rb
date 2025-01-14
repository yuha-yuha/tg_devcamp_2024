class User < ApplicationRecord
  has_many :posts
  has_many :impressions
  validates :line_user_id, presence: true, uniqueness: true
end
