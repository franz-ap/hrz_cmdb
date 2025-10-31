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
# Purpose: Unit tests for HrzcmCi model covering validations, associations, scopes, and methods.

require File.expand_path('../../test_helper', __FILE__)

class HrzcmCiTest < ActiveSupport::TestCase
  fixtures :hrzcm_ci_class, :hrzcm_location, :hrzcm_lifecycle_status, :hrzcm_ci

  # Test validations
  test "should validate presence of ci_class_id" do
    ci = HrzcmCi.new(
      b_name_full: 'Test CI',
      b_name_abbr: 'TST'
    )
    assert_not ci.valid?
    assert_includes ci.errors[:j_ci_class_id], "can't be blank"
  end

  test "should validate length of b_name_full" do
    ci = HrzcmCi.new(
      j_ci_class_id: 2,
      b_name_full: 'a' * 121
    )
    assert_not ci.valid?
    assert_includes ci.errors[:b_name_full], "is too long (maximum is 120 characters)"
  end

  test "should validate length of b_name_abbr" do
    ci = HrzcmCi.new(
      j_ci_class_id: 2,
      b_name_abbr: 'a' * 51
    )
    assert_not ci.valid?
    assert_includes ci.errors[:b_name_abbr], "is too long (maximum is 50 characters)"
  end

  test "should create valid CI with required fields" do
    ci = HrzcmCi.new(
      b_name_full: 'New Server',
      b_name_abbr: 'NS01',
      j_ci_class_id: 2
    )
    assert ci.valid?
    assert ci.save
  end

  # Test associations
  test "should belong to ci_class" do
    ci = HrzcmCi.find(1)
    assert_not_nil ci.ci_class
    assert_equal 2, ci.ci_class.id
    assert_equal 'Server', ci.ci_class.b_name_full
  end

  test "should belong to location" do
    ci = HrzcmCi.find(1)
    assert_not_nil ci.location
    assert_equal 3, ci.location.id
    assert_equal 'Room 101', ci.location.b_name_full
  end

  test "should belong to lifecycle_status" do
    ci = HrzcmCi.find(1)
    assert_not_nil ci.lifecycle_status
    assert_equal 2, ci.lifecycle_status.id
    assert_equal 'Active', ci.lifecycle_status.b_name_full
  end

  # Test scopes
  test "ordered_by_abbr scope should order by b_name_abbr" do
    cis = HrzcmCi.ordered_by_abbr.to_a
    assert_equal 'DB01', cis[0].b_name_abbr
    assert_equal 'WEB01', cis[1].b_name_abbr
    assert_equal 'WS01', cis[2].b_name_abbr
  end

  test "for_location scope should filter by location" do
    cis = HrzcmCi.for_location(3).to_a
    assert_equal 2, cis.count
    assert_includes cis.map(&:id), 1
    assert_includes cis.map(&:id), 2
  end

  test "for_ci_class scope should filter by CI class" do
    cis = HrzcmCi.for_ci_class(2).to_a  # servers
    assert_equal 2, cis.count
    assert_includes cis.map(&:id), 1
    assert_includes cis.map(&:id), 2
  end

  # Test instance methods
  test "display_name should return b_name_abbr if present" do
    ci = HrzcmCi.find(1)
    assert_equal 'WEB01', ci.display_name
  end

  test "display_name should return b_name_full if b_name_abbr is blank" do
    ci = HrzcmCi.find(1)
    ci.b_name_abbr = nil
    assert_equal 'Web Server 01', ci.display_name
  end

  test "display_name should return fallback if both names are blank" do
    ci = HrzcmCi.new(id: 999, j_ci_class_id: 2)
    ci.b_name_abbr = nil
    ci.b_name_full = nil
    assert_equal 'CI #999', ci.display_name
  end

  test "to_s should return display_name" do
    ci = HrzcmCi.find(1)
    assert_equal ci.display_name, ci.to_s
  end

  test "tree_label should include CI class abbreviation" do
    ci = HrzcmCi.find(1)
    assert_equal 'WEB01 (SRV)', ci.tree_label
  end

  test "tree_label should work without CI class" do
    ci = HrzcmCi.new(b_name_abbr: 'TEST', j_ci_class_id: 2)
    ci.ci_class = nil
    assert_equal 'TEST', ci.tree_label
  end

  # Test callbacks
  test "should set creator on create" do
    User.current = User.find(1)
    ci = HrzcmCi.create!(
      b_name_full: 'New CI',
      j_ci_class_id: 2
    )
    assert_equal 1, ci.created_by
    assert_not_nil ci.created_on
  end

  test "should set updater on save" do
    User.current = User.find(1)
    ci = HrzcmCi.find(1)
    ci.b_name_full = 'Updated Name'
    ci.save!
    assert_equal 1, ci.updated_by
    assert_not_nil ci.updated_on
  end
end
