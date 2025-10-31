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
# Purpose: Model for external system integrations (e.g., asset management systems, monitoring tools).
#          Manages connections to third-party systems and URL templates for CI detail pages.

class HrzcmExtSys < ActiveRecord::Base
  self.table_name = 'hrzcm_ext_sys'

  # Associations
  belongs_to :redmine_user, class_name: 'User', foreign_key: 'j_redmine_user_id'
  belongs_to :location_default, class_name: 'HrzcmLocation', foreign_key: 'j_location_default_id', optional: true
  belongs_to :creator, class_name: 'User', foreign_key: 'created_by', optional: true
  belongs_to :updater, class_name: 'User', foreign_key: 'updated_by', optional: true

  has_many :ci_ext_mappings, class_name: 'HrzcmCiExt', foreign_key: 'j_ext_sys_id', dependent: :destroy
  has_many :cis, through: :ci_ext_mappings, class_name: 'HrzcmCi'

  # Validations
  validates :b_name_full, length: { maximum: 120 }
  validates :b_name_abbr, length: { maximum: 50 }
  validates :b_comment, length: { maximum: 10000 }
  validates :b_url_doc, length: { maximum: 1500 }
  validates :b_url_ci_details_ext, length: { maximum: 1500 }
  validates :j_redmine_user_id, presence: true, uniqueness: true

  # Scopes
  scope :ordered_by_abbr, -> { order(:b_name_abbr) }

  # Callbacks
  before_create :set_creator
  before_save :set_updater

  # Returns the display name for this external system.
  # Returns: String with b_name_abbr, b_name_full, or fallback "ExtSys #id"
  def display_name
    b_name_abbr || b_name_full || "ExtSys ##{id}"
  end

  # String representation of the external system using display_name.
  # Returns: String display name
  def to_s
    display_name
  end

  # Returns formatted label for tree display.
  # Returns: String display name
  def tree_label
    display_name
  end

  # Builds external CI detail URL by replacing placeholder with actual external key.
  # Parameter key_ext: String external system key for the CI
  # Returns: String URL with ${key_ext} placeholder replaced, or nil if URL template or key is blank
  def build_ci_detail_url(key_ext)
    # Replace ${key_ext} placeholder with actual key
    return nil if b_url_ci_details_ext.blank? || key_ext.blank?
    b_url_ci_details_ext.gsub('${key_ext}', key_ext)
  end

  private

  # Sets creator user ID and timestamp before record creation.
  # Called automatically before_create.
  # Sets: created_by from User.current, created_on to current time
  def set_creator
    self.created_by ||= User.current&.id
    self.created_on ||= Time.current
  end

  # Updates updater user ID and timestamp before record save.
  # Called automatically before_save.
  # Sets: updated_by from User.current, updated_on to current time
  def set_updater
    self.updated_by = User.current&.id if User.current
    self.updated_on = Time.current
  end
end
