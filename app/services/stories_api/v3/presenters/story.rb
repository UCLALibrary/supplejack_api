# frozen_string_literal: true
# The majority of the Supplejack API code is Crown copyright (C) 2014, New Zealand Government,
# and is licensed under the GNU General Public License, version 3.
# One component is a third party component. See https://github.com/DigitalNZ/supplejack_api for details.
#
# Supplejack was created by DigitalNZ at the National Library of NZ and
# the Department of Internal Affairs. http://digitalnz.org/supplejack

module StoriesApi
  module V3
    module Presenters
      class Story
        TOP_LEVEL_FIELDS = [
          :name,
          :description,
          :privacy,
          :copyright,
          :featured,
          :approved,
          :tags,
          :updated_at
        ].freeze

        def call(story)
          result = {}

          TOP_LEVEL_FIELDS.each do |field|
            result[field] = story.send(field)
          end
          result[:id] = story.id.to_s
          result[:number_of_items] = story.set_items.count
          result[:contents] = story.set_items.sort_by(&:position).map(&StoryItem)

          result
        end

        def self.to_proc
          ->(story) { new.call(story) }
        end
      end
    end
  end
end
