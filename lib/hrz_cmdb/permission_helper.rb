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
# Purpose: Group-based permission checking system for CMDB access control.
#          Implements custom permission logic using Redmine groups instead of role-based permissions.

module HrzCmdb
  class PermissionHelper
    PERMISSION_TYPES = %w[view_cmdb edit_cmdb edit_basic_data].freeze

    class << self
      # Checks if a user has a specific permission based on group membership.
      # Admin users always have all permissions.
      # Parameter user: User instance to check permissions for
      # Parameter permission_type: String permission type
      #   * 'view_cmdb' ............... view CMDB data
      #   * 'edit_cmdb' ............... edit locations and CIs
      #   * 'edit_basic_data' ......... edit CI classes, lifecycle statuses, and external systems
      # Returns: Boolean indicating if user has the specified permission
      def user_has_permission?(user, permission_type)
        return false unless user && PERMISSION_TYPES.include?(permission_type)

        # Admin users have all permissions
        return true if user.admin?

        # Get settings
        settings = Setting.plugin_hrz_cmdb || {}
        group_ids = settings["#{permission_type}_groups"] || []
        group_ids = [group_ids].flatten.map(&:to_i) # Ensure array of integers

        # Check if user belongs to any of the authorized groups
        user.groups.any? { |group| group_ids.include?(group.id) }
      end

      # Gets all group IDs authorized for a specific permission from plugin settings.
      # Parameter permission_type: String permission type (view_cmdb, edit_cmdb, edit_basic_data)
      # Returns: Array of Integer group IDs
      def groups_for_permission(permission_type)
        return [] unless PERMISSION_TYPES.include?(permission_type)

        settings = Setting.plugin_hrz_cmdb || {}
        group_ids = settings["#{permission_type}_groups"] || []
        [group_ids].flatten.map(&:to_i)
      end

      # Gets all Group objects authorized for a specific permission.
      # Parameter permission_type: String permission type (view_cmdb, edit_cmdb, edit_basic_data)
      # Returns: ActiveRecord::Relation of Group instances
      def groups_with_permission(permission_type)
        group_ids = groups_for_permission(permission_type)
        Group.where(id: group_ids)
      end
    end
  end
end