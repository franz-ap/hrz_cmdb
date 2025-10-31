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
# Purpose: Monkey patch extending IssuesHelper to display CI changes in issue history/journal.
#          Adds custom formatting for CI addition/removal events in issue activity logs.

module HrzCmdb
  module Patches
    module IssuesHelperPatch
      # Called when module is included in IssuesHelper.
      # Sets up method aliasing to intercept show_detail calls.
      # Parameter base: The IssuesHelper module that includes this patch
      def self.included(base)
        base.class_eval do
          alias_method :show_detail_without_ci, :show_detail
          alias_method :show_detail, :show_detail_with_ci
        end
      end

      # Enhanced show_detail method with CI relation handling.
      # Formats CI addition/removal events, delegates other details to original method.
      # Parameter detail: JournalDetail instance containing the change information
      # Parameter no_html: Boolean flag for text-only output (default: false)
      # Parameter options: Hash of additional options (default: {})
      # Returns: String formatted change description
      def show_detail_with_ci(detail, no_html=false, options={})
        # Handle CI relation changes
        if detail.property == 'relation' && detail.prop_key == 'ci'
          label = l(:label_configuration_item)

          old_value = if detail.old_value.present?
            ci = HrzcmCi.find_by(id: detail.old_value)
            ci ? ci.display_name : "##{detail.old_value}"
          else
            nil
          end

          new_value = if detail.value.present?
            ci = HrzcmCi.find_by(id: detail.value)
            ci ? ci.display_name : "##{detail.value}"
          else
            nil
          end

          if old_value.present? && new_value.blank?
            # CI was removed
            label + " " + l(:label_ci_deleted, old_value: old_value)
          elsif old_value.blank? && new_value.present?
            # CI was added
            label + " " + l(:label_ci_added, new_value: new_value)
          else
            # Shouldn't happen, but just in case
            label + " " + l(:text_journal_changed, label: label, old: old_value, new: new_value)
          end
        else
          # Call original method for all other detail types
          show_detail_without_ci(detail, no_html, options)
        end
      end
    end
  end
end

# Apply the patch
unless IssuesHelper.included_modules.include?(HrzCmdb::Patches::IssuesHelperPatch)
  IssuesHelper.include(HrzCmdb::Patches::IssuesHelperPatch)
end
