require 'google/api_client'
require 'json'
require 'yaml'

# Alternative popular post plugin for Octopress based on page views fetched
# from google analytics API. This plugin generates cache file to your Octopress
# directory as ".analytics-cache". Cache file will expire 1 day after since
# Google Analytics API refreshes its data every day.
#
# Before you use the plugin:
#
# Must set environment variables:
# - GOOGLE_ANALYTICS_PROFILE="ga:dddddddd" (dddddddd is number)
# - GOOGLE_API_HOME="${HOME}/.google-api.yaml"
#
# Set optional configuration in your _config.yml
# - popular_posts: 10 (default: 10)
#
# See original popular post plugin:
# https://github.com/octopress-themes/popular-posts
module OctopressPlugin

  module PopularPost

    class GoogleAnalytics

      def initialize(max_results = 10)
        @profile     = ENV["GOOGLE_ANALYTICS_PROFILE"]
        @max_results = max_results

        config = YAML.load_file(ENV["GOOGLE_API_HOME"])

        @client = ::Google::APIClient.new(
          :authorization       => :oauth_2,
          :application_name    => 'OctopressPopularPostPlugin',
          :application_version => '0.1'
        )
        @client.authorization.scope         = config['scope']
        @client.authorization.client_id     = config['client_id']
        @client.authorization.client_secret = config['client_secret']
        @client.authorization.access_token  = config['access_token']
        @client.authorization.refresh_token = config['refresh_token']

        @analytics = @client.discovered_api('analytics', 'v3')
      end

      def unique_page_views(path, from, to, start_index = 1)
        result = @client.execute(
          :api_method => @analytics.data.ga.get,
          :parameters => {
            'ids'         => @profile,
            'start-date'  => from.to_date.strftime('%Y-%m-%d'),
            'end-date'    => to.to_date.strftime('%Y-%m-%d'),
            'metrics'     => 'ga:uniquePageviews',
            'dimensions'  => 'ga:pagePath',
            'filters'     => "ga:pagePath=~#{path}",
            'sort'        => '-ga:uniquePageviews',
            'start-index' => start_index,
            'max-results' => @max_results
          }
        )

        if result.status != 200
          raise result.response.body.to_s
        end

        result.response.body
      end

    end #GoogleAnalytics

    class GoogleAnalyticsClient

      DAY_IN_SECS = 86400

      def initialize(max_results = 10)
        @max_results = max_results
        @cache_disabled = false
        @cache_path = File.expand_path('../.analytics-cache', File.dirname(__FILE__))
      end

      def get_score(url)
        if !@score
          data  = get_cache || get_unique_page_views
          json  = JSON.parse(data)
          score = Hash.new(0)

          json['rows'].each do |row|
            # {url => pv}
            score[row[0]] = row[1].to_i
          end

          @score = score
        end

        @score.has_key?(url) ? @score[url] : 0
      end

      def get_unique_page_views
        analytics = GoogleAnalytics.new(@max_results)

        pv = analytics.unique_page_views(
          '^/blog/\d{4}/\d{2}/\d{2}/.*/$',
          Date.today.prev_month, Date.today
        )

        cache pv unless @cache_disabled

        pv
      end

      def get_cache
        File.read(@cache_path) if !cache_expired?(@cache_path)
      end

      def cache_expired?(cache_path)
        if File.exist?(cache_path)
          (Time.now - File.mtime(cache_path)) > DAY_IN_SECS
        else
          true
        end
      end

      def cache(data)
        File.open(@cache_path, "w") do |io|
          io.write data
        end
      end

    end #GoogleAnalyticsClient

    module Post

      def self.included(base)
        if base.class.instance_methods.include?('popular_score')
          raise 'Octopress Popular Posts: Name clashes'
        else
          base.class_eval do
            include PublicInstanceMethods
            attr_accessor :popular_score_client
          end
        end
      end

      module PublicInstanceMethods

        def popular_score
          self.popular_score_client.get_score(self.url)
        end
      end

    end # Post

    module Site

      def self.included(base)
        base.class_eval do
          attr_accessor :popular_posts
          alias_method :old_read, :read
          alias_method :old_site_payload, :site_payload

          def read
            old_read

            # Instantiate client object once
            max_results = self.config.has_key?('popular_posts') ? self.config['popular_posts'] : 10
            client = GoogleAnalyticsClient.new(max_results)

            self.popular_posts = self.posts.sort do |post_x, post_y|
              post_x.popular_score_client = client
              post_y.popular_score_client = client
              x = post_x.popular_score
              y = post_y.popular_score

              if x < y
                1
              elsif x > y
                -1
              else
                post_y.date <=> post_x.date
              end
            end
          end

          def site_payload
            old_site_hash = old_site_payload
            old_site_hash['site'].merge!({'popular_posts' => self.popular_posts})
            old_site_hash
          end
        end
      end # included

    end # Site

  end #PopularPost

end #OctopressPlugin

module Jekyll

  class Post
    include OctopressPlugin::PopularPost::Post
  end

  class Site
    include OctopressPlugin::PopularPost::Site
  end

end
