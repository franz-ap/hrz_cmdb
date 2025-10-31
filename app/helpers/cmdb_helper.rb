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
# Purpose: View helper methods for CMDB permission checks in views and controllers.
#          Provides convenient methods to check user's view, edit, and basic_data permissions.

module CmdbHelper
  # Checks if current user can view CMDB data.
  # Users with edit or edit_basic_data permissions can also view.
  # Returns: Boolean indicating if user has view access
  def can_view_cmdb?
    # Users who can edit can also view
    HrzCmdb::PermissionHelper.user_has_permission?(User.current, 'view_cmdb') ||
    HrzCmdb::PermissionHelper.user_has_permission?(User.current, 'edit_cmdb') ||
    HrzCmdb::PermissionHelper.user_has_permission?(User.current, 'edit_basic_data')
  end

  # Checks if current user can edit locations and CIs.
  # Returns: Boolean indicating if user has edit_cmdb permission
  def can_edit_cmdb?
    HrzCmdb::PermissionHelper.user_has_permission?(User.current, 'edit_cmdb')
  end

  # Checks if current user can edit basic data (CI classes, lifecycle statuses, external systems).
  # Returns: Boolean indicating if user has edit_basic_data permission
  def can_edit_basic_data?
    HrzCmdb::PermissionHelper.user_has_permission?(User.current, 'edit_basic_data')
  end

  # Formats documentation string as appropriate HTML link or text.
  # Parameter documentation: String documentation reference
  #   * 'tiki:PageName' ........... creates JavaScript link to TikiWiki page
  #   * 'https://...' ............. creates external link
  #   * plain text ................ wraps in span tag
  # Returns: HTML safe string (link or span element), or empty string if blank
  def format_documentation_link(documentation)
    return '' if documentation.blank?

    if documentation.starts_with?('tiki:')
      page_name = documentation.sub('tiki:', '')
      link_to documentation, "#", onclick: "HrzCmdb.openTiki('#{page_name}'); return false;",
              class: 'documentation-link', target: '_blank'
    elsif documentation =~ /\Ahttps?:\/\//
      link_to documentation, documentation, class: 'documentation-link', target: '_blank'
    else
      content_tag :span, documentation, class: 'documentation-text'
    end
  end

  # Generates breadcrumb navigation for a location showing all parent locations.
  # Parameter location: HrzcmLocation instance to generate breadcrumb for
  # Returns: HTML safe string with linked location names separated by ' > '
  def location_breadcrumb(location)
    parts = []
    current = location

    while current
      parts.unshift(link_to(current.b_name_abbr || current.b_name_full,
                           "#", onclick: "HrzCmdb.loadLocation(#{current.id}); return false;"))
      current = current.parent1
    end

    safe_join(parts, ' > ')
  end

  # Renders location select options grouped by hierarchy level.
  # Parameter selected_id: Integer ID of location to mark as selected (optional)
  # Parameter exclude_id: Integer ID of location to exclude from options (optional)
  # Returns: HTML safe string with optgroup elements containing location options
  def render_location_tree_options(selected_id = nil, exclude_id = nil)
    options = []

    HrzcmLocatHier.ordered_by_level.each do |hierarchy|
      options << content_tag(:optgroup, label: hierarchy.b_name_abbr) do
        locations = HrzcmLocation.for_type(hierarchy.id).ordered_by_b_name_abbr
        locations = locations.where.not(id: exclude_id) if exclude_id

        options_from_collection_for_select(locations, :id, :display_name, selected_id)
      end
    end

    safe_join(options)
  end

  # Returns appropriate icon HTML for a given CMDB item type.
  # Parameter type: String type identifier
  #   * 'folder' or 'location_with_children' ... folder icon 📁
  #   * 'page' or 'location' .................. page icon 📄
  #   * 'add' or 'new' ........................ add icon ➕
  #   * other ................................. default icon ▪
  # Returns: HTML safe span element with icon
  def cmdb_icon(type)
    case type
    when 'folder', 'location_with_children'
      content_tag :span, '📁', class: 'icon icon-folder'
    when 'page', 'location'
      content_tag :span, '📄', class: 'icon icon-page'
    when 'add', 'new'
      content_tag :span, '➕', class: 'icon icon-add'
    else
      content_tag :span, '▪', class: 'icon icon-default'
    end
  end

  # Generates JavaScript tag with i18n translations for client-side use.
  # Creates window.hrz_cmdb_translations object with common UI text strings.
  # Returns: HTML safe JavaScript tag setting window.hrz_cmdb_translations
  def cmdb_javascript_translations
    translations = {
      select_item: l('hrz_cmdb.select_item'),
      save: l('hrz_cmdb.buttons.save'),
      cancel: l('hrz_cmdb.buttons.cancel'),
      create: l('hrz_cmdb.buttons.create'),
      confirm_delete: l(:text_are_you_sure)
    }

    javascript_tag "window.hrz_cmdb_translations = #{translations.to_json};"
  end
end