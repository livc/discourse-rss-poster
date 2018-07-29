class CreateFeeds < ActiveRecord::Migration[4.2]
  def change
    create_table :rss_poster_feeds do |t|
      t.string :url, null: false
      t.integer :interval, null: false
      t.belongs_to :category, index: true
      t.belongs_to :user, index: true, null: false
      t.timestamps
    end
  end
end
