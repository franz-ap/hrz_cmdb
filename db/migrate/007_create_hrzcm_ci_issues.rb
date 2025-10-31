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
# Purpose: Database migration creating the hrzcm_ci_issues junction table.
#          Links configuration items to Redmine issues for tracking affected assets in tickets.

class CreateHrzcmCiIssues < ActiveRecord::Migration[6.1]
  def change
    create_table :hrzcm_ci_issues do |t|
      t.bigint :ci_id, null: false
      t.integer :issue_id, null: false
      t.integer :created_by
      t.timestamp :created_on
    end

    add_foreign_key :hrzcm_ci_issues, :hrzcm_ci, column: :ci_id
    add_foreign_key :hrzcm_ci_issues, :issues, column: :issue_id

    add_index :hrzcm_ci_issues, :ci_id
    add_index :hrzcm_ci_issues, :issue_id
    add_index :hrzcm_ci_issues, [:ci_id, :issue_id], unique: true
    add_index :hrzcm_ci_issues, :created_by
  end
end
