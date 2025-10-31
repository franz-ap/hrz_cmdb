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
# Purpose: Test configuration and helper methods for CMDB plugin tests.
#          Loads Redmine test environment and provides common test utilities.

# Load the Redmine test helper
require File.expand_path(File.dirname(__FILE__) + '/../../../test/test_helper')

# Additional test helper methods for CMDB plugin
class ActiveSupport::TestCase
  # Returns a user with CMDB permissions
  # Parameter permission_type: String permission type (view_cmdb, edit_cmdb, edit_basic_data)
  # Returns: User instance with specified permission
  def user_with_cmdb_permission(permission_type)
    user = User.find_by(login: 'jsmith') || User.find(2)
    group = Group.create!(lastname: "Test #{permission_type} Group")
    group.users << user

    # Set plugin settings to grant permission to this group
    Setting.plugin_hrz_cmdb = {
      "#{permission_type}_groups" => [group.id.to_s]
    }

    user
  end

  # Returns a user without any CMDB permissions
  # Returns: User instance without CMDB permissions
  def user_without_cmdb_permission
    user = User.find_by(login: 'dlopper') || User.find(3)
    Setting.plugin_hrz_cmdb = {}
    user
  end

  # Sets up User.current for permission testing
  # Parameter user: User instance to set as current
  def setup_user_current(user)
    User.current = user
  end
end
