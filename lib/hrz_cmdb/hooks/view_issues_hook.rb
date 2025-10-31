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
# Purpose: Redmine view hooks to inject CI sections into issue pages.
#          Adds the CI list partial below issue descriptions and loads required assets when CMDB module is enabled.

module HrzCmdb
  module Hooks
    class ViewIssuesHook < Redmine::Hook::ViewListener
      # Hook to add CI section in issue show page (after description)
      # Module check is done in the partial itself
      render_on :view_issues_show_description_bottom,
                partial: 'issue_cis/issue_cis_section'

      # Injects CSS and JavaScript assets into issue page HTML head when CMDB module is enabled.
      # Checks if current issue/project has CMDB module enabled before adding assets.
      # Parameter context: Hash with :controller key containing the current controller instance
      # Returns: String HTML tags for stylesheet and JavaScript, or empty string if CMDB not enabled
      def view_layouts_base_html_head(context={})
        return '' unless context[:controller] && context[:controller].is_a?(IssuesController)

        # Check if the current issue's project has CMDB module enabled
        controller = context[:controller]
        if controller.instance_variable_defined?(:@issue)
          issue = controller.instance_variable_get(:@issue)
          return '' if issue && issue.project && !issue.project.module_enabled?(:cmdb)
        elsif controller.instance_variable_defined?(:@project)
          project = controller.instance_variable_get(:@project)
          return '' if project && !project.module_enabled?(:cmdb)
        end

        stylesheet_link_tag('hrz_cmdb', plugin: 'hrz_cmdb') +
        javascript_include_tag('issue_cis', plugin: 'hrz_cmdb')
      end
    end
  end
end
