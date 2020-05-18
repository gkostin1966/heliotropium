class CreateMarcRecords < ActiveRecord::Migration[5.2]
  def self.up
    create_table :marc_records do |t|
      t.string :filename, null: false, unique: true
      t.datetime :updated, null: false, default: Time.new(1970, 1, 1)

      t.boolean :selected, null: false, default: false
      t.boolean :parsed, null: false, default: false
      t.integer :count, null: false, default: 0
      t.boolean :replaced, null: false, default: false
      t.binary :content
      t.binary :raw
      t.binary :mrc
      t.string :doi, unique: true

      t.timestamps
    end
  end

  def self.down
    drop_table :marc_records
  end
end
