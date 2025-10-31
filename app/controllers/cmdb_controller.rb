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
# Purpose: Main CMDB controller handling CRUD operations for locations, CI classes, CIs, lifecycle statuses, and external systems.
#          Provides the jsTree data endpoint and enforces group-based permissions for all CMDB entities.

class CmdbController < ApplicationController
  before_action :check_permissions
  before_action :find_location, only: [:show_location, :update_location, :destroy_location]
  before_action :find_ci_class, only: [:show_ci_class, :update_ci_class, :destroy_ci_class]
  before_action :find_ci, only: [:show_ci, :update_ci, :destroy_ci]
  before_action :find_lifecycle_status, only: [:show_lifecycle_status, :update_lifecycle_status, :destroy_lifecycle_status]
  before_action :find_ext_sys, only: [:show_ext_sys, :update_ext_sys, :destroy_ext_sys]
  before_action :check_edit_permissions, only: [:new_location, :create_location, :update_location, :destroy_location, :new_ci, :create_ci, :update_ci, :destroy_ci]
  before_action :check_basic_data_permissions, only: [:new_ci_class, :create_ci_class, :update_ci_class, :destroy_ci_class, :new_lifecycle_status, :create_lifecycle_status, :update_lifecycle_status, :destroy_lifecycle_status, :new_ext_sys, :create_ext_sys, :update_ext_sys, :destroy_ext_sys]

  # Main CMDB index page showing the tree navigation interface.
  # Sets permission flags for view rendering.
  # Returns: HTML view with permission flags @can_edit and @can_edit_basic_data
  def index
    @can_edit = can_edit?
    @can_edit_basic_data = can_edit_basic_data?
  end

  # Info page displaying plugin information and statistics.
  # Shows plugin URL, logos, and counts of all CMDB entities.
  # Returns: Partial view with plugin info and statistics
  def info
    # Get plugin information
    plugin = Redmine::Plugin.find(:hrz_cmdb)
    @plugin_url = plugin.url
    @plugin_version = plugin.version
    @plugin_name = plugin.name

    # Get statistics
    @ci_classes_count = HrzcmCiClass.count
    @cis_count = HrzcmCi.count
    @lifecycle_statuses_count = HrzcmLifecycleStatus.count
    @location_hierarchies_count = HrzcmLocatHier.count
    @locations_count = HrzcmLocation.count

    render partial: 'cmdb/info'
  end



  # Defines the structure of the navigation tree.
  # Parameter parent_id:
  #   * blank ................... root level of the tree
  #   * 'location_hierarchy' .... Location hierarchy sub-tree
  def tree_data
    # Returns JSON data for the tree structure
    nodes = []

    # -------------------------------------------------------------------------
    # Root of the tree
    if params[:parent_id].blank?
      # Add "Create new location" node if user has edit rights
      if can_edit?
        nodes << {
          id: 'new_location',
          text: I18n.t('hrz_cmdb.locations.new'),
          icon: 'icon-add',
          children: false,
          type: 'new'
        }
      end

      # Add root locations
      HrzcmLocation.root_locations.ordered_by_b_name_abbr.each do |location|
        nodes << location_to_tree_node(location)
      end

      # Add "CIs by Class" folder
      nodes << {
        id: 'cis_by_class',
        text: I18n.t('hrz_cmdb.cis_by_class.title'),
        icon: 'icon-folder',
        children: true,
        type: 'folder'
      }

      # Add "Basic Data" folder if user has rights
      if can_edit_basic_data?
        nodes << {
          id: 'basic_data',
          text: I18n.t('hrz_cmdb.basic_data.title'),
          icon: 'icon-folder',
          children: true,
          type: 'folder'
        }
      end

      # Add "Settings" folder at the end if user has rights
      if can_edit_basic_data?
        nodes << {
          id: 'settings',
          text: I18n.t('hrz_cmdb.settings.title'),
          icon: 'icon-settings',
          children: true,
          type: 'folder'
        }
      end
    # -------------------------------------------------------------------------
    # Settings subfolder
    elsif params[:parent_id] == 'settings'
      # Seed data. Only for users with edit_basic_data rights.
      if can_edit_basic_data?
        nodes << {
          id: 'seed_data',
          text: I18n.t('hrz_cmdb.seed_data.menu_title'),
          icon: 'icon-package',
          children: false,
          type: 'seed_data'
        }
      end
      nodes << {
        id: 'info',
        text: I18n.t('hrz_cmdb.info.menu_title'),
        icon: 'icon-help',
        children: false,
        type: 'info'
      }
    # -------------------------------------------------------------------------
    # Basic data subfolder
    elsif params[:parent_id] == 'basic_data'
      nodes << {
        id: 'location_hierarchy',
        text: I18n.t('hrz_cmdb.location_hierarchy.title'),
        icon: 'icon-folder',
        children: true,
        type: 'folder'
      }
      nodes << {
        id: 'ci_classes',
        text: I18n.t('hrz_cmdb.ci_classes.title'),
        icon: 'icon-folder',
        children: true,
        type: 'folder'
      }
      nodes << {
        id: 'lifecycle_statuses',
        text: I18n.t('hrz_cmdb.lifecycle_statuses.title'),
        icon: 'icon-folder',
        children: true,
        type: 'folder'
      }
      nodes << {
        id: 'external_systems',
        text: I18n.t('hrz_cmdb.external_systems.title'),
        icon: 'icon-folder',
        children: true,
        type: 'folder'
      }
    # -------------------------------------------------------------------------
    # Location hierarchy sub-tree
    elsif params[:parent_id] == 'location_hierarchy'
      # Add "Create new hierarchy level" node
      if can_edit_basic_data?
        nodes << {
          id: 'new_hierarchy',
          text: I18n.t('hrz_cmdb.location_hierarchy.new'),
          icon: 'icon-add',
          children: false,
          type: 'new_hierarchy'
        }
      end

      # Add hierarchy levels
      HrzcmLocatHier.ordered_by_level.each do |hierarchy|
        node = {
          id: "hierarchy_#{hierarchy.id}",
          text: hierarchy.b_name_abbr,
          icon: 'icon-page',
          children: false,
          type: 'hierarchy'
        }
        # Only add title if b_name_full differs from b_name_abbr
        if hierarchy.b_name_full.present? && hierarchy.b_name_abbr.present? && hierarchy.b_name_full != hierarchy.b_name_abbr
          node[:title] = hierarchy.b_name_full
        end
        nodes << node
      end
    # -------------------------------------------------------------------------
    # CI classes
    elsif params[:parent_id] == 'ci_classes'
      # Add "Create new CI class" node
      if can_edit_basic_data?
        nodes << {
          id: 'new_ci_class',
          text: I18n.t('hrz_cmdb.ci_classes.new'),
          icon: 'icon-add',
          children: false,
          type: 'new_ci_class'
        }
      end

      # Add root CI classes
      HrzcmCiClass.root_classes.ordered_by_sort_and_abbr.each do |ci_class|
        nodes << ci_class_to_tree_node(ci_class)
      end
    # -------------------------------------------------------------------------
    # Lifecycle statuses
    elsif params[:parent_id] == 'lifecycle_statuses'
      # Add "Create new lifecycle status" node
      if can_edit_basic_data?
        nodes << {
          id: 'new_lifecycle_status',
          text: I18n.t('hrz_cmdb.lifecycle_statuses.new'),
          icon: 'icon-add',
          children: false,
          type: 'new_lifecycle_status'
        }
      end

      # Add all lifecycle statuses
      HrzcmLifecycleStatus.ordered_by_abbr.each do |status|
        nodes << lifecycle_status_to_tree_node(status)
      end
    # -------------------------------------------------------------------------
    # External systems
     elsif params[:parent_id] == 'external_systems'
      # Add "Create new external system" node
      if can_edit_basic_data?
        nodes << {
          id: 'new_ext_sys',
          text: I18n.t('hrz_cmdb.external_systems.new'),
          icon: 'icon-add',
          children: false,
          type: 'new_ext_sys'
        }
      end

      # Add all external systems
      HrzcmExtSys.ordered_by_abbr.each do |ext_sys|
        nodes << ext_sys_to_tree_node(ext_sys)
      end
    # -------------------------------------------------------------------------
    # CIs by CI Class
    elsif params[:parent_id] == 'cis_by_class'
      # CIs organized by CI Class - show root CI classes with their CIs
      if can_edit?
        nodes << {
          id: 'new_ci',
          text: I18n.t('hrz_cmdb.cis.new'),
          icon: 'icon-add',
          children: false,
          type: 'new_ci'
        }
      end

      HrzcmCiClass.root_classes.ordered_by_sort_and_abbr.each do |ci_class|
        nodes << ci_class_for_ci_tree_node(ci_class)
      end
    # -------------------------------------------------------------------------
    # Show subclasses and CIs of this CI class
    elsif params[:parent_id].to_s.start_with?('ci_class_for_ci_')
      ci_class_id = params[:parent_id].to_s.sub('ci_class_for_ci_', '').to_i

      # Add subclasses
      HrzcmCiClass.for_parent(ci_class_id).ordered_by_sort_and_abbr.each do |subclass|
        nodes << ci_class_for_ci_tree_node(subclass)
      end

      # Add CIs of this class
      HrzcmCi.for_ci_class(ci_class_id).ordered_by_abbr.each do |ci|
        nodes << ci_to_tree_node(ci)
      end
    # -------------------------------------------------------------------------

    elsif params[:parent_id].to_s.start_with?('location_cis_')
      # CIs of a specific location
      location_id = params[:parent_id].to_s.sub('location_cis_', '').to_i
      HrzcmCi.for_location(location_id).ordered_by_abbr.each do |ci|
        nodes << ci_to_tree_node(ci)
      end
    # -------------------------------------------------------------------------
    # CI class children (from Stammdaten)
    elsif params[:parent_id].to_s.start_with?('ci_class_')
      ci_class_id = params[:parent_id].to_s.sub('ci_class_', '').to_i
      ci_class = HrzcmCiClass.find_by(id: ci_class_id)
      if ci_class
        HrzcmCiClass.for_parent(ci_class_id).ordered_by_sort_and_abbr.each do |subclass|
          nodes << ci_class_to_tree_node(subclass)
        end
      end
    # -------------------------------------------------------------------------
    else
      # Location children
      location_id = params[:parent_id].to_i
      location = HrzcmLocation.find_by(id: location_id)
      if location
        # Add CI subfolder if location has CIs
        if HrzcmCi.for_location(location_id).exists?
          nodes << {
            id: "location_cis_#{location_id}",
            text: I18n.t('hrz_cmdb.cis.title'),
            icon: 'icon-folder',
            children: true,
            type: 'location_cis'
          }
        end

        # Add child locations
        HrzcmLocation.where('j_part_of1_id = ? OR j_part_of2_id = ?', location_id, location_id)
                     .ordered_by_b_name_abbr.each do |child|
          nodes << location_to_tree_node(child)
        end
      end
    end

    render json: nodes
  end  # tree_data

  # Shows details of a specific location.
  # Uses @location instance variable set by find_location before_action.
  # Returns: HTML partial or JSON representation
  def show_location
    respond_to do |format|
      format.html { render partial: 'location_details', locals: { location: @location, can_edit: can_edit? } }
      format.json { render json: @location }
    end
  end

  # Renders form for creating a new location.
  # Returns: HTML partial with new location form
  def new_location
    @location = HrzcmLocation.new
    render partial: 'location_form', locals: { location: @location, can_edit: can_edit? }
  end

  # Creates a new location from form parameters.
  # Parameter location (via params): Hash with location attributes
  # Returns: JSON with success status and created location ID, or error messages
  def create_location
    @location = HrzcmLocation.new(location_params)

    if @location.save
      render json: {
        success: true,
        id: @location.id,
        notice: I18n.t('hrz_cmdb.locations.created')
      }
    else
      render json: { success: false, errors: @location.errors.full_messages }
    end
  end

  # Updates an existing location with new attributes.
  # Uses @location instance variable set by find_location before_action.
  # Parameter location (via params): Hash with location attributes to update
  # Returns: JSON with success status and updated location ID, or error messages
  def update_location
    if @location.update(location_params)
      render json: {
        success: true,
        id: @location.id,
        notice: I18n.t('hrz_cmdb.locations.updated')
      }
    else
      render json: { success: false, errors: @location.errors.full_messages }
    end
  end

  # Deletes a location.
  # Uses @location instance variable set by find_location before_action.
  # Returns: JSON with success status or error messages
  def destroy_location
    if @location.destroy
      render json: {
        success: true,
        notice: I18n.t('hrz_cmdb.locations.deleted')
      }
    else
      render json: { success: false, errors: @location.errors.full_messages }
    end
  end

  # Shows details of a specific CI class.
  # Uses @ci_class instance variable set by find_ci_class before_action.
  # Returns: HTML partial or JSON representation
  def show_ci_class
    respond_to do |format|
      format.html { render partial: 'ci_class_details', locals: { ci_class: @ci_class, can_edit: can_edit_basic_data? } }
      format.json { render json: @ci_class }
    end
  end

  # Renders form for creating a new CI class.
  # Returns: HTML partial with new CI class form
  def new_ci_class
    @ci_class = HrzcmCiClass.new
    render partial: 'ci_class_form', locals: { ci_class: @ci_class, can_edit: can_edit_basic_data? }
  end

  # Creates a new CI class from form parameters.
  # Parameter ci_class (via params): Hash with CI class attributes
  # Returns: JSON with success status and created CI class ID, or error messages
  def create_ci_class
    @ci_class = HrzcmCiClass.new(ci_class_params)

    if @ci_class.save
      render json: {
        success: true,
        id: @ci_class.id,
        notice: I18n.t('hrz_cmdb.ci_classes.created')
      }
    else
      render json: { success: false, errors: @ci_class.errors.full_messages }
    end
  end

  # Updates an existing CI class with new attributes.
  # Uses @ci_class instance variable set by find_ci_class before_action.
  # Parameter ci_class (via params): Hash with CI class attributes to update
  # Returns: JSON with success status and updated CI class ID, or error messages
  def update_ci_class
    if @ci_class.update(ci_class_params)
      render json: {
        success: true,
        id: @ci_class.id,
        notice: I18n.t('hrz_cmdb.ci_classes.updated')
      }
    else
      render json: { success: false, errors: @ci_class.errors.full_messages }
    end
  end

  # Deletes a CI class.
  # Uses @ci_class instance variable set by find_ci_class before_action.
  # Returns: JSON with success status or error messages
  # Deletes a CI class if it has no associated CIs and no subclasses.
  # Uses @ci_class instance variable set by find_ci_class before_action.
  # Returns: JSON with success status if deletion successful, or error if CI class is in use
  def destroy_ci_class
    # Check if CI class has CIs
    if HrzcmCi.exists?(j_ci_class_id: @ci_class.id)
      render json: {
        success: false,
        error: I18n.t('hrz_cmdb.ci_classes.has_cis')
      }
      return
    end

    # Check if CI class has subclasses
    if HrzcmCiClass.exists?(j_subclass_of_id: @ci_class.id)
      render json: {
        success: false,
        error: I18n.t('hrz_cmdb.ci_classes.has_subclasses')
      }
      return
    end

    # Try to delete
    begin
      if @ci_class.destroy
        render json: {
          success: true,
          notice: I18n.t('hrz_cmdb.ci_classes.deleted')
        }
      else
        render json: { success: false, errors: @ci_class.errors.full_messages }
      end
    rescue ActiveRecord::InvalidForeignKey => e
      # Fallback for any foreign key constraint errors we didn't catch
      render json: {
        success: false,
        error: I18n.t('hrz_cmdb.ci_classes.cannot_delete_in_use')
      }
    end
  end

  # Shows details of a specific CI (Configuration Item).
  # Uses @ci instance variable set by find_ci before_action.
  # Returns: HTML partial or JSON representation
  def show_ci
    respond_to do |format|
      format.html { render partial: 'ci_details', locals: { ci: @ci, can_edit: can_edit? } }
      format.json { render json: @ci }
    end
  end

  # Renders form for creating a new CI.
  # Returns: HTML partial with new CI form
  def new_ci
    @ci = HrzcmCi.new
    render partial: 'ci_form', locals: { ci: @ci, can_edit: can_edit? }
  end

  # Creates a new CI from form parameters.
  # Parameter ci (via params): Hash with CI attributes
  # Returns: JSON with success status and created CI ID, or error messages
  def create_ci
    @ci = HrzcmCi.new(ci_params)

    if @ci.save
      render json: {
        success: true,
        id: @ci.id,
        notice: I18n.t('hrz_cmdb.cis.created')
      }
    else
      render json: { success: false, errors: @ci.errors.full_messages }
    end
  end

  # Updates an existing CI with new attributes.
  # Uses @ci instance variable set by find_ci before_action.
  # Parameter ci (via params): Hash with CI attributes to update
  # Returns: JSON with success status and updated CI ID, or error messages
  def update_ci
    if @ci.update(ci_params)
      render json: {
        success: true,
        id: @ci.id,
        notice: I18n.t('hrz_cmdb.cis.updated')
      }
    else
      render json: { success: false, errors: @ci.errors.full_messages }
    end
  end

  # Deletes a CI.
  # Uses @ci instance variable set by find_ci before_action.
  # Returns: JSON with success status or error messages
  def destroy_ci
    if @ci.destroy
      render json: {
        success: true,
        notice: I18n.t('hrz_cmdb.cis.deleted')
      }
    else
      render json: { success: false, errors: @ci.errors.full_messages }
    end
  end

  # Shows details of a specific lifecycle status.
  # Uses @lifecycle_status instance variable set by find_lifecycle_status before_action.
  # Returns: HTML partial or JSON representation
  def show_lifecycle_status
    respond_to do |format|
      format.html { render partial: 'lifecycle_status_details', locals: { lifecycle_status: @lifecycle_status, can_edit: can_edit_basic_data? } }
      format.json { render json: @lifecycle_status }
    end
  end

  # Renders form for creating a new lifecycle status.
  # Returns: HTML partial with new lifecycle status form
  def new_lifecycle_status
    @lifecycle_status = HrzcmLifecycleStatus.new
    render partial: 'lifecycle_status_form', locals: { lifecycle_status: @lifecycle_status, can_edit: can_edit_basic_data? }
  end

  # Creates a new lifecycle status from form parameters.
  # Parameter lifecycle_status (via params): Hash with lifecycle status attributes
  # Returns: JSON with success status and created lifecycle status ID, or error messages
  def create_lifecycle_status
    @lifecycle_status = HrzcmLifecycleStatus.new(lifecycle_status_params)

    if @lifecycle_status.save
      render json: {
        success: true,
        id: @lifecycle_status.id,
        notice: I18n.t('hrz_cmdb.lifecycle_statuses.created')
      }
    else
      render json: { success: false, errors: @lifecycle_status.errors.full_messages }
    end
  end

  # Updates an existing lifecycle status with new attributes.
  # Uses @lifecycle_status instance variable set by find_lifecycle_status before_action.
  # Parameter lifecycle_status (via params): Hash with lifecycle status attributes to update
  # Returns: JSON with success status and updated lifecycle status ID, or error messages
  def update_lifecycle_status
    if @lifecycle_status.update(lifecycle_status_params)
      render json: {
        success: true,
        id: @lifecycle_status.id,
        notice: I18n.t('hrz_cmdb.lifecycle_statuses.updated')
      }
    else
      render json: { success: false, errors: @lifecycle_status.errors.full_messages }
    end
  end

  # Deletes a lifecycle status.
  # Uses @lifecycle_status instance variable set by find_lifecycle_status before_action.
  # Returns: JSON with success status or error messages
  def destroy_lifecycle_status
    if @lifecycle_status.destroy
      render json: {
        success: true,
        notice: I18n.t('hrz_cmdb.lifecycle_statuses.deleted')
      }
    else
      render json: { success: false, errors: @lifecycle_status.errors.full_messages }
    end
  end

  # Shows details of a specific external system.
  # Uses @ext_sys instance variable set by find_ext_sys before_action.
  # Returns: HTML partial or JSON representation
  def show_ext_sys
    respond_to do |format|
      format.html { render partial: 'ext_sys_details', locals: { ext_sys: @ext_sys, can_edit: can_edit_basic_data? } }
      format.json { render json: @ext_sys }
    end
  end

  # Renders form for creating a new external system.
  # Returns: HTML partial with new external system form
  def new_ext_sys
    @ext_sys = HrzcmExtSys.new
    render partial: 'ext_sys_form', locals: { ext_sys: @ext_sys, can_edit: can_edit_basic_data? }
  end

  # Creates a new external system from form parameters.
  # Parameter ext_sys (via params): Hash with external system attributes
  # Returns: JSON with success status and created external system ID, or error messages
  def create_ext_sys
    @ext_sys = HrzcmExtSys.new(ext_sys_params)

    if @ext_sys.save
      render json: {
        success: true,
        id: @ext_sys.id,
        notice: I18n.t('hrz_cmdb.external_systems.created')
      }
    else
      render json: { success: false, errors: @ext_sys.errors.full_messages }
    end
  end

  # Updates an existing external system with new attributes.
  # Uses @ext_sys instance variable set by find_ext_sys before_action.
  # Parameter ext_sys (via params): Hash with external system attributes to update
  # Returns: JSON with success status and updated external system ID, or error messages
  def update_ext_sys
    if @ext_sys.update(ext_sys_params)
      render json: {
        success: true,
        id: @ext_sys.id,
        notice: I18n.t('hrz_cmdb.external_systems.updated')
      }
    else
      render json: { success: false, errors: @ext_sys.errors.full_messages }
    end
  end

  # Deletes an external system.
  # Uses @ext_sys instance variable set by find_ext_sys before_action.
  # Returns: JSON with success status or error messages
  def destroy_ext_sys
    if @ext_sys.destroy
      render json: {
        success: true,
        notice: I18n.t('hrz_cmdb.external_systems.deleted')
      }
    else
      render json: { success: false, errors: @ext_sys.errors.full_messages }
    end
  end

  private

  # Verifies current user has view_cmdb permission.
  # Called as before_action for all controller actions.
  # Denies access if user lacks required permission.
  def check_permissions
    unless can_view?
      deny_access
    end
  end

  # Verifies current user has edit_cmdb permission.
  # Called as before_action for location and CI modification actions.
  # Denies access if user lacks required permission.
  def check_edit_permissions
    unless can_edit?
      deny_access
    end
  end

  # Verifies current user has edit_basic_data permission.
  # Called as before_action for CI class, lifecycle status, and external system modification actions.
  # Denies access if user lacks required permission.
  def check_basic_data_permissions
    unless can_edit_basic_data?
      deny_access
    end
  end

  # Finds and loads a location by ID from params.
  # Called as before_action for show, update, and destroy location actions.
  # Parameter id (via params): Integer ID of the location to find
  # Sets: @location instance variable
  # Raises: Renders 404 if location not found
  def find_location
    @location = HrzcmLocation.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  # Finds and loads a CI class by ID from params.
  # Called as before_action for show, update, and destroy CI class actions.
  # Parameter id (via params): Integer ID of the CI class to find
  # Sets: @ci_class instance variable
  # Raises: Renders 404 if CI class not found
  def find_ci_class
    @ci_class = HrzcmCiClass.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  # Finds and loads a CI by ID from params.
  # Called as before_action for show, update, and destroy CI actions.
  # Parameter id (via params): Integer ID of the CI to find
  # Sets: @ci instance variable
  # Raises: Renders 404 if CI not found
  def find_ci
    @ci = HrzcmCi.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  # Finds and loads a lifecycle status by ID from params.
  # Called as before_action for show, update, and destroy lifecycle status actions.
  # Parameter id (via params): Integer ID of the lifecycle status to find
  # Sets: @lifecycle_status instance variable
  # Raises: Renders 404 if lifecycle status not found
  def find_lifecycle_status
    @lifecycle_status = HrzcmLifecycleStatus.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  # Finds and loads an external system by ID from params.
  # Called as before_action for show, update, and destroy external system actions.
  # Parameter id (via params): Integer ID of the external system to find
  # Sets: @ext_sys instance variable
  # Raises: Renders 404 if external system not found
  def find_ext_sys
    @ext_sys = HrzcmExtSys.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  # Strong parameters filter for location attributes.
  # Permits only whitelisted attributes for mass assignment.
  # Returns: ActionController::Parameters with permitted location attributes
  def location_params
    params.require(:location).permit(:b_name_full, :b_name_abbr, :b_comment,
                                     :b_url_doc, :j_type_id, :j_part_of1_id,
                                     :j_part_of2_id, :b_key)
  end

  # Strong parameters filter for CI class attributes.
  # Permits only whitelisted attributes for mass assignment.
  # Returns: ActionController::Parameters with permitted CI class attributes
  def ci_class_params
    params.require(:ci_class).permit(:b_name_full, :b_name_abbr, :b_comment,
                                     :b_url_doc, :b_key, :j_sort, :j_subclass_of_id)
  end

  # Strong parameters filter for CI attributes.
  # Permits only whitelisted attributes for mass assignment.
  # Returns: ActionController::Parameters with permitted CI attributes
  def ci_params
    params.require(:ci).permit(:b_name_full, :b_name_abbr, :b_comment,
                               :b_url_doc, :j_ci_class_id, :j_location_id,
                               :b_producer, :b_model, :b_tag_serial, :j_status_id)
  end

  # Strong parameters filter for lifecycle status attributes.
  # Permits only whitelisted attributes for mass assignment.
  # Returns: ActionController::Parameters with permitted lifecycle status attributes
  def lifecycle_status_params
    params.require(:lifecycle_status).permit(:b_name_full, :b_name_abbr, :b_comment,
                                             :b_url_doc, :b_key)
  end

  # Strong parameters filter for external system attributes.
  # Permits only whitelisted attributes for mass assignment.
  # Returns: ActionController::Parameters with permitted external system attributes
  def ext_sys_params
    params.require(:ext_sys).permit(:b_name_full, :b_name_abbr, :b_comment,
                                    :b_url_doc, :b_url_ci_details_ext, :j_redmine_user_id,
                                    :j_location_default_id)
  end

  # Converts a location to a jsTree node for the navigation tree.
  # Parameter location: HrzcmLocation instance to convert
  # Returns: Hash with jsTree node structure (id, text, icon, children, type, title)
  def location_to_tree_node(location)
    node = {
      id: location.id,
      text: location.tree_label,
      icon: location.has_children? ? 'icon-folder' : 'icon-page',
      children: location.has_children?,
      type: 'location'
    }
    # Only add title if b_name_full differs from b_name_abbr
    if location.b_name_full.present? && location.b_name_abbr.present? && location.b_name_full != location.b_name_abbr
      node[:title] = location.b_name_full
    end
    node
  end

  # Converts a CI class to a jsTree node for the basic data tree.
  # Parameter ci_class: HrzcmCiClass instance to convert
  # Returns: Hash with jsTree node structure (id, text, icon, children, type, title)
  def ci_class_to_tree_node(ci_class)
    node = {
      id: "ci_class_#{ci_class.id}",
      text: ci_class.tree_label,
      icon: ci_class.has_subclasses? ? 'icon-folder' : 'icon-page',
      children: ci_class.has_subclasses?,
      type: 'ci_class'
    }
    # Only add title if b_name_full differs from b_name_abbr
    if ci_class.b_name_full.present? && ci_class.b_name_abbr.present? && ci_class.b_name_full != ci_class.b_name_abbr
      node[:title] = ci_class.b_name_full
    end
    node
  end

  # Converts a CI to a jsTree node for the navigation tree.
  # Parameter ci: HrzcmCi instance to convert
  # Returns: Hash with jsTree node structure (id, text, icon, children, type, title)
  def ci_to_tree_node(ci)
    node = {
      id: "ci_#{ci.id}",
      text: ci.tree_label,
      icon: 'icon-page',
      children: false,
      type: 'ci'
    }
    # Only add title if b_name_full differs from b_name_abbr
    if ci.b_name_full.present? && ci.b_name_abbr.present? && ci.b_name_full != ci.b_name_abbr
      node[:title] = ci.b_name_full
    end
    node
  end

  # Converts a CI class to a jsTree node for the "CIs by Class" tree.
  # Parameter ci_class: HrzcmCiClass instance to convert
  # Returns: Hash with jsTree node structure (id, text, icon, children, type, title)
  # Note: Checks for subclasses and CIs to determine if node should have children
  def ci_class_for_ci_tree_node(ci_class)
    # Check if this CI class has subclasses or CIs
    has_children = ci_class.has_subclasses? || HrzcmCi.for_ci_class(ci_class.id).exists?

    node = {
      id: "ci_class_for_ci_#{ci_class.id}",
      text: ci_class.tree_label,
      icon: has_children ? 'icon-folder' : 'icon-page',
      children: has_children,
      type: 'ci_class_for_ci'
    }
    # Only add title if b_name_full differs from b_name_abbr
    if ci_class.b_name_full.present? && ci_class.b_name_abbr.present? && ci_class.b_name_full != ci_class.b_name_abbr
      node[:title] = ci_class.b_name_full
    end
    node
  end

  # Converts a lifecycle status to a jsTree node for the basic data tree.
  # Parameter lifecycle_status: HrzcmLifecycleStatus instance to convert
  # Returns: Hash with jsTree node structure (id, text, icon, children, type, title)
  def lifecycle_status_to_tree_node(lifecycle_status)
    node = {
      id: "lifecycle_status_#{lifecycle_status.id}",
      text: lifecycle_status.display_name,
      icon: 'icon-page',
      children: false,
      type: 'lifecycle_status'
    }
    # Only add title if b_name_full differs from b_name_abbr
    if lifecycle_status.b_name_full.present? && lifecycle_status.b_name_abbr.present? && lifecycle_status.b_name_full != lifecycle_status.b_name_abbr
      node[:title] = lifecycle_status.b_name_full
    end
    node
  end

  # Converts an external system to a jsTree node for the basic data tree.
  # Parameter ext_sys: HrzcmExtSys instance to convert
  # Returns: Hash with jsTree node structure (id, text, icon, children, type, title)
  def ext_sys_to_tree_node(ext_sys)
    node = {
      id: "ext_sys_#{ext_sys.id}",
      text: ext_sys.display_name,
      icon: 'icon-page',
      children: false,
      type: 'ext_sys'
    }
    # Only add title if b_name_full differs from b_name_abbr
    if ext_sys.b_name_full.present? && ext_sys.b_name_abbr.present? && ext_sys.b_name_full != ext_sys.b_name_abbr
      node[:title] = ext_sys.b_name_full
    end
    node
  end

  # Checks if current user has permission to view CMDB data.
  # Users with edit or edit_basic_data permissions can also view.
  # Returns: Boolean indicating if user has view access
  def can_view?
    # Users who can edit can also view
    HrzCmdb::PermissionHelper.user_has_permission?(User.current, 'view_cmdb') ||
    HrzCmdb::PermissionHelper.user_has_permission?(User.current, 'edit_cmdb') ||
    HrzCmdb::PermissionHelper.user_has_permission?(User.current, 'edit_basic_data')
  end

  # Checks if current user has permission to edit locations and CIs.
  # Returns: Boolean indicating if user has edit_cmdb permission
  def can_edit?
    HrzCmdb::PermissionHelper.user_has_permission?(User.current, 'edit_cmdb')
  end

  # Checks if current user has permission to edit basic data (CI classes, lifecycle statuses, external systems).
  # Returns: Boolean indicating if user has edit_basic_data permission
  def can_edit_basic_data?
    HrzCmdb::PermissionHelper.user_has_permission?(User.current, 'edit_basic_data')
  end
end
