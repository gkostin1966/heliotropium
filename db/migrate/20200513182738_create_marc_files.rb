class CreateMarcFiles < ActiveRecord::Migration[5.2]
  def self.up
    create_table :marc_files do |t|
      t.string :filename, null: false, unique: true
      t.string :checksum

      t.timestamps
    end
  end

  def self.down
    drop_table :marc_files
  end
end
