# frozen_string_literal: true
# The majority of the Supplejack API code is Crown copyright (C) 2014, New Zealand Government,
# and is licensed under the GNU General Public License, version 3.
# One component is a third party component. See https://github.com/DigitalNZ/supplejack_api for details.
#
# Supplejack was created by DigitalNZ at the National Library of NZ and
# the Department of Internal Affairs. http://digitalnz.org/supplejack

module SupplejackApi
  module Support
    module Harvestable
      extend ActiveSupport::Concern

      def create_or_update_fragment(attributes)
        if fragment = find_fragment(attributes['source_id'])
          fragment.clear_attributes
        elsif fragments.count.zero?
          fragment = primary_fragment
        else
          fragment = fragments.build
        end

        fragment.update_from_harvest(attributes)
      end

      def update_from_harvest(attributes = {})
        attributes = attributes.try(:symbolize_keys) || {}

        attributes[:status] ||= 'active'

        self.class.fields.each do |name, _field|
          if attributes.key?(name.to_sym)
            value = Array(attributes[name.to_sym]).first
            send("#{name}=", value)
          end
        end

        primary_fragment.update_from_harvest(attributes)
        self.updated_at = Time.now
      end

      def update_from_harvest!(attributes = {})
        update_from_harvest(attributes)
        save
      end

      def set_status(required_fragments)
        missing_fragments = Array(required_fragments) - fragments.map(&:source_id)
        self.status = missing_fragments.empty? ? 'active' : 'partial'
      end

      # Sets all the Record attributes to nil except the internal ones
      # that shouldn't be removed (_id, _type, etc..)
      #
      def clear_attributes
        self[:source_url] = nil
        primary_fragment.clear_attributes
      end

      def unset_null_fields
        raw_json = raw_attributes || {}
        unset_hash = {}
        raw_json.each do |key, value|
          unset_hash.merge!(key => true) if value.nil?
        end
        if raw_json['fragments'].present?
          raw_json['fragments'].each_with_index do |fragment, index|
            next if fragment.nil?
            fragment.each do |key, value|
              unset_hash.merge!("fragments.#{index}.#{key}" => true) if value.nil?
            end
          end
        end
        collection.find(atomic_selector).update('$unset' => unset_hash) if unset_hash.any?
      end

      module ClassMethods
        def find_or_initialize_by_identifier(attributes)
          attributes = attributes.symbolize_keys
          identifier = attributes.delete(:internal_identifier)
          identifier = identifier.first if identifier.is_a?(Array)
          find_or_initialize_by(internal_identifier: identifier)
        end

        def flush_old_records(source_id, job_id)
          where(
            :'fragments.source_id' => source_id,
            :'fragments.job_id'.ne => job_id,
            :status.in => %w(active supressed)
          ).update_all(status: 'deleted', updated_at: Time.now)

          cursor = deleted.where('fragments.source_id': source_id)
          total = cursor.count
          start = 0
          chunk_size = 10_000
          while start < total
            records = cursor.limit(chunk_size).skip(start)
            Sunspot.remove(records)
            start += chunk_size
          end
        end
      end
    end
  end
end
