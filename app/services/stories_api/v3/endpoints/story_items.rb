# frozen_string_literal: true
module StoriesApi
  module V3
    module Endpoints
      class StoryItems
        include Helpers

        attr_reader :params, :user, :story

        def initialize(params)
          @params = params
          @user = SupplejackApi::User.find_by_api_key(params[:user])
          @story = @user ? @user.user_sets.find_by_id(params[:id]) : nil
        end

        def get
          presented_story_items = @story.set_items.map(&::StoriesApi::V3::Presenters::StoryItem)

          {
            status: 200,
            payload: presented_story_items
          }
        end

        def post
          validation = StoriesApi::V3::Schemas::StoryItem::BlockValidator.new
          return validation.messages unless validation.call(params[:block])
        end

        def errors
          return V3::Errors::UserNotFound.new(params[:user]).error unless @user.present?
          return V3::Errors::StoryNotFound.new(params[:id]).error unless @story.present?
        end
      end
    end
  end
end
