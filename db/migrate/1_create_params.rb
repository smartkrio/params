class CreateParams < ActiveRecord::Migration
  def self.up
    create_table :params do |t|
      t.integer :company_id, default: 1
      t.string :name, null: false
      t.json :data, null: false
      t.string :env_only

      t.timestamps null: false
    end

    add_index :params, :name, unique: true
  end

  def self.down
    drop_table :params
  end
end
