class CreateImpressions < ActiveRecord::Migration[7.1]
  def change
    create_table :impressions do |t|
      t.references :product, foreign_key: true
      t.references :user, foreign_key: true
      t.integer :post_user_id

      t.timestamps
    end

    add_index :impressions,  [:user_id, :product_id], unique: true
  end
end
