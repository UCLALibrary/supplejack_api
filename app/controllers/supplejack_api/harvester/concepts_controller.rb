# The majority of the Supplejack API code is Crown copyright (C) 2014, New Zealand Government, 
# and is licensed under the GNU General Public License, version 3.
# One component is a third party component. See https://github.com/DigitalNZ/supplejack_api for details. 
# 
# Supplejack was created by DigitalNZ at the National Library of NZ and 
# the Department of Internal Affairs. http://digitalnz.org/supplejack

module SupplejackApi
  module Harvester
    class ConceptsController < ActionController::Base
      respond_to :json

      def create
        @concept = Concept.find_or_initialize_by_identifier(params[:concept])
        @concept.landing_url = params[:concept].delete(:landing_url)
        @concept.set_status(params[:required_fragments])
        @concept.create_or_update_fragment(params[:concept])
        @concept.save
        @concept.unset_null_fields
        render json: {concept_id: @concept.concept_id}
      end

      def update
        @concept = Concept.custom_find(params[:id],nil, {status: :all})
        if params[:concept].present? and params[:concept][:status].present?
          @concept.update_attribute(:status, params[:concept][:status])
        end
        respond_with @concept
      end
    end
  end
end
