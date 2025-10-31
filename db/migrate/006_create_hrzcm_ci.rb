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
# Purpose: Database migration creating the hrzcm_ci table.
#          Stores individual configuration items (hardware/software inventory) with links to location, class, and status.

class CreateHrzcmCi < ActiveRecord::Migration[6.1]
  def change
    create_table :hrzcm_ci do |t|
      t.string :b_name_full, limit: 120
      t.string :b_name_abbr, limit: 15
      t.text :b_comment, limit: 10000
      t.string :b_url_doc, limit: 1500
      t.bigint :j_ci_class_id
      t.bigint :j_location_id
      t.string :b_producer, limit: 100
      t.string :b_model, limit: 100
      t.string :b_tag_serial, limit: 40
      t.bigint :j_status_id
      t.integer :created_by
      t.integer :updated_by

      t.timestamp :created_on
      t.timestamp :updated_on
    end

    add_foreign_key :hrzcm_ci, :hrzcm_ci_class, column: :j_ci_class_id
    add_foreign_key :hrzcm_ci, :hrzcm_location, column: :j_location_id
    add_foreign_key :hrzcm_ci, :hrzcm_lifecycle_status, column: :j_status_id

    add_index :hrzcm_ci, :j_ci_class_id
    add_index :hrzcm_ci, :j_location_id
    add_index :hrzcm_ci, :j_status_id
    add_index :hrzcm_ci, :created_by
    add_index :hrzcm_ci, :updated_by
  end
end
