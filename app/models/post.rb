class Post < ApplicationRecord
  extend Enumerize
  before_save :store_regex
  has_many :products, dependent: :destroy
  belongs_to :user
  accepts_nested_attributes_for :products, allow_destroy: true

  enumerize :convenience_store_type, in: [:familly_mart, :seven_eleven ]

  validates :store_name, presence: true

  private 
    def store_regex
      r = /(?:セブンイレブン|ファミリーマート|seveneleven|fammilymart)?(.+?)(?:店)?$/
      match = self.store_name.match(r)
      self.store_name = match[1].strip
    end
end
