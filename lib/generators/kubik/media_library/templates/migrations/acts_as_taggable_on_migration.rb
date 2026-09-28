class ActsAsTaggableOnMigration < ActiveRecord::Migration[7.0]
  def change
    create_table :tags do |t|
      t.string :name
      t.integer :taggings_count, default: 0
      t.timestamps
    end

    create_table :taggings do |t|
      t.references :tag, foreign_key: true
      t.references :taggable, polymorphic: true
      t.references :tagger, polymorphic: true
      t.string :context, limit: 128
      t.datetime :created_at
      t.string :tenant, limit: 128
    end

    add_index :taggings, %i[taggable_id taggable_type context], name: "taggings_taggable_context_idx"
    add_index :tags, :name, unique: true
  end
end
