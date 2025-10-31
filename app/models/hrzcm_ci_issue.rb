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
# Purpose: Junction model connecting Configuration Items to Redmine issues.
#          Enables tracking which hardware/software items are affected by or related to specific tickets.

class HrzcmCiIssue < ActiveRecord::Base
  self.table_name = 'hrzcm_ci_issues'

  # Associations
  belongs_to :ci, class_name: 'HrzcmCi', foreign_key: 'ci_id'
  belongs_to :issue, class_name: 'Issue', foreign_key: 'issue_id'
  belongs_to :creator, class_name: 'User', foreign_key: 'created_by', optional: true

  # Validations
  validates :ci_id, presence: true
  validates :issue_id, presence: true
  validates :ci_id, uniqueness: { scope: :issue_id, message: 'is already linked to this issue' }

  # Callbacks
  before_create :set_creator

  private

  # Sets creator user ID and timestamp before record creation.
  # Called automatically before_create.
  # Sets: created_by from User.current, created_on to current time
  def set_creator
    self.created_by ||= User.current&.id
    self.created_on ||= Time.current
  end
end
