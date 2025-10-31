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
# Purpose: Database migration updating location unique index to include parent relationships.
#          Ensures location keys are unique within their type and parent context.

class UpdateHrzcmLocationUniqueIndex < ActiveRecord::Migration[6.1]
  def change
    # Remove old unique index
    remove_index :hrzcm_location, name: 'index_hrzcm_location_on_b_key_and_j_type_id'

    # Add new unique index including parent relationships
    add_index :hrzcm_location, [:b_key, :j_type_id, :j_part_of1_id, :j_part_of2_id],
              unique: true,
              name: 'index_hrzcm_location_on_b_key_and_type_and_parents'
  end
end
