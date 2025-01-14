class CreateCoupons < ActiveRecord::Migration[7.1]
  def change
    create_table :coupons do |t|
      t.string :serial_code

      t.timestamps
    end
  end
end
