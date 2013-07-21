---
layout: doc
title: How to migrate from flex 0.x
---

# {{ page.title }}

Flex 1.x has changed quite a lot from version 0.x but you need just to rename a few things in order to upgrade it. You can do it in a couple of minutes with just a few search and replace.  If you miss any change, flex will work anyway, but will emit a deprecation warning, so keep an eye on the log.

## Changes

### 1. Gem changes

#### Rails Apps

You have to change `gem 'flex', :require => 'flex/rails'` to simply `gem 'flex-rails'` in your `Gemfile`. Run a `bundle install` and your app should be able to start. Then it will emit the deprecation warnings for the other changes in the log.

#### Non Rails Apps

If you used model related functionality, you will be required to load the `flex-model` gem that is now separated by the `flex` core gem.

### 2. Configuration Renaming

`base_uri` > `http_client.base_uri`

`http_client_options` > `http_client.options`

`raise_proc` > `http_client.raise_proc`

### 3. Method Renaming

`add` > `deep_merge!` for all variables receivers

`info` > `doc` to print the self documentation (e.g. `Flex.doc`, `YourClass.flex.doc` {% see 2.5 %})

#### Bulk Support

`Flex.bulk(:lines => lines_bulk_string)` > `Flex.post_bulk_string(:bulk_string => lines_bulk_string)`

`Flex.process_bulk(:collection => collection)` > `Flex.post_bulk_collection(collection, options)`

`Flex.import_collection` > `Flex.post_bulk_collection`

`Flex.delete_collection(collection)` > `Flex.post_bulk_collection(collection, :action => "delete")`

### 4. Modules Renaming

`Flex::Loader` > `Flex::Templates`

`Flex::Model` > `Flex::ModelIndexer`

`Flex::RelatedModel` > `Flex::ModelSyncer`

### 5. Rake Tasks Renaming

`flex:create_indices` > `flex:index:create`

`flex:delete_indices` > `flex:index:delete`

> __Notice__: some ENV variable used for the tasks, may also have been renamed {% see 1.4 %}

## Additions

You may want to check the new documentation in order to take advantage of the new features of the gems. For example, you may want to add `Flex::Scopes` to some of your classes, or you may want to use the new `flex-backup` binary and tasks, or live-reindexing your code/index changes, or fine-tuning the configuration of the new flex logger etc. {% see 1.1, 1.2 %}
