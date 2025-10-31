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
# Purpose: Unit tests for HrzCmdb::PermissionHelper covering group-based permission checks.

require File.expand_path('../../test_helper', __FILE__)

class PermissionHelperTest < ActiveSupport::TestCase
  fixtures :users, :groups_users

  def setup
    @user = User.find(2)  # jsmith
    @admin = User.find(1)  # admin
    @group = Group.create!(lastname: 'Test Permission Group')
    @group.users << @user
  end

  def teardown
    # Clean up plugin settings after each test
    Setting.plugin_hrz_cmdb = {}
  end

  # Test user_has_permission?
  test "should return false for nil user" do
    result = HrzCmdb::PermissionHelper.user_has_permission?(nil, 'view_cmdb')
    assert_not result
  end

  test "should return false for invalid permission type" do
    result = HrzCmdb::PermissionHelper.user_has_permission?(@user, 'invalid_permission')
    assert_not result
  end

  test "should return true for admin users regardless of groups" do
    result = HrzCmdb::PermissionHelper.user_has_permission?(@admin, 'view_cmdb')
    assert result

    result = HrzCmdb::PermissionHelper.user_has_permission?(@admin, 'edit_cmdb')
    assert result

    result = HrzCmdb::PermissionHelper.user_has_permission?(@admin, 'edit_basic_data')
    assert result
  end

  test "should return true when user belongs to authorized group" do
    Setting.plugin_hrz_cmdb = {
      'view_cmdb_groups' => [@group.id.to_s]
    }

    result = HrzCmdb::PermissionHelper.user_has_permission?(@user, 'view_cmdb')
    assert result
  end

  test "should return false when user does not belong to authorized group" do
    other_group = Group.create!(lastname: 'Other Group')
    Setting.plugin_hrz_cmdb = {
      'view_cmdb_groups' => [other_group.id.to_s]
    }

    result = HrzCmdb::PermissionHelper.user_has_permission?(@user, 'view_cmdb')
    assert_not result
  end

  test "should return false when no groups configured for permission" do
    Setting.plugin_hrz_cmdb = {}

    result = HrzCmdb::PermissionHelper.user_has_permission?(@user, 'view_cmdb')
    assert_not result
  end

  test "should handle multiple groups in settings" do
    group1 = Group.create!(lastname: 'Group 1')
    group2 = Group.create!(lastname: 'Group 2')
    group2.users << @user

    Setting.plugin_hrz_cmdb = {
      'edit_cmdb_groups' => [group1.id.to_s, group2.id.to_s]
    }

    result = HrzCmdb::PermissionHelper.user_has_permission?(@user, 'edit_cmdb')
    assert result
  end

  # Test groups_for_permission
  test "should return empty array for invalid permission type" do
    result = HrzCmdb::PermissionHelper.groups_for_permission('invalid')
    assert_equal [], result
  end

  test "should return group IDs for permission" do
    Setting.plugin_hrz_cmdb = {
      'view_cmdb_groups' => [@group.id.to_s, '99']
    }

    result = HrzCmdb::PermissionHelper.groups_for_permission('view_cmdb')
    assert_equal 2, result.count
    assert_includes result, @group.id
    assert_includes result, 99
  end

  test "should return empty array when no groups configured" do
    Setting.plugin_hrz_cmdb = {}

    result = HrzCmdb::PermissionHelper.groups_for_permission('edit_basic_data')
    assert_equal [], result
  end

  # Test groups_with_permission
  test "should return Group objects for permission" do
    Setting.plugin_hrz_cmdb = {
      'edit_cmdb_groups' => [@group.id.to_s]
    }

    result = HrzCmdb::PermissionHelper.groups_with_permission('edit_cmdb')
    assert_equal 1, result.count
    assert_equal @group.id, result.first.id
    assert_instance_of Group, result.first
  end

  test "should filter out non-existent group IDs" do
    Setting.plugin_hrz_cmdb = {
      'view_cmdb_groups' => [@group.id.to_s, '99999']
    }

    result = HrzCmdb::PermissionHelper.groups_with_permission('view_cmdb')
    assert_equal 1, result.count
    assert_equal @group.id, result.first.id
  end

  # Test all three permission types
  test "should work with view_cmdb permission" do
    Setting.plugin_hrz_cmdb = {
      'view_cmdb_groups' => [@group.id.to_s]
    }

    assert HrzCmdb::PermissionHelper.user_has_permission?(@user, 'view_cmdb')
  end

  test "should work with edit_cmdb permission" do
    Setting.plugin_hrz_cmdb = {
      'edit_cmdb_groups' => [@group.id.to_s]
    }

    assert HrzCmdb::PermissionHelper.user_has_permission?(@user, 'edit_cmdb')
  end

  test "should work with edit_basic_data permission" do
    Setting.plugin_hrz_cmdb = {
      'edit_basic_data_groups' => [@group.id.to_s]
    }

    assert HrzCmdb::PermissionHelper.user_has_permission?(@user, 'edit_basic_data')
  end
end
