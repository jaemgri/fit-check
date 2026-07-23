class AddFavoriteToTryons < ActiveRecord::Migration[7.2]
  def change
    add_column :tryons, :favorite, :boolean, default: false, null: false
  end
end
