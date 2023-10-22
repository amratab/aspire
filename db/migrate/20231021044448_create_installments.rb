class CreateInstallments < ActiveRecord::Migration[7.0]
  def change
    create_table :installments do |t|
      t.datetime :paid_at
      t.datetime :due_date, null: false
      t.float :amount_due, null: false
      t.float :amount_paid, default: 0
      t.integer :status, default: 0
      t.references :loan, null: false, foreign_key: true

      t.timestamps
    end
  end
end
