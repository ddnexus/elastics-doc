---
layout: doc
title: How to migrate from flex 0.x
---

# {{ page.title }}

Flex 1.x has changed quite a lot from version 0.x but you need just to rename a few things in order to upgrade it. You can do it in 3 minutes with just a few search and replace.  If you miss any change, flex will work anyway, but will emit a deprecation warning, so keep an eye on the log.

## Changes

### 1. Gemfile change (only for rails applications)

There is only one breaking change (the only that will raise an error), that you have to update if you are using flex with a Rails app. It's a very simple one: you have just to change `gem 'flex', :require => 'flex/rails'` to simply `gem 'flex-rails'`. Then run a `bundle install` and your app should be able to start, and emit the deprecation warnings in the log.

### 2. Configuration Renaming

`base_uri` > `http_client.base_uri`

`http_client_options` > `http_client.options`

`raise_proc` > `http_client.raise_proc`

### 3. Method Renaming

`add` > `deep_merge!` for all variables receivers

`info` > `doc` to print the self documentation (e.g. `Flex.doc`, `YourClass.flex.doc` {% see 2.4 %})

### 4. Modules Renaming

`Flex::Loader` > `Flex::Templates`

`Flex::Model` > `Flex::ModelIndexer`

`Flex::RelatedModel` > `Flex::ModelSyncer`

### 5. Rake Tasks Renaming

`flex:create_indices` > `flex:index:create`

`flex:delete_indices` > `flex:index:delete`

> __Notice__: some ENV variable used for the tasks, may also have been renamed {% see 1.4 %}

## Additions

You may want to check the new documentation in order to take advantage of the new features of the gems. For example, you may want to add `Flex::Scopes` to some of your classes, or you may want to use the new `flex-backup` binary and tasks, or fine-tuning the configuration of the new flex logger etc. {% see 1.1, 1.2 %}
