class CreateKbartFiles < ActiveRecord::Migration[5.2]
  def self.up
    create_table :kbart_files do |t|
      t.string :filename, null: false, unique: true
      t.date :updated, null: false, default: Time.new(1970, 1, 1)

      t.timestamps
    end
  end

  def self.down
    drop_table :kbart_files
  end
end
