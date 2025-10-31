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
# Purpose: Model for physical/logical locations in a hierarchical structure with dual-parent support.
#          Represents buildings, rooms, racks, etc. where configuration items are located.

class HrzcmLocation < ActiveRecord::Base
  self.table_name = 'hrzcm_location'

  # Associations
  belongs_to :location_type, class_name: 'HrzcmLocatHier', foreign_key: 'j_type_id'
  belongs_to :parent1, class_name: 'HrzcmLocation', foreign_key: 'j_part_of1_id', optional: true
  belongs_to :parent2, class_name: 'HrzcmLocation', foreign_key: 'j_part_of2_id', optional: true
  has_many :children1, class_name: 'HrzcmLocation', foreign_key: 'j_part_of1_id', dependent: :restrict_with_error
  has_many :children2, class_name: 'HrzcmLocation', foreign_key: 'j_part_of2_id', dependent: :restrict_with_error
  belongs_to :creator, class_name: 'User', foreign_key: 'created_by', optional: true
  belongs_to :updater, class_name: 'User', foreign_key: 'updated_by', optional: true

  # Validations
  validates :b_name_full, length: { maximum: 120 }
  validates :b_name_abbr, length: { maximum: 15 }
  validates :b_comment, length: { maximum: 10000 }
  validates :b_url_doc, length: { maximum: 1500 }
  validates :j_type_id, presence: true
  validate :unique_b_key_with_type

  # Scopes
  scope :root_locations, -> { where(j_part_of1_id: nil, j_part_of2_id: nil) }
  scope :ordered_by_b_name_abbr, -> { order(:b_name_abbr) }
  scope :for_type, ->(type_id) { where(j_type_id: type_id) }

  # Callbacks
  before_validation :normalize_b_key
  before_create :set_creator
  before_save :set_updater

  # Returns formatted display name with location type prefix.
  # Returns: String in format "TYPE: name" using type abbreviation and location name
  def display_name
    type_prefix = location_type&.b_name_abbr || ''
    "#{type_prefix}: #{b_name_abbr || b_name_full}"
  end

  # Returns all child locations from both parent relationships.
  # Returns: Array of unique HrzcmLocation instances (children from j_part_of1_id and j_part_of2_id)
  def children
    # Returns all children (from both parent relationships)
    (children1.to_a + children2.to_a).uniq
  end

  # Checks if location has any child locations.
  # Returns: Boolean indicating if children exist in either parent relationship
  def has_children?
    children1.exists? || children2.exists?
  end

  # Returns all parent locations (up to 2).
  # Returns: Array of HrzcmLocation instances (compact removes nils)
  def parents
    [parent1, parent2].compact
  end

  # String representation of the location.
  # Returns: String with b_name_abbr, b_name_full, or b_key as fallback
  def to_s
    b_name_abbr || b_name_full || b_key
  end

  # Returns formatted label for tree display with type abbreviation.
  # Returns: String in format "TYPE: name"
  def tree_label
    "#{location_type.b_name_abbr}: #{b_name_abbr || b_name_full}"
  end

  private

  # Normalizes b_key by converting empty strings to nil.
  # Called automatically before_validation.
  # Prevents unique constraint violations from empty string values.
  def normalize_b_key
    # Convert empty strings to nil to avoid unique constraint violations
    self.b_key = nil if b_key.blank?
  end

  # Validates uniqueness of b_key within type and parent context.
  # Called automatically during validation.
  # Adds error if duplicate b_key exists for same type and parent combination.
  def unique_b_key_with_type
    if b_key.present? && j_type_id.present?
      existing = HrzcmLocation.where(
        b_key: b_key,
        j_type_id: j_type_id,
        j_part_of1_id: j_part_of1_id,
        j_part_of2_id: j_part_of2_id
      )
      existing = existing.where.not(id: id) if persisted?
      if existing.exists?
        errors.add(:b_key, I18n.t('hrz_cmdb.errors.b_key_not_unique_for_type'))
      end
    end
  end

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