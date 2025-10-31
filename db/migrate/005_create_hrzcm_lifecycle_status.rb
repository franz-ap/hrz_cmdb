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
# Purpose: Database migration creating the hrzcm_lifecycle_status table.
#          Stores lifecycle status definitions for tracking CI operational states (planning, active, decommissioned, etc.).

class CreateHrzcmLifecycleStatus < ActiveRecord::Migration[6.1]
  def change
    create_table :hrzcm_lifecycle_status do |t|
      t.string :b_key, null: false
      t.string :b_name_full, limit: 120
      t.string :b_name_abbr, limit: 15
      t.text :b_comment, limit: 10000
      t.string :b_url_doc, limit: 1500
      t.integer :created_by
      t.integer :updated_by

      t.timestamp :created_on
      t.timestamp :updated_on
    end

    add_index :hrzcm_lifecycle_status, :b_key, unique: true
    add_index :hrzcm_lifecycle_status, :created_by
    add_index :hrzcm_lifecycle_status, :updated_by
  end
end
