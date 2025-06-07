require 'active_record'

# migrate the database

class CreateSchemas < ActiveRecord::Migration[7.1]
    def change
      create_table :repositories do |t|
      t.string :name
      t.string :link
      t.string :visibility
      t.boolean :archived
      t.timestamps
    end

    create_table :pull_requests do |t|
      t.integer :number
      t.string :title
      t.string :pr_updated_at
      t.string :pr_closed_at
      t.string :pr_merged_at
      t.string :author
      t.integer :additions
      t.integer :deletions
      t.integer :changed_files
      t.integer :num_of_commits
      t.references :repository, foreign_key: true
      t.timestamps
    end

    create_table :reviews do |t|
      t.string :author
      t.string :state
      t.string :submitted_at
      t.references :pull_request, foreign_key: true
      t.timestamps
    end
  end
end