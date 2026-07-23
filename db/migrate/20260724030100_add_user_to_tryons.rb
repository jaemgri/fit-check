class AddUserToTryons < ActiveRecord::Migration[7.2]
  def change
    add_reference :tryons, :user, foreign_key: true
  end
end
