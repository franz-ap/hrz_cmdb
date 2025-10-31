/*-------------------------------------------------------------------------------------------*/
/* Redmine CMDB plugin: Configuration Management DataBase                                    */
/* Copyright (C) 2025 Franz Apeltauer                                                        */
/*                                                                                           */
/* This program is free software: you can redistribute it and/or modify it under the terms   */
/* of the GNU Affero General Public License as published by the Free Software Foundation,    */
/* either version 3 of the License, or (at your option) any later version.                   */
/*                                                                                           */
/* This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; */
/* without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. */
/* See the GNU Affero General Public License for more details.                               */
/*                                                                                           */
/* You should have received a copy of the GNU Affero General Public License                  */
/* along with this program.  If not, see <https://www.gnu.org/licenses/>.                    */
/*-------------------------------------------------------------------------------------eohdr-*/
// Purpose: Main JavaScript for CMDB page functionality including jsTree initialization and AJAX operations.
//          Handles tree navigation, node selection, form submissions, and dynamic content loading for all CMDB entities.

var HrzCmdb = {
  options: {},
  currentNode: null,

  init: function(options) {
    this.options = options;
    this.initTree();
    this.bindEvents();
  },

  initTree: function() {
    console.log('=== initTree called ===');
    this.loadTreeNode(null, $('#cmdb-tree'));
  },

  loadTreeNode: function(parentId, container) {
    var self = this;
    var url = this.options.treeDataUrl;
    var data = parentId ? { parent_id: parentId } : {};

    console.log('Loading tree node, parentId:', parentId, 'url:', url);

    $.ajax({
      url: url,
      data: data,
      dataType: 'json',
      success: function(nodes) {
        console.log('Tree data loaded, nodes count:', nodes.length);
        self.renderNodes(nodes, container);
      },
      error: function(xhr, status, error) {
        console.error('Failed to load tree data:', status, error);
      }
    });
  },

  renderNodes: function(nodes, container) {
    var self = this;
    var ul = $('<ul class="tree-list"></ul>');

    $.each(nodes, function(index, node) {
      console.log('Rendering node:', node.text, 'title:', node.title);
      var li = $('<li class="tree-node" data-id="' + node.id + '" data-type="' + node.type + '"></li>');
      var nodeContent = $('<div class="node-content"></div>');

      // Add title attribute if present (for tooltip)
      if (node.title) {
        //console.log('Setting title attribute:', node.title);
        nodeContent.attr('title', node.title);
      }

      // Add expand/collapse icon for folders
      if (node.children) {
        var expander = $('<span class="expander collapsed">▶</span>');
        nodeContent.append(expander);
      } else {
        nodeContent.append('<span class="spacer"></span>');
      }

      // Add node icon
      var icon = $('<span class="node-icon"></span>');
      if (node.type === 'new' || node.type === 'new_hierarchy') {
        icon.addClass('icon-add');
      } else if (node.children) {
        icon.addClass('icon-folder');
      } else {
        icon.addClass('icon-page');
      }
      nodeContent.append(icon);

      // Add node text
      var text = $('<span class="node-text">' + node.text + '</span>');
      // Also add title to the text span for better tooltip display
      if (node.title) {
        text.attr('title', node.title);
      }
      nodeContent.append(text);

      li.append(nodeContent);
      ul.append(li);
    });

    container.append(ul);
  },

  bindEvents: function() {
    var self = this;

    // Click on expander
    $(document).on('click', '.expander', function(e) {
      e.stopPropagation();
      var expander = $(this);
      var node = expander.closest('.tree-node');

      if (expander.hasClass('collapsed')) {
        self.expandNode(node);
        expander.removeClass('collapsed').addClass('expanded');
        expander.text('▼');
      } else {
        self.collapseNode(node);
        expander.removeClass('expanded').addClass('collapsed');
        expander.text('▶');
      }
    });

    // Click on node
    $(document).on('click', '.node-content', function(e) {
      var node = $(this).closest('.tree-node');
      self.selectNode(node);
    });

    // Track which submit button was clicked
    var clickedButton = null;
    $(document).on('click', 'input[type="submit"]', function() {
      clickedButton = $(this);
    });

    // Form submission
    $(document).on('submit', '#location-form, #new-location-form, #hierarchy-form, #new-hierarchy-form, #ci-class-form, #new-ci-class-form, #ci-form, #new-ci-form, #lifecycle-status-form, #new-lifecycle-status-form, #ext-sys-form, #new-ext-sys-form', function(e) {
      e.preventDefault();
      self.submitForm($(this), clickedButton);
      clickedButton = null; // Reset after use
    });

    // URL field changes - enable/disable icon
    $(document).on('input', '.url-field', function() {
      var input = $(this);
      var icon = input.siblings('.url-open-icon');
      var url = input.val().trim();

      if (url) {
        icon.removeClass('disabled').attr('data-url', url);
      } else {
        icon.addClass('disabled').removeAttr('data-url');
      }
    });

    // Click on URL open icon
    $(document).on('click', '.url-open-icon:not(.disabled)', function(e) {
      e.preventDefault();
      var icon = $(this);
      var url = icon.attr('data-url') || icon.closest('.url-field-container').find('.url-field').val().trim();

      if (url) {
        self.openTiki(url);
      }
    });
  },

  expandNode: function(node) {
    var self = this;
    var nodeId = node.data('id');
    console.log('=== expandNode called for:', nodeId);
    var childContainer = node.find('> .tree-children');

    if (childContainer.length === 0) {
      console.log('Creating new child container and loading children');
      childContainer = $('<div class="tree-children"></div>');
      node.append(childContainer);
      this.loadTreeNode(nodeId, childContainer);
    } else {
      console.log('Child container exists, just showing it');
      childContainer.show();
    }
  },

  collapseNode: function(node) {
    var childContainer = node.find('> .tree-children');
    childContainer.hide();
  },

  selectNode: function(node) {
    var self = this;
    var nodeId = node.data('id');
    var nodeType = node.data('type');

    // Remove previous selection
    $('.tree-node').removeClass('selected');
    node.addClass('selected');

    // If it's a folder, toggle expansion instead of loading details
    if (nodeType === 'folder') {
      console.log('Folder clicked, toggling expansion');
      var expander = node.find('> .node-content > .expander');
      if (expander.length > 0) {
        if (expander.hasClass('collapsed')) {
          self.expandNode(node);
          expander.removeClass('collapsed').addClass('expanded');
          expander.text('▼');
        } else {
          self.collapseNode(node);
          expander.removeClass('expanded').addClass('collapsed');
          expander.text('▶');
        }
      }
      // Don't load details for folders
      return;
    }

    // Load details
    this.currentNode = node;
    this.loadDetails(nodeId, nodeType);
  },

  loadDetails: function(nodeId, nodeType) {
    var self = this;
    var detailsContainer = $('#cmdb-details');

    if (nodeType === 'new') {
      // Load new location form
      $.ajax({
        url: '/cmdb/new_location',
        success: function(html) {
          detailsContainer.html(html);
        },
        error: function(xhr) {
          console.error('Failed to load new location form:', xhr);
          detailsContainer.html('<div class="flash error">Failed to load form. Please check your permissions.</div>');
        }
      });
    } else if (nodeType === 'new_hierarchy') {
      // Load new hierarchy form
      $.ajax({
        url: '/cmdb_basic_data/location_hierarchies/new_hierarchy',
        success: function(html) {
          detailsContainer.html(html);
        },
        error: function(xhr) {
          console.error('Failed to load new hierarchy form:', xhr);
          detailsContainer.html('<div class="flash error">Failed to load form. Please check your permissions.</div>');
        }
      });
    } else if (nodeType === 'seed_data') {
      // Load seed data management page
      $.ajax({
        url: '/cmdb_basic_data/seed_data_management',
        success: function(html) {
          detailsContainer.html(html);
        },
        error: function(xhr) {
          console.error('Failed to load seed data management:', xhr);
          detailsContainer.html('<div class="flash error">Failed to load seed data management.</div>');
        }
      });
    } else if (nodeType === 'info') {
      // Load info page
      $.ajax({
        url: '/cmdb/info',
        success: function(html) {
          detailsContainer.html(html);
        },
        error: function(xhr) {
          console.error('Failed to load info page:', xhr);
          detailsContainer.html('<div class="flash error">Failed to load info page.</div>');
        }
      });
    } else if (nodeType === 'location') {
      // Load location details
      $.ajax({
        url: '/cmdb/location/' + nodeId,
        success: function(html) {
          detailsContainer.html(html);
        },
        error: function(xhr) {
          console.error('Failed to load location details:', xhr);
          detailsContainer.html('<div class="flash error">Failed to load details.</div>');
        }
      });
    } else if (nodeType === 'hierarchy') {
      // Load hierarchy details
      var hierarchyId = nodeId.replace('hierarchy_', '');
      $.ajax({
        url: '/cmdb_basic_data/location_hierarchies/' + hierarchyId,
        success: function(html) {
          detailsContainer.html(html);
        },
        error: function(xhr) {
          console.error('Failed to load hierarchy details:', xhr);
          detailsContainer.html('<div class="flash error">Failed to load details.</div>');
        }
      });
    } else if (nodeType === 'new_ci_class') {
      // Load new CI class form
      $.ajax({
        url: '/cmdb/new_ci_class',
        success: function(html) {
          detailsContainer.html(html);
        },
        error: function(xhr) {
          console.error('Failed to load new CI class form:', xhr);
          detailsContainer.html('<div class="flash error">Failed to load form. Please check your permissions.</div>');
        }
      });
    } else if (nodeType === 'ci_class' || nodeType === 'ci_class_for_ci') {
      // Load CI class details
      // Extract ID by removing the longest matching prefix first
      var ciClassId = nodeId.replace('ci_class_for_ci_', '').replace('ci_class_', '');
      $.ajax({
        url: '/cmdb/ci_class/' + ciClassId,
        success: function(html) {
          detailsContainer.html(html);
        },
        error: function(xhr) {
          console.error('Failed to load CI class details:', xhr);
          detailsContainer.html('<div class="flash error">Failed to load details.</div>');
        }
      });
    } else if (nodeType === 'new_ci') {
      // Load new CI form
      $.ajax({
        url: '/cmdb/new_ci',
        success: function(html) {
          detailsContainer.html(html);
        },
        error: function(xhr) {
          console.error('Failed to load new CI form:', xhr);
          detailsContainer.html('<div class="flash error">Failed to load form. Please check your permissions.</div>');
        }
      });
    } else if (nodeType === 'ci') {
      // Load CI details
      var ciId = nodeId.replace('ci_', '');
      $.ajax({
        url: '/cmdb/ci/' + ciId,
        success: function(html) {
          detailsContainer.html(html);
        },
        error: function(xhr) {
          console.error('Failed to load CI details:', xhr);
          detailsContainer.html('<div class="flash error">Failed to load details.</div>');
        }
      });
    } else if (nodeType === 'new_lifecycle_status') {
      // Load new lifecycle status form
      $.ajax({
        url: '/cmdb/new_lifecycle_status',
        success: function(html) {
          detailsContainer.html(html);
        },
        error: function(xhr) {
          console.error('Failed to load new lifecycle status form:', xhr);
          detailsContainer.html('<div class="flash error">Failed to load form. Please check your permissions.</div>');
        }
      });
    } else if (nodeType === 'lifecycle_status') {
      // Load lifecycle status details
      var lifecycleStatusId = nodeId.replace('lifecycle_status_', '');
      $.ajax({
        url: '/cmdb/lifecycle_status/' + lifecycleStatusId,
        success: function(html) {
          detailsContainer.html(html);
        },
        error: function(xhr) {
          console.error('Failed to load lifecycle status details:', xhr);
          detailsContainer.html('<div class="flash error">Failed to load details.</div>');
        }
      });
    } else if (nodeType === 'new_ext_sys') {
      // Load new external system form
      $.ajax({
        url: '/cmdb/new_ext_sys',
        success: function(html) {
          detailsContainer.html(html);
        },
        error: function(xhr) {
          console.error('Failed to load new external system form:', xhr);
          detailsContainer.html('<div class="flash error">Failed to load form. Please check your permissions.</div>');
        }
      });
    } else if (nodeType === 'ext_sys') {
      // Load external system details
      var extSysId = nodeId.replace('ext_sys_', '');
      $.ajax({
        url: '/cmdb/ext_sys/' + extSysId,
        success: function(html) {
          detailsContainer.html(html);
        },
        error: function(xhr) {
          console.error('Failed to load external system details:', xhr);
          detailsContainer.html('<div class="flash error">Failed to load details.</div>');
        }
      });
    }
  },

  clearDetails: function() {
    console.log('=== clearDetails called ===');
    $('#cmdb-details').html('<div class="no-selection">' +
                            (window.hrz_cmdb_translations ?
                             window.hrz_cmdb_translations.select_item :
                             'Select an item from the tree to view details') +
                            '</div>');
    $('.tree-node').removeClass('selected');
    console.log('Details cleared');
  },

  // Generic method to load any node by type and ID.
  // Parameter nodeType: String type of node (e.g., 'settings', 'seed_data')
  // Parameter nodeId: String/Integer ID of the node
  loadNode: function(nodeType, nodeId) {
    var self = this;
    console.log('=== loadNode called ===');
    console.log('Node type:', nodeType, 'Node ID:', nodeId);

    // Find and select the node in the tree if it exists
    var node = $('.tree-node[data-id="' + nodeId + '"][data-type="' + nodeType + '"]');
    if (node.length > 0) {
      this.selectNode(node);
    } else {
      // If node not found in tree, directly load details
      this.loadDetails(nodeId, nodeType);
    }
  },

  deleteNode: function(nodeType, nodeId) {
    var self = this;
    console.log('=== deleteNode called ===');
    console.log('Node type:', nodeType);
    console.log('Node ID:', nodeId);

    // Determine the delete URL based on node type
    var url;
    switch(nodeType) {
      case 'location':
        url = '/cmdb/location/' + nodeId;
        break;
      case 'ci_class':
        url = '/cmdb/ci_classes/' + nodeId;
        break;
      case 'ci':
        url = '/cmdb/cis/' + nodeId;
        break;
      case 'lifecycle_status':
        url = '/cmdb/lifecycle_statuses/' + nodeId;
        break;
      case 'ext_sys':
        url = '/cmdb/external_systems/' + nodeId;
        break;
      case 'hierarchy':
        url = '/cmdb_basic_data/location_hierarchies/' + nodeId;
        break;
      default:
        console.error('Unknown node type:', nodeType);
        return;
    }

    console.log('Delete URL:', url);

    // Send DELETE request
    $.ajax({
      url: url,
      type: 'DELETE',
      dataType: 'json',
      success: function(response) {
        console.log('Delete response:', response);

        // Check if deletion was actually successful
        if (response.success === false) {
          // Deletion failed - show error message
          var errorMessage = response.error || response.errors || 'Failed to delete item.';
          if (Array.isArray(errorMessage)) {
            errorMessage = errorMessage.join(', ');
          }
          console.error('Delete prevented:', errorMessage);
          $('#cmdb-details').prepend('<div class="flash error">' + errorMessage + '</div>');
        } else {
          // Deletion successful
          console.log('Delete successful');
          // Show success message
          if (response.notice) {
            $('#cmdb-details').html('<div class="flash notice">' + response.notice + '</div>');
          }
          // Clear details and reload tree
          setTimeout(function() {
            self.clearDetails();
            self.refreshTree();
          }, 1000);
        }
      },
      error: function(xhr) {
        console.error('Delete failed:', xhr);
        var errorMessage = 'Failed to delete item.';
        if (xhr.responseJSON && xhr.responseJSON.errors) {
          errorMessage = xhr.responseJSON.errors.join(', ');
        } else if (xhr.responseJSON && xhr.responseJSON.error) {
          errorMessage = xhr.responseJSON.error;
        } else if (xhr.responseText) {
          errorMessage = xhr.responseText;
        }
        $('#cmdb-details').prepend('<div class="flash error">' + errorMessage + '</div>');
      }
    });
  },

  submitForm: function(form, clickedButton) {
    var self = this;
    console.log('=== submitForm called ===');
    console.log('Form ID:', form.attr('id'));
    console.log('Clicked button:', clickedButton);
    console.log('Button name:', clickedButton ? clickedButton.attr('name') : 'none');

    // Check which button was clicked
    var continueEditing = clickedButton && clickedButton.attr('name') === 'continue';
    var saveAsCopy = clickedButton && clickedButton.attr('name') === 'save_as_copy';
    var isNewForm = form.attr('id') === 'new-location-form' || form.attr('id') === 'new-hierarchy-form' || form.attr('id') === 'new-ci-class-form' || form.attr('id') === 'new-ci-form' || form.attr('id') === 'new-lifecycle-status-form' || form.attr('id') === 'new-ext-sys-form';

    console.log('continueEditing:', continueEditing);
    console.log('saveAsCopy:', saveAsCopy);
    console.log('isNewForm:', isNewForm);

    // Determine URL and method
    var url = form.attr('action');
    var method = form.attr('method') || 'POST';

    console.log('Original URL:', url);
    console.log('Original method:', method);

    if (saveAsCopy) {
      console.log('Save as copy detected, changing to POST');
      // For save as copy, we need to POST to the create action
      method = 'POST';
      // Remove the ID from the URL to use the create action
      if (form.attr('id') === 'location-form') {
        url = '/cmdb/location';
      } else if (form.attr('id') === 'hierarchy-form') {
        url = '/cmdb_basic_data/location_hierarchies';
      } else if (form.attr('id') === 'ci-class-form') {
        url = '/cmdb/ci_classes';
      } else if (form.attr('id') === 'ci-form') {
        url = '/cmdb/cis';
      } else if (form.attr('id') === 'lifecycle-status-form') {
        url = '/cmdb/lifecycle_statuses';
      } else if (form.attr('id') === 'ext-sys-form') {
        url = '/cmdb/external_systems';
      }
      console.log('New URL for copy:', url);
    }

    // Prepare form data
    var formData = form.serialize();

    if (saveAsCopy) {
      // Remove the _method=put parameter that Rails adds for PUT requests
      console.log('Removing _method parameter for save as copy');
      formData = formData.replace(/&?_method=put/gi, '');
    }

    formData += (continueEditing ? '&continue=true' : '') + (saveAsCopy ? '&save_as_copy=true' : '');

    console.log('Sending AJAX request:', url, method);
    console.log('Form data:', formData);

    $.ajax({
      url: url,
      type: method,  // jQuery uses 'type', not 'method'
      data: formData,
      dataType: 'json',
      beforeSend: function() {
        console.log('=== AJAX beforeSend ===');
        // Disable submit buttons to prevent double submission
        form.find('input[type="submit"]').prop('disabled', true);
      },
      success: function(response) {
        console.log('=== AJAX success ===');
        console.log('Response:', response);

        if (response.success) {
          console.log('Operation successful, response.id:', response.id);
          self.showNotice(response.notice || 'Operation successful');

          // Always refresh the entire tree to show new items
          console.log('Calling refreshTree()');
          self.refreshTree();

          // Handle details area based on what was saved and which button was clicked
          console.log('Determining what to do next - saveAsCopy:', saveAsCopy, 'continueEditing:', continueEditing);

          if (saveAsCopy && response.id) {
            console.log('Save as copy - loading new record for editing');
            // For save as copy, load the newly created item for editing
            if (form.attr('id') === 'location-form') {
              self.loadDetails(response.id, 'location');
            } else if (form.attr('id') === 'hierarchy-form') {
              self.loadDetails('hierarchy_' + response.id, 'hierarchy');
            } else if (form.attr('id') === 'ci-class-form') {
              self.loadDetails('ci_class_' + response.id, 'ci_class');
            } else if (form.attr('id') === 'ci-form') {
              self.loadDetails('ci_' + response.id, 'ci');
            } else if (form.attr('id') === 'lifecycle-status-form') {
              self.loadDetails('lifecycle_status_' + response.id, 'lifecycle_status');
            } else if (form.attr('id') === 'ext-sys-form') {
              self.loadDetails('ext_sys_' + response.id, 'ext_sys');
            }
          } else if (!continueEditing) {
            console.log('Normal save - clearing details');
            // "Save" button - clear details
            self.clearDetails();
          } else if (response.id) {
            console.log('Continue editing - reloading record');
            // "Save and continue" button - load the saved item for editing
            if (form.attr('id') === 'new-location-form') {
              // For new location, load it as existing location for editing
              self.loadDetails(response.id, 'location');
            } else if (form.attr('id') === 'location-form') {
              // For existing location, reload it
              self.loadDetails(response.id, 'location');
            } else if (form.attr('id') === 'new-hierarchy-form') {
              // For new hierarchy, load it as existing hierarchy for editing
              self.loadDetails('hierarchy_' + response.id, 'hierarchy');
            } else if (form.attr('id') === 'hierarchy-form') {
              // For existing hierarchy, reload it
              self.loadDetails('hierarchy_' + response.id, 'hierarchy');
            } else if (form.attr('id') === 'new-ci-class-form') {
              // For new CI class, load it as existing CI class for editing
              self.loadDetails('ci_class_' + response.id, 'ci_class');
            } else if (form.attr('id') === 'ci-class-form') {
              // For existing CI class, reload it
              self.loadDetails('ci_class_' + response.id, 'ci_class');
            } else if (form.attr('id') === 'new-ci-form') {
              // For new CI, load it as existing CI for editing
              self.loadDetails('ci_' + response.id, 'ci');
            } else if (form.attr('id') === 'ci-form') {
              // For existing CI, reload it
              self.loadDetails('ci_' + response.id, 'ci');
            } else if (form.attr('id') === 'new-lifecycle-status-form') {
              // For new lifecycle status, load it as existing lifecycle status for editing
              self.loadDetails('lifecycle_status_' + response.id, 'lifecycle_status');
            } else if (form.attr('id') === 'lifecycle-status-form') {
              // For existing lifecycle status, reload it
              self.loadDetails('lifecycle_status_' + response.id, 'lifecycle_status');
            } else if (form.attr('id') === 'new-ext-sys-form') {
              // For new external system, load it as existing ext sys for editing
              self.loadDetails('ext_sys_' + response.id, 'ext_sys');
            } else if (form.attr('id') === 'ext-sys-form') {
              // For existing external system, reload it
              self.loadDetails('ext_sys_' + response.id, 'ext_sys');
            }
          } else if (isNewForm && continueEditing) {
            // New form with continue but no ID returned - keep the form
            // This shouldn't happen, but as fallback keep current view
          } else {
            // Default: clear details
            self.clearDetails();
          }
        } else {
          self.showErrors(response.errors);
        }
      },
      error: function(xhr, status, error) {
        console.log('=== AJAX error ===');
        console.log('Status:', xhr.status);
        console.log('Error:', error);
        console.log('Response:', xhr.responseText);

        if (xhr.status === 403) {
          self.showErrors(['Access denied. Please check your permissions.']);
        } else {
          self.showErrors(['An error occurred. Please try again.']);
        }
      },
      complete: function(xhr, status) {
        console.log('=== AJAX complete ===');
        console.log('Status:', status);
        // Always re-enable form after AJAX completes (success or error)
        // But only if the request did not succeed in creating/updating a record
        // (we check this by looking at whether we're still showing the same form)
        if (status === 'error' || (xhr.responseJSON && !xhr.responseJSON.success)) {
          console.log('Re-enabling form after failed request');
          self.enableForm(form);
        }
      }
    });
  },

  refreshTree: function() {
    var self = this;
    console.log('=== refreshTree called ===');

    // Save currently expanded nodes
    var expandedNodes = [];
    $('.tree-node .expander.expanded').each(function() {
      expandedNodes.push($(this).closest('.tree-node').data('id'));
    });
    console.log('Expanded nodes before refresh:', expandedNodes);

    // Clear and reload tree
    console.log('Clearing tree container');
    $('#cmdb-tree').empty();
    console.log('Calling initTree()');
    this.initTree();

    // Re-expand previously expanded nodes after a short delay
    // We need to expand them in order (parent first, then children)
    setTimeout(function() {
      console.log('Re-expanding nodes after delay');

      // Function to expand a node and its children recursively
      var expandNodeById = function(nodeId, callback) {
        var node = $('.tree-node[data-id="' + nodeId + '"]');
        if (node.length > 0) {
          console.log('Re-expanding node:', nodeId);
          var expander = node.find('> .node-content > .expander');
          if (expander.hasClass('collapsed')) {
            self.expandNode(node);
            expander.removeClass('collapsed').addClass('expanded');
            expander.text('▼');

            // Wait a bit for the node to load its children before proceeding
            if (callback) {
              setTimeout(callback, 300);
            }
          } else if (callback) {
            callback();
          }
        } else if (callback) {
          callback();
        }
      };

      // Expand in order: basic_data, then location_hierarchy, then others
      var index = 0;
      var expandNext = function() {
        if (index < expandedNodes.length) {
          var nodeId = expandedNodes[index];
          index++;
          expandNodeById(nodeId, expandNext);
        } else {
          console.log('Tree refresh complete');
        }
      };

      expandNext();
    }, 500);
  },

  showNotice: function(message) {
    var notice = $('<div class="flash notice">' + message + '</div>');
    $('#cmdb-container').prepend(notice);
    setTimeout(function() {
      notice.fadeOut(function() {
        notice.remove();
      });
    }, 3000);
  },

  showErrors: function(errors) {
    var errorDiv = $('<div class="flash error"></div>');
    $.each(errors, function(index, error) {
      errorDiv.append('<div>' + error + '</div>');
    });
    $('#cmdb-container').prepend(errorDiv);
    setTimeout(function() {
      errorDiv.fadeOut(function() {
        errorDiv.remove();
      });
    }, 5000);
  },

  enableForm: function(form) {
    console.log('=== enableForm called ===');
    // Re-enable all submit buttons in the form
    form.find('input[type="submit"]').prop('disabled', false).removeClass('disabled');
    // Re-enable the form itself
    form.find('input, select, textarea').prop('disabled', false);
    console.log('Form re-enabled');
  },

  openTiki: function(url) {
    var fullUrl = url;

    // Check if it's a tiki: reference
    if (url.indexOf('tiki:') === 0) {
      var pageName = url.substring(5); // Remove 'tiki:' prefix
      var tikiBaseUrl = this.options.tikiBaseUrl || '';

      if (tikiBaseUrl) {
        fullUrl = tikiBaseUrl + pageName;
      } else {
        // Fallback if no base URL is configured
        fullUrl = '/tiki/' + pageName;
      }
    }

    window.open(fullUrl, '_blank');
  },

  // Reloads the entire tree from the root.
  // This is useful after operations that modify the tree structure (e.g., seed data operations).
  loadTree: function() {
    console.log('=== loadTree called ===');
    // Clear the tree container
    $('#cmdb-tree').empty();
    // Reload the tree from root
    this.initTree();
  }
};
