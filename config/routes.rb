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
# Purpose: Route definitions for the CMDB plugin.
#          Defines RESTful routes for locations, CI classes, CIs, lifecycle statuses, external systems,
#          location hierarchy management, and CI-Issue associations.

Rails.application.routes.draw do
  # CMDB main routes
  resources :cmdb do
    collection do
      get 'tree_data'
      get 'info'
      get 'new_location', action: :new_location
      get 'location/:id', action: :show_location, as: :show_location
      post 'location', action: :create_location
      put 'location/:id', action: :update_location
      delete 'location/:id', action: :destroy_location
      get 'new_ci_class', action: :new_ci_class
      get 'ci_class/:id', action: :show_ci_class, as: :show_ci_class
      post 'ci_classes', action: :create_ci_class
      put 'ci_classes/:id', action: :update_ci_class
      delete 'ci_classes/:id', action: :destroy_ci_class
      get 'new_ci', action: :new_ci
      get 'ci/:id', action: :show_ci, as: :show_ci
      post 'cis', action: :create_ci
      put 'cis/:id', action: :update_ci
      delete 'cis/:id', action: :destroy_ci
      get 'new_lifecycle_status', action: :new_lifecycle_status
      get 'lifecycle_status/:id', action: :show_lifecycle_status, as: :show_lifecycle_status
      post 'lifecycle_statuses', action: :create_lifecycle_status
      put 'lifecycle_statuses/:id', action: :update_lifecycle_status
      delete 'lifecycle_statuses/:id', action: :destroy_lifecycle_status
      get 'new_ext_sys', action: :new_ext_sys
      get 'ext_sys/:id', action: :show_ext_sys, as: :show_ext_sys
      post 'external_systems', action: :create_ext_sys
      put 'external_systems/:id', action: :update_ext_sys
      delete 'external_systems/:id', action: :destroy_ext_sys
    end
  end

  # Basic data routes (without namespace)
  scope :cmdb_basic_data do
    get '/', to: 'cmdb_basic_data#index', as: :cmdb_basic_data
    get '/location_hierarchies/new_hierarchy', to: 'cmdb_basic_data#new_hierarchy', as: :new_cmdb_basic_data_hierarchy
    get '/location_hierarchies/:id', to: 'cmdb_basic_data#show', as: :cmdb_basic_data_location_hierarchy
    post '/location_hierarchies', to: 'cmdb_basic_data#create', as: :cmdb_basic_data_location_hierarchies
    put '/location_hierarchies/:id', to: 'cmdb_basic_data#update'
    delete '/location_hierarchies/:id', to: 'cmdb_basic_data#destroy'

    # Seed data management routes
    get '/seed_data_management', to: 'cmdb_basic_data#show_seed_data_management', as: :seed_data_management_cmdb_basic_data
    post '/seed_data/add', to: 'cmdb_basic_data#add_seed_data', as: :add_seed_data_cmdb_basic_data
    post '/seed_data/remove_unused', to: 'cmdb_basic_data#remove_unused_seed_data', as: :remove_unused_seed_data_cmdb_basic_data
  end

  # CI-Issue integration routes
  resources :issues, only: [] do
    get 'cis/available', to: 'issue_cis#available_cis', as: :available_cis
    resources :cis, controller: 'issue_cis', only: [:create, :destroy]
  end
end