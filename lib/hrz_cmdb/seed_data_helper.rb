#-------------------------------------------------------------------------------------------#
# Redmine CMDB plugin: Configuration Management DataBase                                    #
# Copyright (C) 2025 Franz Apeltauer                                                        #
#                                                                                           #
# This program is free software: you can redistribute it and/or modify it under the terms   #
# of the GNU Affero General Public License as published by the Free Software Foundation,    #
# either version 3 of the License, or (at your option) any later version.                   #
#                                                                                           #
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; #
# without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. #
# See the GNU Affero General Public License for more details.                               #
#                                                                                           #
# You should have received a copy of the GNU Affero General Public License                  #
# along with this program.  If not, see <https://www.gnu.org/licenses/>.                    #
#-------------------------------------------------------------------------------------eohdr-#
# Purpose: Helper methods for inserting and removing seed data with hierarchy support.
#          Handles foreign key dependencies and duplicate detection via b_key.

module HrzCmdb
  class SeedDataHelper
    class << self
      # Inserts all seed data, skipping records that already exist (by b_key).
      # Processes hierarchies from root to leaf.
      # Returns: Hash with statistics { inserted: {}, skipped: {}, errors: {} }
      def insert_all_seed_data
        stats = { inserted: {}, skipped: {}, errors: {} }

        HrzCmdb::SeedData.insertion_order.each do |entry|
          model = entry[:model]
          data = entry[:data]
          model_name = model.name.demodulize.underscore.to_sym

          stats[:inserted][model_name] = 0
          stats[:skipped][model_name] = 0
          stats[:errors][model_name] = []

          insert_seed_data_for_model(model, data, stats, model_name)
        end

        stats
      end

      # Removes all unused seed data (records not referenced by foreign keys).
      # Processes hierarchies from leaf to root.
      # Returns: Hash with statistics { deleted: {}, kept: {} (still in use), errors: {} }
      def remove_unused_seed_data
        stats = { deleted: {}, kept: {}, errors: {} }

        HrzCmdb::SeedData.deletion_order.each do |model|
          model_name = model.name.demodulize.underscore.to_sym

          stats[:deleted][model_name] = 0
          stats[:kept][model_name] = 0
          stats[:errors][model_name] = []

          remove_unused_for_model(model, stats, model_name)
        end

        stats
      end

      private

      # Inserts seed data for a specific model.
      # Parameter model: ActiveRecord model class
      # Parameter data: Array of hashes with seed data
      # Parameter stats: Hash for collecting statistics
      # Parameter model_name: Symbol model name for stats
      def insert_seed_data_for_model(model, data, stats, model_name)
        puts "=== Starting insert for model: #{model.name}, records: #{data.size} ==="

        data.each do |record_data|
          b_key = record_data[:b_key]
          puts "  Processing record: #{b_key}"

          # Skip if record with this b_key already exists
          if model.exists?(b_key: b_key)
            puts "    -> SKIPPED (already exists)"
            stats[:skipped][model_name] += 1
            next
          end

          # Prepare record attributes
          attributes = record_data.dup

          # Handle parent relationship for CI Classes
          if model == HrzcmCiClass
            parent_key_value = attributes.delete(:parent_key)
            if parent_key_value.present?
              puts "    -> Has parent_key: #{parent_key_value}"
              parent = HrzcmCiClass.find_by(b_key: parent_key_value)
              if parent
                puts "    -> Parent found with id: #{parent.id}"
                attributes[:j_subclass_of_id] = parent.id
              else
                error_msg = "Parent '#{parent_key_value}' not found for '#{b_key}'"
                puts "    -> ERROR: #{error_msg}"
                stats[:errors][model_name] << error_msg
                next
              end
            else
              puts "    -> Root level CI class (no parent)"
            end
          end

          # Create record
          begin
            puts "    -> Attempting to create with attributes: #{attributes.inspect}"
            record = model.create!(attributes)
            puts "    -> SUCCESS: Created with id: #{record.id}"
            stats[:inserted][model_name] += 1
          rescue => e
            error_msg = "#{b_key}: #{e.message}"
            puts "    -> ERROR during create: #{error_msg}"
            stats[:errors][model_name] << error_msg
          end
        end

        puts "=== Finished insert for model: #{model.name} ==="
      end

      # Removes unused seed data for a specific model.
      # Parameter model: ActiveRecord model class
      # Parameter stats: Hash for collecting statistics
      # Parameter model_name: Symbol model name for stats
      def remove_unused_for_model(model, stats, model_name)
        puts "=== Starting removal for model: #{model.name} ==="

        # Get seed b_keys in correct order for deletion
        # For CI Classes: reverse order (leaf to root) to handle parent-child relationships
        seed_keys = case model.name
                    when 'HrzcmLocatHier'
                      HrzCmdb::SeedData::LOCATION_HIERARCHY.map { |r| r[:b_key] }
                    when 'HrzcmCiClass'
                      # Reverse order: delete children before parents
                      HrzCmdb::SeedData::CI_CLASSES.reverse.map { |r| r[:b_key] }
                    when 'HrzcmLifecycleStatus'
                      HrzCmdb::SeedData::LIFECYCLE_STATUSES.map { |r| r[:b_key] }
                    else
                      []
                    end

        puts "  Processing #{seed_keys.size} seed keys in deletion order"

        # Process records in the specific order (important for hierarchies)
        seed_keys.each do |b_key|
          record = model.find_by(b_key: b_key)

          unless record
            puts "  Record with b_key '#{b_key}' not found (already deleted or never existed)"
            next
          end

          puts "  Processing record: #{b_key} (id: #{record.id})"

          if record_is_unused?(record)
            begin
              puts "    -> Attempting to delete (unused)"
              record.destroy
              puts "    -> SUCCESS: Deleted"
              stats[:deleted][model_name] += 1
            rescue => e
              error_msg = "#{record.b_key}: #{e.message}"
              puts "    -> ERROR during delete: #{error_msg}"
              stats[:errors][model_name] << error_msg
              stats[:kept][model_name] += 1
            end
          else
            puts "    -> KEPT (still in use)"
            stats[:kept][model_name] += 1
          end
        end

        puts "=== Finished removal for model: #{model.name} ==="
      end

      # Checks if a record is unused (not referenced by any foreign keys).
      # Parameter record: ActiveRecord record instance
      # Returns: Boolean true if record is not referenced anywhere
      def record_is_unused?(record)
        case record.class.name
        when 'HrzcmLocatHier'
          # Check if any locations use this hierarchy type
          !HrzcmLocation.exists?(j_type_id: record.id)

        when 'HrzcmCiClass'
          # Check if any CIs use this class or if it has subclasses
          !HrzcmCi.exists?(j_ci_class_id: record.id) &&
            !HrzcmCiClass.exists?(j_subclass_of_id: record.id)

        when 'HrzcmLifecycleStatus'
          # Check if any CIs use this status
          !HrzcmCi.exists?(j_status_id: record.id)

        else
          false
        end
      end
    end
  end
end
