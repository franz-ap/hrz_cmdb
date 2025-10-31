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
# Purpose: Junction model linking CIs to external systems with external key references.
#          Maps internal CIs to their identifiers in external inventory/management systems.

class HrzcmCiExt < ActiveRecord::Base
  self.table_name = 'hrzcm_ci_ext'
  self.primary_key = [:j_ci_id, :j_ext_sys_id, :b_key_ext]

  # Associations
  belongs_to :ci, class_name: 'HrzcmCi', foreign_key: 'j_ci_id'
  belongs_to :ext_sys, class_name: 'HrzcmExtSys', foreign_key: 'j_ext_sys_id'

  # Validations
  validates :b_key_ext, presence: true, length: { maximum: 50 }
  validates :j_ci_id, presence: true
  validates :j_ext_sys_id, presence: true

  # Validate uniqueness of composite key (since Rails doesn't automatically do this for composite keys)
  validates :b_key_ext, uniqueness: { scope: [:j_ci_id, :j_ext_sys_id] }

  # Builds the external system's CI detail URL using this mapping's external key.
  # Returns: String URL to CI details in external system, or nil if external system not present
  def external_detail_url
    ext_sys&.build_ci_detail_url(b_key_ext)
  end
end
