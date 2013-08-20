---
layout: doc
badge: elastics-client
title: How to migrate from Flex 0.x
---

# {{ page.title }}

Elastics 1.x has changed quite a lot from Flex version 0.x but you need just to rename a few things in order to upgrade it. You should be able to do it in a couple of minutes with the help of the `elastics-legacy` gem and just a few search and replace.  If you miss any change, Elastics will work anyway, but will emit a deprecation warning, so keep an eye on the log.

## Changes

### 1. Gem changes

#### Rails Apps

You have to change `gem 'flex', :require => 'flex/rails'` to simply `gem 'elastics-rails'` in your `Gemfile`. Then add `elastics-legacy` gem to your `Gemfile`. It will make it work almost as it is and it will allow a smoot migration. Run a `bundle install` and your app should be able to start. Then it will emit the deprecation warnings for the other changes in the log.

#### Non Rails Apps

If you used model related functionality, you will be required to load the `elastics-models` gem that is now separated by the `elastics-client` core gem. You should require the `elastics-legacy` gem. It will make it work almost as it is and it will allow a smoot migration.

### 2. Configuration Renaming

`base_uri` > `http_client.base_uri`

`http_client_options` > `http_client.options`

`raise_proc` > `http_client.raise_proc`

### 3. Special Variables

`vars[:size]` is not a special variable anymore, so it will not be automatically converted to the `vars[:params][:size]` param anymore. You must set it as a standard param: `:params => {:size => size}`.

> Elastics will not emit any warning if you still use the old `vars[:size]` variable with the intention to change the `vars[:params][:size]` param: it will just not set the param. If you used the `<<size>>` tag in any template it will work as long as a `:size` variable is set. Remember that tags can now refer to nested variables, so you could refer to the `vars[:params][:size]` param in any template with `<<params.size>>`.

### 4. Method Renaming

`add` > `deep_merge!` for all variables receivers

`info` > `doc` to print the self documentation (e.g. `Elastics.doc`, `YourClass.elastics.doc` {% see 2.5 %})

#### Bulk Support

`Flex.bulk(:lines => lines_bulk_string)` > `Elastics.post_bulk_string(:bulk_string => lines_bulk_string)`

`Flex.process_bulk(:collection => collection)` > `Elastics.post_bulk_collection(collection, options)`

`Flex.import_collection` > `Elastics.post_bulk_collection`

`Flex.delete_collection(collection)` > `Elastics.post_bulk_collection(collection, :action => "delete")`

### 5. Modules Renaming

`Flex::Loader` > `Elastics::Templates`

`Flex::Model` > `Elastics::ModelIndexer`

`Flex::RelatedModel` > `Elastics::ModelSyncer`

### 6. Rake Tasks Renaming

> __Notice__: The following rake tasks have been renamed and are not available, so please, change their name acordingly. Besides some ENV variable used for other tasks, may also have been renamed {% see 1.4 %}

`flex:create_indices` > `elastics:index:create`

`flex:delete_indices` > `elastics:index:delete`

### 7. flex > elastics

Search and replace in all your code `'flex'` for `'elastics'`. You must preserve the case so  for example `'Flex'` will be replaced by `'Elastics'` and `'flex_indexable?'` will be replaced by `'elastics_indexable?'` etc.

Rename also the `'flex'` dir to `'elastics'` and the files `'flex.yml'` and `'flex.rb'` to `'elastics.yml'` and `'elastics.rb'`.

## Additions

You may want to check the new documentation in order to take advantage of the new features of the gems. For example, you may want to add `Elastics::Scopes` to some of your classes, or you may want to use the new `elastics-admin` binary and tasks, or live-reindexing your code/index changes, or fine-tuning the configuration of the new elastics logger etc. {% see 1.1, 1.2 %}
