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
# Purpose: Seed data definitions for CMDB basic data with hierarchical structure.
#          Provides default data sets for location hierarchy, CI classes, and lifecycle statuses.

module HrzCmdb
  class SeedData
    # Location Hierarchy using OpenStreetMap admin_level schema
    # Hierarchy from top to bottom (root to leaf)
    LOCATION_HIERARCHY = [
      { b_key: 'admin_level__2', b_name_full: 'Country', b_name_abbr: 'Ctry.',      j_level:  20, b_comment: 'Country level (OpenStreetMap admin_level 2)' },
      { b_key: 'admin_level__4', b_name_full: 'State/Region', b_name_abbr: 'State', j_level:  40, b_comment: 'State/Province level (OpenStreetMap admin_level 4)' },
      { b_key: 'admin_level__6', b_name_full: 'District',     b_name_abbr: 'Dist.', j_level:  60, b_comment: 'District level (OpenStreetMap admin_level 6)' },
      { b_key: 'admin_level__8', b_name_full: 'City',         b_name_abbr: 'City',  j_level:  80, b_comment: 'City/Municipality level (OpenStreetMap admin_level 8)' },
      { b_key: 'building',       b_name_full: 'Building',     b_name_abbr: 'Bld.',  j_level: 200, b_comment: 'Building' },
      { b_key: 'floor',          b_name_full: 'Floor',        b_name_abbr: 'Flr.',  j_level: 210, b_comment: 'Floor within building' },
      { b_key: 'room',           b_name_full: 'Room',         b_name_abbr: 'Room',  j_level: 220, b_comment: 'Room within floor' },
      { b_key: 'rack',           b_name_full: 'Rack',         b_name_abbr: 'Rack',  j_level: 230, b_comment: 'Server rack' },
      { b_key: 'rack_unit',      b_name_full: 'Rack Unit',    b_name_abbr: 'RU',    j_level: 240, b_comment: 'Position within rack (1U, 2U, etc.)' }
    ].freeze

    # CI Classes hierarchy (from root to leaf)
    CI_CLASSES = [
      # Root level
      { b_key: 'hardware', b_name_full: 'Hardware', b_name_abbr: 'Hw',  j_sort:  10, parent_key: nil, b_comment: 'Physical hardware devices' },
      { b_key: 'software', b_name_full: 'Software', b_name_abbr: 'Sw',  j_sort: 100, parent_key: nil, b_comment: 'Software and applications' },
      { b_key: 'service',  b_name_full: 'Service',  b_name_abbr: 'Svc', j_sort: 200, parent_key: nil, b_comment: 'IT Services' },

      # Hardware subclasses
      { b_key: 'server',      b_name_full: 'Server',            b_name_abbr: 'Srv', j_sort: 11, parent_key: 'hardware', b_comment: 'Server hardware' },
      { b_key: 'vm',          b_name_full: 'Virtual machine',   b_name_abbr: 'VM',  j_sort: 12, parent_key: 'hardware', b_comment: 'Virtual server "hardware"' },
      { b_key: 'storage',     b_name_full: 'Storage',           b_name_abbr: 'Sto', j_sort: 13, parent_key: 'hardware', b_comment: 'Storage systems (SAN, NAS)' },
      { b_key: 'network',     b_name_full: 'Network Equipment', b_name_abbr: 'Nw',  j_sort: 14, parent_key: 'hardware', b_comment: 'Network devices' },
      { b_key: 'workstation', b_name_full: 'Workstation',       b_name_abbr: 'Ws',  j_sort: 15, parent_key: 'hardware', b_comment: 'Desktop and laptop computers' },
      { b_key: 'mobile',      b_name_full: 'Mobile Device',     b_name_abbr: 'Mob', j_sort: 16, parent_key: 'hardware', b_comment: 'Smartphones and tablets' },
      { b_key: 'printer',     b_name_full: 'Printer',           b_name_abbr: 'Prt', j_sort: 17, parent_key: 'hardware', b_comment: 'Printers and multifunction devices' },

      # Network subclasses
      { b_key: 'switch',   b_name_full: 'Switch',            b_name_abbr: 'Swi', j_sort: 131, parent_key: 'network', b_comment: 'Network switches' },
      { b_key: 'router',   b_name_full: 'Router',            b_name_abbr: 'Rtr', j_sort: 132, parent_key: 'network', b_comment: 'Network routers' },
      { b_key: 'firewall', b_name_full: 'Firewall',          b_name_abbr: 'Fw',  j_sort: 133, parent_key: 'network', b_comment: 'Firewall devices' },
      { b_key: 'wlan_ap',  b_name_full: 'WLAN Access Point', b_name_abbr: 'Ap',  j_sort: 134, parent_key: 'network', b_comment: 'Wireless access points' },

      # Software subclasses
      { b_key: 'operating_system', b_name_full: 'Operating System', b_name_abbr: 'OS',  j_sort: 101, parent_key: 'software', b_comment: 'Operating systems' },
      { b_key: 'database',         b_name_full: 'Database',         b_name_abbr: 'DB',  j_sort: 102, parent_key: 'software', b_comment: 'Database systems' },
      { b_key: 'application',      b_name_full: 'Application',      b_name_abbr: 'App', j_sort: 103, parent_key: 'software', b_comment: 'Business applications' },
      { b_key: 'middleware',       b_name_full: 'Middleware',       b_name_abbr: 'MW',  j_sort: 104, parent_key: 'software', b_comment: 'Middleware and integration software' }
    ].freeze

    # Lifecycle Statuses (no hierarchy, but ordered by typical lifecycle)
    LIFECYCLE_STATUSES = [
      { b_key: 'planned',        b_name_full: 'Planned',        b_name_abbr: 'plan',   b_comment: 'In planning phase' },
      { b_key: 'ordered',        b_name_full: 'Ordered',        b_name_abbr: 'ord',    b_comment: 'Ordered but not yet delivered' },
      { b_key: 'in_delivery',    b_name_full: 'In Delivery',    b_name_abbr: 'deliv',  b_comment: 'Being delivered' },
      { b_key: 'in_setup',       b_name_full: 'In Setup',       b_name_abbr: 'setup',  b_comment: 'Being set up/configured' },
      { b_key: 'in_test',        b_name_full: 'In Test',        b_name_abbr: 'test',   b_comment: 'In testing phase' },
      { b_key: 'active',         b_name_full: 'Active',         b_name_abbr: 'act',    b_comment: 'Currently in production use' },
      { b_key: 'maintenance',    b_name_full: 'Maintenance',    b_name_abbr: 'maint',  b_comment: 'Under maintenance' },
      { b_key: 'repair',         b_name_full: 'Repair',         b_name_abbr: 'rep',    b_comment: 'Being repaired' },
      { b_key: 'spare',          b_name_full: 'Spare',          b_name_abbr: 'spare',  b_comment: 'Spare/backup device' },
      { b_key: 'decommissioned', b_name_full: 'Decommissioned', b_name_abbr: 'decomm', b_comment: 'Decommissioned, no longer in use' },
      { b_key: 'disposed',       b_name_full: 'Disposed',       b_name_abbr: 'disp',   b_comment: 'Physically disposed/recycled' }
    ].freeze

    class << self
      # Returns all seed data definitions
      # Returns: Hash with keys :location_hierarchy, :ci_classes, :lifecycle_statuses
      def all_seed_data
        {
          location_hierarchy: LOCATION_HIERARCHY,
          ci_classes:         CI_CLASSES,
          lifecycle_statuses: LIFECYCLE_STATUSES
        }
      end

      # Returns seed data in correct order for insertion (top to bottom)
      # Returns: Array of hashes with :model, :data keys
      def insertion_order
        [
          { model: HrzcmLocatHier, data: LOCATION_HIERARCHY },
          { model: HrzcmLifecycleStatus, data: LIFECYCLE_STATUSES },
          { model: HrzcmCiClass, data: CI_CLASSES }
        ]
      end

      # Returns models in correct order for deletion (bottom to top)
      # Returns: Array of model classes
      def deletion_order
        [HrzcmCiClass, HrzcmLifecycleStatus, HrzcmLocatHier]
      end
    end
  end
end
