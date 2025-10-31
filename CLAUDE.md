# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

<!-- Purpose: Documentation file providing AI coding assistants with context about this Redmine CMDB plugin's architecture, development workflows, and coding conventions. -->

## Project Overview

This is a Configuration Management Database (CMDB) plugin for Redmine 6.1+. It allows tracking hardware and software inventory items (Configuration Items/CIs) and connecting them to Redmine tickets. The plugin is in active development (currently v0.7.4, MVP stage).

## Development Commands

### Installation and Setup
```bash
# Install dependencies (from Redmine root)
bundle install

# Run database migrations
RAILS_ENV=production bundle exec rake redmine:plugins:migrate

# Rollback migrations (for uninstall or testing)
RAILS_ENV=production bundle exec rake redmine:plugins:migrate NAME=hrz_cmdb VERSION=0
```

### Plugin Development
This plugin follows standard Redmine plugin development patterns. There are no automated tests yet. Manual testing is done through the Redmine web interface.

## Code Architecture

### Plugin Structure
- **init.rb**: Plugin registration, defines menu items, permissions, and settings. Loads all lib files automatically.
- **config/routes.rb**: All routing definitions for CMDB, basic data, and issue-CI integration.
- **lib/hrz_cmdb/**: Core plugin modules
  - **permission_helper.rb**: Group-based permission system (view_cmdb, edit_cmdb, edit_basic_data)
  - **hooks/view_issues_hook.rb**: Redmine view hooks to inject CI sections into issue pages
  - **patches/**: Monkey patches to extend core Redmine classes (Issue, IssuesHelper)

### Data Model Hierarchy

The plugin implements a dual hierarchy system:

1. **Location Hierarchy** (tree structure):
   - `HrzcmLocatHier`: Defines location hierarchy levels/types
   - `HrzcmLocation`: Actual locations with two-parent support (j_part_of1_id, j_part_of2_id)
   - Locations can have multiple parents, enabling complex organizational structures

2. **CI Class Hierarchy** (tree structure):
   - `HrzcmCiClass`: Configuration Item classes in a tree structure
   - `HrzcmCi`: Actual configuration items linked to locations, classes, and lifecycle statuses
   - CIs track hardware/software with producer, model, serial numbers, etc.

3. **Additional Models**:
   - `HrzcmLifecycleStatus`: Status tracking for CIs (planning, active, decommissioned, etc.)
   - `HrzcmExtSys`: External system integration points
   - `HrzcmCiExt`: Links CIs to external systems
   - `HrzcmCiIssue`: Junction table connecting CIs to Redmine issues

### Controllers

- **CmdbController**: Main CRUD operations for locations, CI classes, CIs, lifecycle statuses, and external systems. Provides tree_data endpoint for jsTree UI.
- **CmdbBasicDataController**: Manages location hierarchy levels (basic data setup).
- **IssueCisController**: Handles CI-Issue associations, provides available_cis endpoint.

### Permission System

Custom group-based permissions (not Redmine role-based):
- Permissions are configured via plugin settings (Administration → Plugins → CMDB AF → Configure)
- Three permission levels: view_cmdb, edit_cmdb, edit_basic_data
- `HrzCmdb::PermissionHelper.user_has_permission?(user, permission_type)` checks access
- Admins always have full access
- Issue-level CI permissions (view_issue_cis, manage_issue_cis) use standard Redmine roles

### View Structure

- **app/views/cmdb/index.html.erb**: Main CMDB page with jsTree-based hierarchical navigation
- **app/views/cmdb/_*_form.html.erb**: Form partials for creating/editing entities
- **app/views/cmdb/_*_details.html.erb**: Detail view partials
- **app/views/issue_cis/**: Partials for displaying CIs in issue pages

### Frontend

- **assets/javascripts/hrz_cmdb.js**: Main JavaScript for tree navigation, AJAX operations
- **assets/javascripts/issue_cis.js**: Issue-CI association management
- **assets/stylesheets/hrz_cmdb.css**: Plugin-specific styles
- Uses jsTree library for hierarchical tree views

### Database Naming Convention

Tables and columns use a prefix system:
- Tables: `hrzcm_*` (e.g., hrzcm_ci, hrzcm_location)
- Integer data fields: prefix `j_*`
- Text fields: `b_*` (e.g., b_name_full, b_name_abbr, b_comment)
- Boolean/data fields: `q_*`
- This convention helps avoid naming conflicts with Redmine core tables.
- Foreign keys are usually Integer data fields. So, they have prefix `j_*`  and since they contain IDs (primary keys of the referenced tables), they also have suffix `*_id`  (e.g., j_ci_class_id, j_location_id)


### Model Callbacks and Tracking

All models automatically track:
- Creator: `created_by` (User ID), `created_on` (timestamp)
- Updater: `updated_by` (User ID), `updated_on` (timestamp)
- Uses `User.current` from Redmine's thread-local user context

### File Headers

All Ruby files include a standardized AGPL v3 license header. Template is in `.header.txt`. The header is 89 characters wide and ends with "eohdr" marker.
Never change this standard header!


### Internationalization

Plugin is fully multilingual with 12+ language files in `config/locales/`. Translation keys follow pattern: `hrz_cmdb.*`
It is important to always add new texts to all those language files.

### Integration Points

- **Redmine Issues**: CIs can be attached to issues via has_many :through relationship. Issue model is patched to add `has_many :cis` association.
- **TikiWiki**: Optional integration via configurable base URL in plugin settings
- **Permissions**: Integrates with Redmine's project modules and role system for issue-level permissions

## Coding Conventions for This Project

### Purpose Comments in All Files

Every source file MUST have a purpose comment directly below the header explaining what the file does:
- **Ruby files (*.rb)**: `# Purpose: <description>`
- **ERB files (*.erb)**: `<%# Purpose: <description> %>`
- **JavaScript files (*.js)**: `// Purpose: <description>`
- **CSS files (*.css)**: `/* Purpose: <description> */`

This requirement applies to ALL newly created files.

### Internationalization Requirements

When adding new UI text, ALL language files must be updated simultaneously:
- `bg.yml` (Bulgarian)
- `de.yml` (German)
- `el.yml` (Greek)
- `en.yml` (English)
- `hr.yml` (Croatian)
- `hu.yml` (Hungarian)
- `pl.yml` (Polish)
- `ro.yml` (Romanian)
- `ru.yml` (Russian)
- `tr.yml` (Turkish)
- `uk.yml` (Ukrainian)

Never add translation keys to only a subset of these files. All 11 must be updated together.

### Three-Layer Validation for Required Fields

When making a field required, implement validation at all three layers:

1. **Database layer**: Add NOT NULL constraint via migration
   ```ruby
   change_column_null :table_name, :column_name, false
   ```

2. **Application layer**: Add ActiveRecord validation in model
   ```ruby
   validates :column_name, presence: true
   ```

3. **UI layer**: Add HTML5 validation and visual indicator
   ```erb
   <%= label_tag :field_name, l('label') %> <span class="required">*</span>
   <%= text_field_tag 'field_name', '', required: true %>
   ```

This ensures data integrity at every level and provides clear feedback to users.

### Comment Preservation and Method Documentation

**Never remove comments.** If necessary, supplement or correct them to ensure accuracy, especially after program changes.

**Method Documentation for all `def` statements:**
Every method definition must have documentation immediately above it (before the `def` line) that includes:
1. Brief description of what the method does
2. Description of all parameters
3. Possible values for each parameter and their meaning

Example format (from `app/controllers/cmdb_controller.rb:tree_data`):
```ruby
# Defines the structure of the navigation tree.
# Parameter parent_id:
#   * blank ................... root level of the tree
#   * 'location_hierarchy' .... Location hierarchy sub-tree
def tree_data
  # method body
end
```

For methods with multiple parameters or complex return values, also document:
- Return value type and meaning
- Any exceptions that may be raised
- Side effects (database updates, external API calls, etc.)

### Automated Testing

**All functionality must have automated tests.** For every model, controller, helper, and lib function that can be tested, create corresponding test files.

**Test Structure:**
```
test/
  fixtures/          # YAML test data
  unit/             # Model tests
  functional/       # Controller tests
  integration/      # End-to-end tests
  test_helper.rb    # Test configuration
```

**Test Requirements:**
- **Model tests** must cover: validations, associations, scopes, instance methods, class methods
- **Controller tests** must cover: all actions, permission checks, success/error responses, JSON responses
- **Helper tests** must cover: all public helper methods with various inputs
- **Integration tests** should cover: critical user workflows

**Running Tests:**
```bash
# All plugin tests
bundle exec rake redmine:plugins:test NAME=hrz_cmdb

# Only unit tests
bundle exec rake redmine:plugins:test:units NAME=hrz_cmdb

# Only functional tests
bundle exec rake redmine:plugins:test:functionals NAME=hrz_cmdb
```

**Test Naming Convention:**
- Model tests: `test/unit/hrzcm_*_test.rb`
- Controller tests: `test/functional/*_controller_test.rb`
- Use descriptive test names: `test_should_validate_presence_of_ci_class`
