require 'open-uri'
require 'simple-rss'

module Jobs
  class RssPosterPoll < Jobs::Base

    sidekiq_options retry: false

    def execute(args)
      id = args[:feed_id]

      feed = RssPoster::Feed.find(id)
      feed.last_run = Time.now
      feed.status = 'running'
      feed.save!

      begin
        rss = SimpleRSS.parse open(feed.url, allow_redirections: :all)

        rss.items.each do |item|
          url = TopicEmbed.normalize_url(item.link)
          content = item.content.try(:force_encoding, 'UTF-8').try(:scrub) || item.description.try(:force_encoding, 'UTF-8').try(:scrub)
          title = item.title.force_encoding('UTF-8').scrub
          content_sha1 = Digest::SHA1.hexdigest(content)

          custom_field = PostCustomField.find_by(name: 'rss_poster_id', value: url)

          if custom_field.nil?
            creator = PostCreator.new(feed.user,
                                      title: title,
                                      raw: TopicEmbed.absolutize_urls(url, content),
                                      skip_validations: true,
                                      bypass_rate_limiter: true,
                                      cook_method: Post.cook_methods[:raw_html],
                                      category: feed.category.id,
                                      custom_fields: { :rss_poster_id => url, :rss_poster_sha1 => content_sha1 })
            creator.create
          else
            post = custom_field.post
            post_sha1 = post.custom_fields[:rss_poster_sha1]
            if content_sha1 != post_sha1
              post.revise(feed.user,
                          raw: TopicEmbed.absolutize_urls(url, content),
                          skip_validations: true,
                          bypass_rate_limiter: true)
              post.custom_fields[:rss_poster_sha1] = content_sha1
            end
          end
        end

        feed.status = 'success'
        feed.save!
      rescue Exception => e
        feed.status = 'error'
        feed.exception = e.message
        feed.save!
      end

      interval = feed.interval.to_i
      Jobs.enqueue_in(interval.minutes, :rss_poster_poll, feed_id: id)
    end
  end
end
