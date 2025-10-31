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
# Purpose: Database migration increasing CI abbreviated name field length from 15 to 50 characters.
#          Allows for longer CI abbreviations to better accommodate naming conventions.

class IncreaseHrzcmCiNameAbbrLimit < ActiveRecord::Migration[6.1]
  def up
    change_column :hrzcm_ci, :b_name_abbr, :string, limit: 50
  end

  def down
    change_column :hrzcm_ci, :b_name_abbr, :string, limit: 15
  end
end
