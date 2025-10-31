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
# Purpose: Monkey patch extending Redmine's Issue model with CI associations.
#          Adds has_many relationships to enable linking configuration items to issues.

module HrzCmdb
  module Patches
    module IssuePatch
      # Called when module is included in Issue class.
      # Adds CI associations to Issue model using class_eval.
      # Parameter base: The Issue class that includes this module
      def self.included(base)
        base.class_eval do
          has_many :ci_issues, class_name: 'HrzcmCiIssue', foreign_key: 'issue_id', dependent: :destroy
          has_many :cis, through: :ci_issues, class_name: 'HrzcmCi'
        end
      end
    end
  end
end

# Apply the patch
unless Issue.included_modules.include?(HrzCmdb::Patches::IssuePatch)
  Issue.send(:include, HrzCmdb::Patches::IssuePatch)
end
