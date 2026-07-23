class CreateTryons < ActiveRecord::Migration[7.2]
  def change
    create_table :tryons do |t|
      t.string :status, default: "pending"
      t.text :error_message

      t.timestamps
    end
  end
end
