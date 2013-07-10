---
layout: doc
title: flex-model - Live Reindex
---

# {{ page.title }}

If you ever tried to reindex your production app while it is running you know that it might be quite a difficult task. You have the old code running and constantly updating the old index, and you need to deploy some new search feature with the new code, that would produce and need a new index, so what should you do? If the production index/indices are small, you may shut-down your site for a few minutes in order to deploy the new code, reindex and restart the site. No big deal: problem solved! But quite typically your index/indices are big, so the reindexing would require you to shut down your site (or part of it) during a few hours, and that wouldn't be acceptable. If your app is making money, shutting it down would likely cost you a lot of bucks.

So you could try a live update, i.e. re-import the data while the old data is still in place. From a commercial point of view, that solution is probably better than shutting down the site, but it is still a bad one from a technical point of view. Your index will stay in an inconsistent state during the time of the update, and that may probably cause both your old and new code to fail during the process. The "deploy-then-update" will not be better than the "update-then-deploy" technique: both will likely produce a quite bad user experience during the process - depending on the magnitude of your changes.

The live-reindex feature is what you need in this case. You can leave your production app running the old code/index (and keep updating the old index) while the live-reindex rebuilds a new index by using your new code. During the rebuild, all the changes made by the old code (still running live) get tracked and mirrored on the new index. When the new index is complete, you can hot-swap the old code and index with the new code and index. Just a couple of lines of code to write, practically no down-time, no index inconsistency so no code failures and a very smooth user experience.

## Requirements

- The live-reindex feature rely on a `redis` list in order to track the changes made by the processes of your running app during the reindex. You need to install [redis](http://www.redis.io/download) and the `redis` gem, and/or you may need to add it to your Gemfile.
- The `:ensure_indices` option (only required when you do a partial reindex) rely on the `flex-backup` gem, so you need to install it to enable partial reindexing.

## Usage

Using the live-reindex feature is very easy, but you need to understand the basic about how it works in order to use it properly.

The live reindexing should be the last step of your new deployment, performed just before you swap the old code with the new one. It will take care of reindex your data in new index/indices, including the changes being made during the reindexing itself. The names of the new indices will be prefixed with a timestamp, similar to the timestamp prepended in the `ActiveRecord` migration (something like `20130608103457_my_index` for the index `my_index`). However, when the reindex will be completed each old index will be deleted and the new indices will be aliased with the original base name. That means that your app will continue to use e.g. the `my_index` name, but it will automatically point to the new (prefixed) index (no intervention required on your side).

It's important to understand that code and index must constantly match when the app is running: the old code with the old index; the new code with the new index.
So in order to ensure that consistency - if your index may get changed by the old code during the reindexing - the live-reindex feature needs to stop the indexing during the swapping. For that reason you must define the `:stop_indexing_proc` proc that must ensure to prevent all the processes that use the old code to change the index (e.g. put the app in maintenance mode, wait for eventual `resque` tasks in the queue to complete before returning, flush the indices, etc.).

The `:stop_indexing_proc` will be called (almost) at the end of the live-reindexing, just before the index swap. Just remember that the reindex methods will reindex, call your proc to stop the indexing and swap the old index with the new one: after that you must swap the old code with the new one and resume the indexing that your proc stopped. The time from the indexing-stop to the indexing-restart will probably be just a few milliseconds or seconds at worse, but that is a critical step if you want a consistent and complete index and a smooth swapping.

If you deploy with `capistrano`, you you should run the reindex method right before `creating_symlink` (perhaps in a migration) and you should resume the indexing right after it.

> In case your index is not being changed during the reindexing, obviously you do not need to stop the indexing so you can explicitly pass `:stop_indexing_proc => nil` to silence the `MissingStopIndexingProcError` error.

There are 3 reindex methods useful for different kind of reindexing

### Flex::LiveReindex.import_models

> Use this live reindex to import/reimport `ActiveRecord` and `Mongoid` models.

You can set the `:stop_indexing_proc` as a configuration setting in the flex initializer file, and omit to pass it each time you need to reindex:

{% highlight ruby %}
Flex::Configuration.stop_indexing_proc = proc{Rake::Task('maintenance:start').execute}
{% endhighlight %}

You can reindex all the `flex_models`:

{% highlight ruby %}
Flex::LiveReindex.import_models
{% endhighlight %}

In case you want to limit the reindexing to a few models (that really changed), you can pass an array of `:models`, but in that case you should also pass the `:ensure_indices` option that will ensure the completeness of the indices being reindexed.

{% highlight ruby %}
Flex::LiveReindex.import_models :models         => [ MyModelA, MyModelB ],
                                :ensure_indices => [ 'my_index' ]
{% endhighlight %}

The `:ensure_indices` option ensures 2 things:

1. It dumps and loads the complete data from the old index to the new one, then reimport only the models you listed. In case the index is built by a few models, that is faster than reimporting all the models from scratch, besides it ensures you won't miss any data from the old index.
2. It checks whether any record/document in your DB would use any index not specifically listed in the `:ensure_indices` option. That might happen if you forgot to list one index that a model is referring to, or if you forgot that your model uses dynamic indices (so indexing part of its records in some other index). If it encounters any index that is not specifically listed it will abort the reindexing, raising an error that will show you the extra index found.

> You can also pass other options, that will be forwarded to the `import` task. You can use the symbolic version of the env options (e.g.: `MODELS` > `:models`) {% see 1.4#flex_import flex:import %}.

### Flex::LiveReindex.migrate_active_models

> Use this live reindex for indexed `ActiveModel` models.

The same documentation of `Flex::LiveReindex.import_models` applies to this method, with just a little addition.

A `Flex::ActiveModel` model is a model that stores its data directly in the index: there is no DB data to import into the index, there is only the data already in the index itself. Reindexing it is sort of a data migration from the old index to the new one. You can do so by defining a block that will receive all the documents in the old index (one at a time) and should modify and return it. The returned (modified) document will be indexed in the new index.

For example:

{% highlight ruby %}
Flex::LiveReindex.migrate_active_models(my_options) do |raw_document_hash|
  raw_document_hash['_source']['some_field'] = my_transform(raw_document_hash['_source']['some_field'])
  raw_document_hash['_source'].delete('some_other_field')
  # you must return the modified document
  raw_document_hash
end
{% endhighlight %}

> __Notice__: the document received and returned by your block is and must be a raw document hash, with the same structure understood by elasticsearch.


### Flex::LiveReindex.migrate_index

> Use this live reindex for any index, when you prefer to interact directly with the documents, regardless the models.

This type of live reindexing is similar to the `Flex::LiveReindex.migrate_active_models`. The only difference is that it migrates directly the content of one index through the block that you must pass it. For example:

{% highlight ruby %}
Flex::LiveReindex.migrate_index('my_index', my_options) do |raw_document_hash|
  raw_document_hash['_source']['some_field'] = my_transform(raw_document_hash['_source']['some_field'])
  raw_document_hash['_source'].delete('some_other_field')
  # you must return the modified document
  raw_document_hash
end
{% endhighlight %}

## Caveats

### IMPORTANT: Flex::Configuration.app_id

When you live-reindex, the `Flex::Configuration.app_id` should be set and match for both the old code and the new code. If you use `flex-rails` it is already set and matching, however, if you set it explicitly, ensure that the running app processes are using the same id of the new code, or you will miss all the changes made by the old running code during the reindexing. In other words, you cannot set and run it in the same commit/deploy: instead you should set it, commit and deploy, then make your changes and reindex on the next deploy.

### Safe live-reindex

Live-reindexing is a potentially dangerous process, so you should always backup your indices before proceed, or at least dump the data with the `flex:backup:dump` task. Besides, remember that the live-reindex will keep track of the changes made to the indices by "whatching" the `flex.sync` method. If your indices may get modified by some API method (e.g. `Flex.store`, `Flex.remove`, etc.), by other applications or by some elasticsearch river (none of which uses the `sync` method), the changes during the reindexing will not be mirrored on the new index/indices. In this case, you must explicitly keep track of the changes by using the `track_change` or the `track_external_change` methods. Pease, take a look at the code and if you need some assistance, send me an email.
