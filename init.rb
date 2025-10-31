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
# Purpose: Plugin registration file for the CMDB Redmine plugin.
#          Defines plugin metadata, menu items, permissions, settings, and loads all lib files.

require 'redmine'

Redmine::Plugin.register :hrz_cmdb do
  name 'CMDB AF'
  author 'Franz Apeltauer, Claude'
  description 'Configuration Management Database (CMDB) plugin for Redmine'
  version '0.7.28'
  url 'https://github.com/franz-ap/hrz_cmdb'
  author_url ''
  requires_redmine version_or_higher: '6.1.0'

  # Add menu item to top menu
  menu :top_menu, :cmdb,
       { controller: 'cmdb', action: 'index' },
       caption: :label_cmdb,
       if: Proc.new {
         HrzCmdb::PermissionHelper.user_has_permission?(User.current, 'view_cmdb') ||
         HrzCmdb::PermissionHelper.user_has_permission?(User.current, 'edit_cmdb') ||
         HrzCmdb::PermissionHelper.user_has_permission?(User.current, 'edit_basic_data')
       }

  # Settings - Group-based permissions and configuration
  settings default: {
    'view_cmdb_groups' => [],
    'edit_cmdb_groups' => [],
    'edit_basic_data_groups' => [],
    'tiki_base_url' => ''
  }, partial: 'settings/hrz_cmdb_settings'

  # Project module
  project_module :cmdb do
    permission :view_issue_cis, { issue_cis: [:available_cis] }, read: true
    permission :manage_issue_cis, { issue_cis: [:create, :destroy] }
  end
end

# Load the plugin's lib files
Dir[File.join(File.dirname(__FILE__), 'lib', '**', '*.rb')].each do |file|
  require_dependency file
end
