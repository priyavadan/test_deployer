class CreateApplications < ActiveRecord::Migration[5.2]
  def change
    create_table :applications do |t|
      t.string :name
      t.string :url
      t.string :revcontrol

      t.timestamps
    end
  end
end
