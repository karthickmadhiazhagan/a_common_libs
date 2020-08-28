## A Common Libs
Contains:
  * Global JS and CSS libraries for RMPlus plugins
  * Some helper methods and global functionality for RMPlus plugins
  * Tricks and hacks to speedup redmine (we need to rewrite redmine core, to make it faster, so, just tricks and hacks)

Changelog:
2.5.7
* Added: support rail 2.5.4

2.5.6
* Added: additional macros

2.5.5
* Added: Month picker

2.5.4
* Added: Support Rails 5 and Redmine 4
* Dropped: support Rails < 5 and Redmine < 4

2.5.3
* Added: associated custom field column
* Added: Setting for ajax issue edit form
* Added: logo in attachment

2.5.2
* Fixed: issue macros

2.5.1
* Rename methods

2.5.0
* Added: callbacks to exec ActiveRecord query
* Speedup link_to_user method helper

2.4.9
* Fixed: autoloading bugs coz poor knowledge author's others plugins

2.4.8
* Fixed: fix double load environment
* Fixed: scroll in modal windows with hint

2.4.7
* Fixed: hide window scroll if modal window opened
* Added: drag-n-drop for file's custom fields
* Added: rmplus additional functionality

2.4.6
* Added: helper functions and styles for RMPlus plugins
* Added: RMPlus button styles
* Added: base macros and issue macros
* Added: custom visibility conditions

2.4.5
* Fixed: size modal window
* Fixed: added awesome-font to print version

2.4.4
* Added: auto enable settings for unread_issues and redmine_issue_tabs
* Added: patching views
* Change: improve custom fields
* Change: ajax counters store

2.4.3
* Fixed: reassign issue custom fields after project\tracker changed
* Fixed: custom fields API access
* Fixed: bugs of migration
* Fixed: mobile view
* Fixed: drag and drops bugs

2.4.2
* Improved redmine custom_fields
* Added support MSSQL

2.4.0
* Added: support redmine 3.4
* Fixed: minor bugs
* Dropped: support redmine < 3.4, need to use previous versions of the plugin

2.3.5
* Speedup issues queries with CF multiple users column in list

2.3.4
* Fixed: loading path order

2.3.3
* Fixed: minor bugs

2.3.2
* Added: compatibility to our plugins

2.3.1
* Added: refactored redmine custom_fields to speedup (need to be disabled)
* Fixed: some sql extensions for different databases
* Fixed: sql extension substring for mysql

2.3.0
* Added: log for api
* Added: custom field Percent

2.2.9
* Added: jqPlot plugins

2.2.8
* Fixed: ajax_values permissions

2.2.7
* Fixed: support redmine < 3.0

2.2.6
* Added: fix for redmine 3.3

2.2.5
* Added: Updated FontAwesome

2.2.4
* Fixed: detecting favourite project for user without preferences

2.2.3
* fixed custom field order values for user type
* new version of DatePicker

2.2.2
* fixed time queries

2.2.0
* fixed select2 styles
* moved RM+ icon for email layout to our server
* fixed fast-edit links for select2
* support redmine 3.3.0

2.1.9
* select2 - 4.0.3
* fixed modal windows

2.1.8
* fixed loading select2_extensions if select2 disabled

2.1.7
* moved helpers for postgreSQL

2.1.6
* add periodpicker

2.1.5
* dependency FontAwasome fot luxury_buttons

2.1.0
* refactored modal windows

2.0.0
* fixed auto-setting FontAwasome

1.1.8
* fixed auto-settings

1.1.7
* fixed favourite project sql to ansi sql

1.1.6
* added support for information about the license expiration
* change Highcharts to jqPlot

1.1.5:
* added create_guid
* modified modal_windows