class CreateLoans < ActiveRecord::Migration[7.0]
  def change
    create_table :loans do |t|
      t.integer :status, default: 0
      t.references :user, null: false, foreign_key: true
      t.float :amount, null: false
      t.integer :term, null: false
      t.datetime :approved_at
      t.datetime :paid_at

      t.timestamps
    end
  end
end
