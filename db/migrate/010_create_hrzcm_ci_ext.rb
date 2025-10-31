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
# Purpose: Database migration creating the hrzcm_ci_ext junction table with composite primary key.
#          Maps CIs to their identifiers in external systems for cross-system integration.

class CreateHrzcmCiExt < ActiveRecord::Migration[6.1]
  def change
    create_table :hrzcm_ci_ext, id: false do |t|
      t.bigint :j_ci_id, null: false
      t.bigint :j_ext_sys_id, null: false
      t.string :b_key_ext, limit: 50, null: false
    end

    add_foreign_key :hrzcm_ci_ext, :hrzcm_ci, column: :j_ci_id
    add_foreign_key :hrzcm_ci_ext, :hrzcm_ext_sys, column: :j_ext_sys_id

    # Composite primary key
    execute "ALTER TABLE hrzcm_ci_ext ADD PRIMARY KEY (j_ci_id, j_ext_sys_id, b_key_ext)"

    add_index :hrzcm_ci_ext, :j_ci_id
    add_index :hrzcm_ci_ext, :j_ext_sys_id
    add_index :hrzcm_ci_ext, [:j_ext_sys_id, :b_key_ext], name: 'index_hrzcm_ci_ext_on_ext_sys_and_key'
  end
end
