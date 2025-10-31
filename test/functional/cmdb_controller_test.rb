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
# Purpose: Functional tests for CmdbController covering CRUD operations, permissions, and JSON responses.

require File.expand_path('../../test_helper', __FILE__)

class CmdbControllerTest < ActionController::TestCase
  fixtures :users, :hrzcm_ci_class, :hrzcm_location, :hrzcm_lifecycle_status, :hrzcm_ci, :hrzcm_locat_hier

  def setup
    @user_with_view = user_with_cmdb_permission('view_cmdb')
    @user_with_edit = user_with_cmdb_permission('edit_cmdb')
    @user_without_permission = user_without_cmdb_permission
    @admin = User.find(1)
  end

  def teardown
    Setting.plugin_hrz_cmdb = {}
  end

  # Test index action
  test "should get index with view permission" do
    @request.session[:user_id] = @user_with_view.id
    get :index
    assert_response :success
    assert_template :index
  end

  test "should deny index without permission" do
    @request.session[:user_id] = @user_without_permission.id
    get :index
    assert_response :forbidden
  end

  test "admin should always access index" do
    @request.session[:user_id] = @admin.id
    get :index
    assert_response :success
  end

  # Test tree_data action
  test "should get tree_data for root level" do
    @request.session[:user_id] = @user_with_view.id
    get :tree_data, format: :json
    assert_response :success

    json = JSON.parse(response.body)
    assert json.is_a?(Array)
    assert json.any? { |node| node['id'] == 'cis_by_class' }
  end

  test "should get tree_data for location hierarchy" do
    @request.session[:user_id] = @user_with_view.id
    get :tree_data, params: { parent_id: 'location_hierarchy' }, format: :json
    assert_response :success

    json = JSON.parse(response.body)
    assert json.is_a?(Array)
  end

  test "should get tree_data for CI classes" do
    @request.session[:user_id] = @user_with_view.id
    get :tree_data, params: { parent_id: 'ci_classes' }, format: :json
    assert_response :success

    json = JSON.parse(response.body)
    assert json.is_a?(Array)
  end

  # Test CI CRUD operations
  test "should show ci with view permission" do
    @request.session[:user_id] = @user_with_view.id
    get :show_ci, params: { id: 1 }, format: :html
    assert_response :success
  end

  test "should create ci with edit permission" do
    @request.session[:user_id] = @user_with_edit.id

    assert_difference 'HrzcmCi.count', 1 do
      post :create_ci, params: {
        ci: {
          b_name_full: 'Test Server',
          b_name_abbr: 'TST01',
          j_ci_class_id: 2,
          j_location_id: 3
        }
      }, format: :json
    end

    assert_response :success
    json = JSON.parse(response.body)
    assert json['success']
    assert_not_nil json['id']
  end

  test "should not create ci without edit permission" do
    @request.session[:user_id] = @user_with_view.id

    assert_no_difference 'HrzcmCi.count' do
      post :create_ci, params: {
        ci: {
          b_name_full: 'Test Server',
          j_ci_class_id: 2
        }
      }, format: :json
    end

    assert_response :forbidden
  end

  test "should not create ci without required ci_class_id" do
    @request.session[:user_id] = @user_with_edit.id

    assert_no_difference 'HrzcmCi.count' do
      post :create_ci, params: {
        ci: {
          b_name_full: 'Test Server'
        }
      }, format: :json
    end

    assert_response :success
    json = JSON.parse(response.body)
    assert_not json['success']
    assert json['errors']
  end

  test "should update ci with edit permission" do
    @request.session[:user_id] = @user_with_edit.id

    put :update_ci, params: {
      id: 1,
      ci: {
        b_name_full: 'Updated Server'
      }
    }, format: :json

    assert_response :success
    json = JSON.parse(response.body)
    assert json['success']

    ci = HrzcmCi.find(1)
    assert_equal 'Updated Server', ci.b_name_full
  end

  test "should destroy ci with edit permission" do
    @request.session[:user_id] = @user_with_edit.id

    assert_difference 'HrzcmCi.count', -1 do
      delete :destroy_ci, params: { id: 1 }, format: :json
    end

    assert_response :success
    json = JSON.parse(response.body)
    assert json['success']
  end

  # Test Location CRUD operations
  test "should create location with edit permission" do
    @request.session[:user_id] = @user_with_edit.id

    assert_difference 'HrzcmLocation.count', 1 do
      post :create_location, params: {
        location: {
          b_name_full: 'Test Building',
          b_name_abbr: 'TB',
          j_type_id: 1
        }
      }, format: :json
    end

    assert_response :success
    json = JSON.parse(response.body)
    assert json['success']
  end

  test "should update location with edit permission" do
    @request.session[:user_id] = @user_with_edit.id

    put :update_location, params: {
      id: 1,
      location: {
        b_name_full: 'Updated Building'
      }
    }, format: :json

    assert_response :success
    json = JSON.parse(response.body)
    assert json['success']
  end

  # Test CI Class operations (require edit_basic_data permission)
  test "should not create ci_class with only edit_cmdb permission" do
    @request.session[:user_id] = @user_with_edit.id

    assert_no_difference 'HrzcmCiClass.count' do
      post :create_ci_class, params: {
        ci_class: {
          b_name_full: 'Test Class',
          b_name_abbr: 'TST',
          b_key: 'test'
        }
      }, format: :json
    end

    assert_response :forbidden
  end

  test "should create ci_class with edit_basic_data permission" do
    user_with_basic_data = user_with_cmdb_permission('edit_basic_data')
    @request.session[:user_id] = user_with_basic_data.id

    assert_difference 'HrzcmCiClass.count', 1 do
      post :create_ci_class, params: {
        ci_class: {
          b_name_full: 'Test Class',
          b_name_abbr: 'TST',
          b_key: 'test_class',
          j_sort: 50
        }
      }, format: :json
    end

    assert_response :success
    json = JSON.parse(response.body)
    assert json['success']
  end

  # Test lifecycle status operations
  test "should create lifecycle_status with edit_basic_data permission" do
    user_with_basic_data = user_with_cmdb_permission('edit_basic_data')
    @request.session[:user_id] = user_with_basic_data.id

    assert_difference 'HrzcmLifecycleStatus.count', 1 do
      post :create_lifecycle_status, params: {
        lifecycle_status: {
          b_name_full: 'Test Status',
          b_name_abbr: 'TST',
          b_key: 'test_status'
        }
      }, format: :json
    end

    assert_response :success
    json = JSON.parse(response.body)
    assert json['success']
  end
end
