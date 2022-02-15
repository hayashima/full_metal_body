# frozen_string_literal: true

class CreateBlockedActions < ActiveRecord::Migration[7.0]

  def change
    create_table :blocked_actions do |t|
      t.string :controller, null: false
      t.string :action, null: false

      t.timestamps
    end
    add_index :blocked_actions, [:controller, :action], unique: true

    create_table :blocked_keys do |t|
      t.references :blocked_action, foreign_key: true, null: false
      t.string :blocked_key, array: true, null: false

      t.timestamps
    end
    add_index :blocked_keys, [:blocked_action_id, :blocked_key], unique: true
  end
end
