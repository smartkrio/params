class CreateClients < ActiveRecord::Migration
  def self.up
    create_table :clients do |t|
      # <Read only params block>
      t.string :firstname
      t.string :lastname
      t.string :id_number
      t.integer :company_id
      t.date :birthdate
      t.integer :gender
      t.date :date_of_decease
      t.string :client_number
      t.string :prefixes
      t.string :home_number
      t.string :home_number_addition
      t.string :place
      t.string :postal_code
      t.string :marital_status
      t.string :email
      # </Read only params block>

      t.json :predefined, default: []
      t.json :extra, default: []

      t.timestamps null: false
    end
  end

  def self.down
    drop_table :clients
  end
end
