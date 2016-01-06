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
        Rails.logger.debug("SupplejackApi::Support::Harvestable.create_or_update_fragment(#{attributes.inspect})")
        if fragment = find_fragment(attributes['source_id'])
          Rails.logger.debug("SupplejackApi::Support::Harvestable.create_or_update_fragment: clearing attributes of #{fragment.inspect}")
          fragment.clear_attributes
        elsif self.fragments.count == 0
          fragment = self.primary_fragment
        else
          fragment = self.fragments.build
        end

        fragment.update_from_harvest(attributes)
      end


      def update_from_harvest(attributes={})
        attributes = attributes.try(:symbolize_keys) || {}
        Rails.logger.debug("SupplejackApi::Support::Harvestable.update_from_harvest(#{attributes.inspect})")
        Rails.logger.debug("SupplejackApi::Support::Harvestable.update_from_harvest: #{self.class.fields.inspect}")

        attributes[:status] ||= "active"

        self.class.fields.each do |name, field|
          if attributes.has_key?(name.to_sym)
            value = Array(attributes[name.to_sym]).first
            self.send("#{name}=", value)
          end
        end

        self.primary_fragment.update_from_harvest(attributes)
        self.updated_at = Time.now
      end


      def update_from_harvest!(attributes={})
        self.update_from_harvest(attributes)
        self.save
      end

      def set_status(required_fragments)
        missing_fragments = Array(required_fragments) - self.fragments.map(&:source_id)
        self.status = missing_fragments.empty? ? 'active' : 'partial'
      end

      # Sets all the Record attributes to nil except the internal ones
      # that shouldn't be removed (_id, _type, etc..)
      #
      def clear_attributes
        Rails.logger.debug("SupplejackApi::Support::Harvestable.clear_attributes()")
        self[:source_url] = nil
        self.primary_fragment.clear_attributes
      end

      def unset_null_fields
        raw_json = self.raw_attributes || {}
        unset_hash = {}
        raw_json.each do |key, value|
          unset_hash.merge!({key => true}) if value.nil?
        end
        if raw_json['fragments'].present?
          raw_json['fragments'].each_with_index do |fragment, index|
            next if fragment.nil?
            fragment.each do |key,value|
              unset_hash.merge!({"fragments.#{index}.#{key}" => true}) if value.nil?
            end
          end
        end
        self.collection.find(self.atomic_selector).update({"$unset" => unset_hash}) if unset_hash.any?
      end

      module ClassMethods
        def find_or_initialize_by_identifier(attributes)
          attributes = attributes.symbolize_keys
          identifier = attributes.delete(:internal_identifier)
          identifier = identifier.first if identifier.is_a?(Array)
          self.find_or_initialize_by(internal_identifier: identifier)
        end

        def flush_old_records(source_id, job_id)
          self.where(
            :'fragments.source_id' => source_id, 
            :'fragments.job_id'.ne => job_id, 
            :'status'.in => ['active', 'supressed']
          ).update_all(status: 'deleted', updated_at: Time.now)

          cursor = self.deleted.where(:'fragments.source_id' => source_id)
          total = cursor.count
          start = 0
          chunk_size = 10000
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
