class CreateProducts < ActiveRecord::Migration[7.1]
  def change
    create_table :products do |t|
      t.string :content
      t.string :name
      t.references :post, foreign_key: true
      t.timestamps
    end
  end
end
