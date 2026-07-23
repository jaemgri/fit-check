class AddNameToTryons < ActiveRecord::Migration[7.2]
  def change
    add_column :tryons, :name, :string
  end
end
