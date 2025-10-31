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
# Purpose: Database migration creating the hrzcm_location table.
#          Stores physical/logical locations with dual-parent support for flexible hierarchical relationships.

class CreateHrzcmLocation < ActiveRecord::Migration[6.1]
  def change
    create_table :hrzcm_location do |t|
      t.string :b_name_full, limit: 120
      t.string :b_name_abbr, limit: 15
      t.text :b_comment, limit: 10000
      t.string :b_url_doc, limit: 1500
      t.bigint :j_type_id
      t.bigint :j_part_of1_id
      t.bigint :j_part_of2_id
      t.string :b_key
      t.integer :created_by
      t.integer :updated_by

      t.timestamp :created_on
      t.timestamp :updated_on
    end

    add_foreign_key :hrzcm_location, :hrzcm_locat_hier, column: :j_type_id
    add_foreign_key :hrzcm_location, :hrzcm_location, column: :j_part_of1_id
    add_foreign_key :hrzcm_location, :hrzcm_location, column: :j_part_of2_id

    add_index :hrzcm_location, [:b_key, :j_type_id], unique: true
    add_index :hrzcm_location, :j_type_id
    add_index :hrzcm_location, :j_part_of1_id
    add_index :hrzcm_location, :j_part_of2_id
    add_index :hrzcm_location, :created_by
    add_index :hrzcm_location, :updated_by
  end
end