class AddFailuresToRssPosterFeeds < ActiveRecord::Migration[4.2]
  def change
    add_column :rss_poster_feeds, :failures, :integer
    add_column :rss_poster_feeds, :exceptions, :text
  end
end
