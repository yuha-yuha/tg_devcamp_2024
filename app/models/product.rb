class Product < ApplicationRecord
  belongs_to :post
  has_many :impressions

  validates :content , presence: true
  validates :name, presence: true
  
  
end
