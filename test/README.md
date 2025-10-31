# CMDB Plugin Tests

This directory contains automated tests for the Redmine CMDB plugin.

## Test Structure

```
test/
├── fixtures/          # YAML test data for all models
├── functional/        # Controller tests
├── unit/             # Model and lib tests
├── integration/      # End-to-end tests (future)
├── test_helper.rb    # Test configuration and utilities
└── README.md         # This file
```

## Running Tests

### All Plugin Tests
```bash
cd /path/to/redmine
bundle exec rake redmine:plugins:test NAME=hrz_cmdb
```

### Only Unit Tests (Models, Helpers, Libs)
```bash
bundle exec rake redmine:plugins:test:units NAME=hrz_cmdb
```

### Only Functional Tests (Controllers)
```bash
bundle exec rake redmine:plugins:test:functionals NAME=hrz_cmdb
```

### Single Test File
```bash
bundle exec ruby plugins/hrz_cmdb/test/unit/hrzcm_ci_test.rb
```

### Single Test Method
```bash
bundle exec ruby plugins/hrz_cmdb/test/unit/hrzcm_ci_test.rb -n test_should_validate_presence_of_ci_class
```

## Test Coverage

### Unit Tests

#### Models
- **hrzcm_ci_test.rb** - Tests for Configuration Items
  - Validations (presence, length)
  - Associations (ci_class, location, lifecycle_status)
  - Scopes (ordered_by_abbr, for_location, for_ci_class)
  - Instance methods (display_name, to_s, tree_label)
  - Callbacks (creator, updater)

- **hrzcm_location_test.rb** - Tests for Locations
  - Validations (presence, length)
  - Associations (location_type, parent1, parent2, children)
  - Scopes (root_locations, ordered_by_b_name_abbr, for_type)
  - Hierarchy methods (children, has_children?, parents)
  - Instance methods (display_name, to_s, tree_label)

- **permission_helper_test.rb** - Tests for Permission System
  - user_has_permission? with various scenarios
  - Admin user permissions
  - Group-based permission checks
  - groups_for_permission method
  - groups_with_permission method

### Functional Tests

- **cmdb_controller_test.rb** - Tests for Main CMDB Controller
  - Index action with/without permissions
  - tree_data action for different node types
  - CI CRUD operations (create, read, update, delete)
  - Location CRUD operations
  - CI Class operations (edit_basic_data permission)
  - Lifecycle Status operations
  - Permission checks for all actions
  - JSON response validation

## Test Fixtures

Fixtures provide consistent test data across all tests:

- **hrzcm_locat_hier.yml** - 3 hierarchy levels (Building, Floor, Room)
- **hrzcm_location.yml** - 4 locations in hierarchical structure
- **hrzcm_ci_class.yml** - 4 CI classes (Hardware > Server, Workstation; Software)
- **hrzcm_lifecycle_status.yml** - 4 lifecycle statuses (Planning, Active, Maintenance, Decommissioned)
- **hrzcm_ci.yml** - 4 CIs (2 servers, 1 workstation, 1 invalid for testing)

## Writing New Tests

### Unit Test Template

```ruby
require File.expand_path('../../test_helper', __FILE__)

class MyModelTest < ActiveSupport::TestCase
  fixtures :my_fixtures

  test "should do something" do
    # Arrange
    object = MyModel.new(attribute: 'value')

    # Act
    result = object.some_method

    # Assert
    assert_equal expected, result
  end
end
```

### Functional Test Template

```ruby
require File.expand_path('../../test_helper', __FILE__)

class MyControllerTest < ActionController::TestCase
  fixtures :users, :my_fixtures

  def setup
    @user = user_with_cmdb_permission('view_cmdb')
  end

  test "should get index" do
    @request.session[:user_id] = @user.id
    get :index
    assert_response :success
  end
end
```

## Test Helpers

Custom test helpers are available in `test_helper.rb`:

- `user_with_cmdb_permission(permission_type)` - Returns user with specified CMDB permission
- `user_without_cmdb_permission` - Returns user without any CMDB permissions
- `setup_user_current(user)` - Sets User.current for permission testing

## Continuous Integration

Tests should be run:
- Before committing changes
- In CI/CD pipeline
- After merging branches
- Before releases

## Test Guidelines

1. **Test names** should be descriptive: `test_should_validate_presence_of_ci_class`
2. **Follow AAA pattern**: Arrange, Act, Assert
3. **One assertion per test** when possible
4. **Use fixtures** for consistent test data
5. **Test edge cases**: nil values, empty strings, boundary conditions
6. **Test permissions**: Both granted and denied scenarios
7. **Clean up** after tests (especially plugin settings)

## Debugging Tests

Enable verbose output:
```bash
bundle exec rake redmine:plugins:test NAME=hrz_cmdb TESTOPTS="-v"
```

Run with debugger:
```ruby
# Add to test file
require 'debug'
binding.break  # Execution will pause here
```

Show test coverage (if simplecov is installed):
```bash
COVERAGE=true bundle exec rake redmine:plugins:test NAME=hrz_cmdb
```

## Troubleshooting

### Database issues
```bash
# Reset test database
RAILS_ENV=test bundle exec rake db:drop db:create db:migrate
RAILS_ENV=test bundle exec rake redmine:plugins:migrate
```

### Fixture loading errors
- Check YAML syntax in fixture files
- Ensure foreign key references exist
- Verify fixture names match model class names

### Permission test failures
- Check that User fixtures are loaded (users, groups_users)
- Verify plugin settings are reset in teardown
- Ensure User.current is set properly
