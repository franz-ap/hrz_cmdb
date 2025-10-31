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
# Purpose: Database migration adding NOT NULL constraint to j_ci_class_id column.
#          Ensures that all CIs must have a CI class assigned, enforcing referential integrity.

class AddNotNullConstraintToCiClassId < ActiveRecord::Migration[6.1]
  def up
    # First, update any existing CIs that have NULL j_ci_class_id
    # This shouldn't happen in practice, but we handle it to avoid migration failure
    execute <<-SQL
      UPDATE hrzcm_ci
      SET j_ci_class_id = (SELECT id FROM hrzcm_ci_class ORDER BY id LIMIT 1)
      WHERE j_ci_class_id IS NULL
    SQL

    # Add NOT NULL constraint
    change_column_null :hrzcm_ci, :j_ci_class_id, false
  end

  def down
    # Remove NOT NULL constraint
    change_column_null :hrzcm_ci, :j_ci_class_id, true
  end
end
