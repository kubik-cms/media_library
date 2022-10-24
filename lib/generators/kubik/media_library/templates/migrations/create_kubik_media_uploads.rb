class CreateKubikMediaUploads < ActiveRecord::Migration[5.1]
  def change
    create_table :kubik_media_uploads do |t|
      t.jsonb  :image_data, null: false, default: {}
      t.jsonb  :file_data, null: false, default: {}
      t.jsonb :additional_info, null: false, default: { 'alt_text': '' }
      t.string :aasm_state

      t.timestamps
    end
    add_index  :kubik_media_uploads, :image_data, using: :gin
    add_index  :kubik_media_uploads, :file_data, using: :gin
    add_index  :kubik_media_uploads, :additional_info, using: :gin
  end
end
