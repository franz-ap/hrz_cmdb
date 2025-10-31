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
# Purpose: Model for CI (Configuration Item) classes in a hierarchical tree structure.
#          Defines categories/types of configuration items (e.g., servers, workstations, software).

class HrzcmCiClass < ActiveRecord::Base
  self.table_name = 'hrzcm_ci_class'

  # Associations
  belongs_to :parent_class, class_name: 'HrzcmCiClass', foreign_key: 'j_subclass_of_id', optional: true
  has_many :subclasses, class_name: 'HrzcmCiClass', foreign_key: 'j_subclass_of_id', dependent: :restrict_with_error
  belongs_to :creator, class_name: 'User', foreign_key: 'created_by', optional: true
  belongs_to :updater, class_name: 'User', foreign_key: 'updated_by', optional: true

  # Validations
  validates :b_name_full, length: { maximum: 120 }
  validates :b_name_abbr, length: { maximum: 15 }
  validates :b_comment, length: { maximum: 10000 }
  validates :b_url_doc, length: { maximum: 1500 }
  validates :b_key, presence: true, uniqueness: true
  validates :j_sort, numericality: { only_integer: true }

  # Scopes
  scope :root_classes, -> { where(j_subclass_of_id: nil) }
  scope :ordered_by_sort_and_abbr, -> { order(:j_sort, :b_name_abbr) }
  scope :for_parent, ->(parent_id) { where(j_subclass_of_id: parent_id) }

  # Callbacks
  before_create :set_creator
  before_save :set_updater

  # Returns the display name for this CI class.
  # Returns: String with b_name_abbr, b_name_full, or b_key as fallback
  def display_name
    b_name_abbr || b_name_full || b_key
  end

  # Checks if CI class has any subclasses.
  # Returns: Boolean indicating if subclasses exist
  def has_subclasses?
    subclasses.exists?
  end

  # String representation of the CI class.
  # Returns: String with b_name_abbr, b_name_full, or b_key as fallback
  def to_s
    b_name_abbr || b_name_full || b_key
  end

  # Returns formatted label for tree display.
  # Returns: String with b_name_abbr or b_name_full
  def tree_label
    b_name_abbr || b_name_full
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
