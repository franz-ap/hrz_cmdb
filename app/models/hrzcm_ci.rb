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
# Purpose: Model for Configuration Items (CIs) - individual hardware/software inventory items.
#          Tracks physical and virtual assets with location, class, lifecycle status, and external system links.

class HrzcmCi < ActiveRecord::Base
  self.table_name = 'hrzcm_ci'

  # Associations
  belongs_to :ci_class, class_name: 'HrzcmCiClass', foreign_key: 'j_ci_class_id', optional: true
  belongs_to :location, class_name: 'HrzcmLocation', foreign_key: 'j_location_id', optional: true
  belongs_to :lifecycle_status, class_name: 'HrzcmLifecycleStatus', foreign_key: 'j_status_id', optional: true
  belongs_to :creator, class_name: 'User', foreign_key: 'created_by', optional: true
  belongs_to :updater, class_name: 'User', foreign_key: 'updated_by', optional: true

  has_many :ci_issues, class_name: 'HrzcmCiIssue', foreign_key: 'ci_id', dependent: :destroy
  has_many :issues, through: :ci_issues, class_name: 'Issue'

  has_many :ci_ext_mappings, class_name: 'HrzcmCiExt', foreign_key: 'j_ci_id', dependent: :destroy
  has_many :ext_systems, through: :ci_ext_mappings, source: :ext_sys, class_name: 'HrzcmExtSys'

  # Validations
  validates :j_ci_class_id, presence: true
  validates :b_name_full, length: { maximum: 120 }
  validates :b_name_abbr, length: { maximum: 50 }
  validates :b_comment, length: { maximum: 10000 }
  validates :b_url_doc, length: { maximum: 1500 }
  validates :b_producer, length: { maximum: 100 }
  validates :b_model, length: { maximum: 100 }
  validates :b_tag_serial, length: { maximum: 40 }

  # Scopes
  scope :ordered_by_abbr, -> { order(:b_name_abbr) }
  scope :for_location, ->(location_id) { where(j_location_id: location_id) }
  scope :for_ci_class, ->(ci_class_id) { where(j_ci_class_id: ci_class_id) }

  # Callbacks
  before_create :set_creator
  before_save :set_updater

  # Returns the display name for this CI, prioritizing abbreviated name.
  # Returns: String with b_name_abbr, b_name_full, or fallback "CI #id"
  def display_name
    b_name_abbr || b_name_full || "CI ##{id}"
  end

  # String representation of the CI using display_name.
  # Returns: String display name
  def to_s
    display_name
  end

  # Returns formatted label for tree display including CI class.
  # Returns: String with display name and CI class abbreviation in parentheses (if present)
  def tree_label
    label = display_name
    label += " (#{ci_class.b_name_abbr})" if ci_class
    label
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
