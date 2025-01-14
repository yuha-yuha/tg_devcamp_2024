class Impression < ApplicationRecord
  validates :user_id, uniqueness: { scope: :product_id } 
end
