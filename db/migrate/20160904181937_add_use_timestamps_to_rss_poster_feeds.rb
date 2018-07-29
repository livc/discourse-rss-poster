class AddUseTimestampsToRssPosterFeeds < ActiveRecord::Migration[4.2]
  def change
    add_column :rss_poster_feeds, :use_timestamps, :boolean
  end
end
