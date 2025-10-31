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
# Purpose: Unit tests for HrzcmLocation model covering validations, associations, hierarchy, and methods.

require File.expand_path('../../test_helper', __FILE__)

class HrzcmLocationTest < ActiveSupport::TestCase
  fixtures :hrzcm_locat_hier, :hrzcm_location

  # Test validations
  test "should validate presence of j_type_id" do
    location = HrzcmLocation.new(
      b_name_full: 'Test Location',
      b_name_abbr: 'TST'
    )
    assert_not location.valid?
    assert_includes location.errors[:j_type_id], "can't be blank"
  end

  test "should validate length of b_name_full" do
    location = HrzcmLocation.new(
      j_type_id: 1,
      b_name_full: 'a' * 121
    )
    assert_not location.valid?
    assert_includes location.errors[:b_name_full], "is too long (maximum is 120 characters)"
  end

  test "should validate length of b_name_abbr" do
    location = HrzcmLocation.new(
      j_type_id: 1,
      b_name_abbr: 'a' * 16
    )
    assert_not location.valid?
    assert_includes location.errors[:b_name_abbr], "is too long (maximum is 15 characters)"
  end

  test "should create valid location with required fields" do
    location = HrzcmLocation.new(
      b_name_full: 'New Building',
      b_name_abbr: 'NB',
      j_type_id: 1
    )
    assert location.valid?
    assert location.save
  end

  # Test associations
  test "should belong to location_type" do
    location = HrzcmLocation.find(1)
    assert_not_nil location.location_type
    assert_equal 1, location.location_type.id
    assert_equal 'Building', location.location_type.b_name_full
  end

  test "should have parent1 association" do
    location = HrzcmLocation.find(2)  # first_floor
    assert_not_nil location.parent1
    assert_equal 1, location.parent1.id
    assert_equal 'Main Building', location.parent1.b_name_full
  end

  test "should have children" do
    building = HrzcmLocation.find(1)  # main_building
    children = building.children
    assert_equal 1, children.count
    assert_includes children.map(&:id), 2
  end

  # Test scopes
  test "root_locations scope should return locations without parents" do
    roots = HrzcmLocation.root_locations.to_a
    assert_equal 1, roots.count
    assert_equal 1, roots.first.id
  end

  test "ordered_by_b_name_abbr scope should order by abbreviation" do
    locations = HrzcmLocation.ordered_by_b_name_abbr.to_a
    assert_equal '101', locations[0].b_name_abbr
    assert_equal '102', locations[1].b_name_abbr
    assert_equal '1F', locations[2].b_name_abbr
  end

  test "for_type scope should filter by location type" do
    rooms = HrzcmLocation.for_type(3).to_a  # room type
    assert_equal 2, rooms.count
    assert_includes rooms.map(&:id), 3
    assert_includes rooms.map(&:id), 4
  end

  # Test instance methods
  test "display_name should include type prefix" do
    location = HrzcmLocation.find(1)
    assert_equal 'BLD: MB', location.display_name
  end

  test "has_children? should return true for location with children" do
    building = HrzcmLocation.find(1)
    assert building.has_children?
  end

  test "has_children? should return false for location without children" do
    room = HrzcmLocation.find(3)
    assert_not room.has_children?
  end

  test "parents should return array of parent locations" do
    floor = HrzcmLocation.find(2)
    parents = floor.parents
    assert_equal 1, parents.count
    assert_equal 1, parents.first.id
  end

  test "to_s should return abbreviation or name" do
    location = HrzcmLocation.find(1)
    assert_equal 'MB', location.to_s
  end

  test "tree_label should include type and name" do
    location = HrzcmLocation.find(1)
    assert_equal 'BLD: MB', location.tree_label
  end

  # Test callbacks
  test "should normalize b_key to nil if blank" do
    location = HrzcmLocation.create!(
      b_name_full: 'Test',
      b_name_abbr: 'TST',
      j_type_id: 1,
      b_key: ''
    )
    assert_nil location.b_key
  end

  test "should set creator on create" do
    User.current = User.find(1)
    location = HrzcmLocation.create!(
      b_name_full: 'New Location',
      b_name_abbr: 'NL',
      j_type_id: 1
    )
    assert_equal 1, location.created_by
    assert_not_nil location.created_on
  end
end
