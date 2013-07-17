---
layout: doc
title: flex-model - Live Reindex
---

# {{ page.title }}

If you ever tried to reindex your production app while it is running you know that it might be quite a difficult task. You have the old code running and constantly updating the old index/indices, and you need to deploy some new search feature with the new code, that would produce and need a new index, so what should you do? If the production index/indices are small, you may shut-down your site for a few minutes in order to deploy the new code, reindex and restart the site. No big deal: problem solved! But quite typically your index/indices are big, so the reindexing would require you to shut down your site (or part of it) during a few hours, and that wouldn't be acceptable. If your app is making money, shutting it down would likely cost you a lot of bucks.

So you could try a live update, i.e. re-import the data while the old data is still in place. From a commercial point of view, that solution is probably better than shutting down the site, but it is still a bad one from a technical point of view. Your index will stay in an inconsistent state during the time of the update, and that may probably cause both your old and new code to fail during the process. The "deploy-then-update" will not be better than the "update-then-deploy" technique: both will likely produce a quite bad user experience during the process - depending on the magnitude of your changes.

The flex live-reindex feature is what you need in this case. You can leave your production app running the old code/index (and keep updating the old index) while the live-reindex rebuilds a new index by using your new code. During the rebuild, all the changes made by the old code (still running live) get tracked and mirrored on the new index. When the new index is complete, you can hot-swap the old code and index with the new code and index. Just a couple of lines of code to write, practically no down-time, no index inconsistency so no code failures and a very smooth user experience.

> __Personal Note__: Live-reindexing is tricky per se, but finding a way to perform it easily and regardless the app structure has been an even trickier challenge.

## Requirements

The live-reindex feature rely on a `redis` list in order to track the changes made by the processes of your running app during the reindex. You need to install [redis](http://www.redis.io/download) and the `redis` gem, and/or you may need to add it to your Gemfile.

## Usage

Using the live-reindex feature is very easy, but you need to understand the basics about how it works in order to use it properly, or you might corrupt your indices {% see 4.6#caveats %}.

The live reindexing should be the last step of your new deployment, performed just before you swap the old code with the new one. It will take care of reindex your data in new index/indices, including the changes being made during the reindexing itself.

> If you deploy with `capistrano`, you you should run the reindex method (perhaps in a migration) right before the `creating_symlink`

### Index Renaming

 The names of the new indices will be prefixed with a timestamp, similar to the timestamp prepended in the `ActiveRecord` migration: something like `20130608103457_my_index` for the index `my_index`. However, when the reindex will be completed each old index will be deleted and the new indices will be aliased with the original base name. That means that your app will continue to use e.g. the `my_index` name, but it will automatically point to the new (prefixed) index (no intervention required on your side).

### Stop Indexing

It's important to understand that code and index must constantly match when the app is running: the old code with the old index; the new code with the new index.
So in order to ensure that consistency the live-reindex feature needs to stop the indexing during the swapping (old code and index / new code and index). For that reason you must define the `:stop_indexing_proc` proc that must ensure to prevent all the processes that use the old code to change the index (e.g. put the app in maintenance mode, wait for eventual `resque` tasks in the queue to complete before returning, flush the indices, etc.).

The `:stop_indexing_proc` will be called (almost) at the end of the live-reindexing, just before the index swap. Just remember that the reindex methods will: 1) reindex, 2) call your proc to stop the indexing and 3) swap the old index with the new one. After that you must: 1) swap the old code with the new one and 2) resume the indexing that your proc stopped (or maybe just restart the new deployed app). The elapsed time from the indexing-stop to the indexing-restart will probably be just a few milliseconds or seconds at worse, but that is a critical step if you want a consistent and complete index and a smooth swapping.

> If you deploy with `capistrano`, you should resume the indexing right after the `creating_symlink`

You can set the `:stop_indexing_proc` as a configuration setting in the flex initializer file, and omit to pass it each time you need to reindex:

{% highlight ruby %}
Flex::Configuration.stop_indexing_proc = proc{Rake::Task('maintenance:start').execute}
{% endhighlight %}

However you can also pass it as an option of the method. For example:

{% highlight ruby %}
Flex::LiveReindex.<reindex_method>(:stop_indexing_proc => proc{...})
{% endhighlight %}

> The `:stop_indexing_proc` is explicitly required for your production environment, and for very good reasons. However when you are experimenting in your development environment, you don't need to stop anything, so you can silence the `MissingStopIndexingProcError` error by explicitly pass `:stop_indexing_proc => nil`. You may also want to set a different `Flex::Configuration.stop_indexing_proc` for different environments.

### Tracking Changes

During the reindexing, your live app may change some document in the old index/indices. The changes are tracked in a redis list and will be indexed at the end of the reindexing. If you pass a block with the reindex method it will receive (also) the changes done during the reindexing, so giving you the chance to update the new index/indices consistently with the change.

The tracking is done inside the Flex API methods defined for store and delete (i.e. `store`, `put_store`, `post_store`, `delete` and `remove`).

If your indices may get modified by some custom method, by other applications or by some elasticsearch river (none of which uses the above methods), the changes during the reindexing will not be traacked, hence will not be mirrored to the new index/indices. In that case, you must explicitly keep track of the changes by using the `track_change` or the `track_external_change` methods. Pease, take a look at the code and if you need some assistance, send me an email.

### Transform Block

The methods accept also an optional block, which will be used to eventually transform the documents passed.

The block will receive the action (`'index'` or `'delete'`) as the first argument, and the hash document pulled from elasticsearch. It is expected to change the passed document and return one of:

- a Hash with a single key/value pair of action/document: `{ action => document }` (where document can be a hash understood by elasticsearch or a DB record/document to index).
- an array of Hashes like the above (when you need to split one single action into a few different actions): `[ { action => document },{ action => document }, ... ]`
- a nil value (when you want to halt the indexing/deletion for a particular document)

The returned result(s) will be bulk-indexed.

For example:

{% highlight ruby %}
# a simple block
Flex::LiveReindex./<reindex_method>(my_options) do |action, raw_document_hash|
  if action == 'index'
    raw_document_hash['_source']['some_field'] = my_transform(raw_document_hash['_source']['some_field'])
    raw_document_hash['_source'].delete('some_other_field')
  end
  # you must return the action and the modified document
  {action => raw_document_hash}
end
{% endhighlight %}

> It's important to notice that the raw document hash argument passed to the block is a document pulled from one of the elasticsearch OLD indices, containing the old structure.

The block may need to process different indices in different ways, and the old index name might be prefixed (if it is already the product of a live-reindex). When you need to check the index name you should use the `index_basename` method on the document hash. It will return the unprefixed index name of the raw_document_hash. For example:

{% highlight irb %}
>> raw_document_hash['_index']
=> "20130608103457_my_index"

>> raw_document_hash.index_basename
=> "my_index"
{% endhighlight %}

You should always use the `index_basename` method when you need to check the index of the document. For example:

{% highlight ruby %}
Flex::LiveReindex.<reindex_method>(my_options) do |action, raw_document_hash|
  if action == 'index'
    case raw_document_hash.index_basename
    when 'my_index'
      ...
    when 'some_other_index'
      ...
    end
  end
  # you must return the action and the modified document
  {action => raw_document_hash}
end
{% endhighlight %}

> __Important__: you must not directly or indirectly run code that may call the `store`, `put_store`, `post_store`, `delete` and `remove`  Flex API methods from inside your transform block, or your app will enter in an infinite loop. Your block must return documents understood by the `Flex.build_bulk_string` method {% see 2.5#flexbuild_bulk_string Flex.build_bulk_string %}.

If you pass no block, the reindex method will use a default proc, different for different type of reindexing: see the details about each default in the specific method session.


## Reindex Methods

There are 3 different reindexing methods, useful in different contexts but working quite similarly. You can use only one of the 3 methods and only one time in one live-reindex session, then you have to swap the code and deploy. If you need to use more than one method, you must do it in different deploys.

> If you try to use more than one of the reindexing method in the same session, the execution of the second method will raise a `MultipleReindexError` error. In that case the first reindexing execution took place regularly (and the error will tell you the new index/indices that have been swapped successfully), but the other reindexing(s) have been aborted so you have still the old index/indices in place. If the code-changes that you were about to deploy rely on the successive reindexings that have been aborted, your app may fail, so you should complete the other reindexing in single successive deploys ASAP.
>
> If you are in development environment and REALLY know what you are doing, you can restart the process and silence that error by passing `:safe_reindex => false`.

If any other (not `MultipleReindexError`) error is raised during the process, the live-reindex will be aborted. In that case, your old index/indices have not been touched at all so they are left exactly as before. The new index/indices being built are probably incomplete, so they have already been deleted by an ensure block, so they left no trace in your elasticsearch server.

### Flex::LiveReindex.import_models

> Use this live reindex to import/reimport `ActiveRecord` and `Mongoid` models.

The transform block will be used only to pass the tracked changes at the end of the reindexing.

If you don't pass any block a default proc will be used. It will simply pull the current record/document from the DB and index it in the new index, or delete the elasticsearch document from the new index in case of a `'delete'` action. That's fine when you don't change the structure of your models, and change only the `flex_source` method for example. But if you delete or rename models, it will fail. In that case you could alias the models or split the changes in 2 deploys, or you  must pass an explicit block that will receive as usual the action and the document hash pulled from the old elasticsearch index at the moment of the change: you must do the changes in the document (like changing the type for example, or reindexing some other record, etc.) and return the proper result {% see 4.6#transform_block %}.

#### Full Reindex

You can reindex all the `Flex::Configuration.flex_models`

{% highlight ruby %}
Flex::LiveReindex.import_models {|action, raw_document_hash| .... }
{% endhighlight %}

#### Partial Reindex

In case you want to limit the reindexing to a few models (that really changed), you can pass an array of `:models`, but in that case you should also pass the `:ensure_indices` option that will ensure the completeness of the indices being reindexed.

{% highlight ruby %}
Flex::LiveReindex.import_models :models         => [ MyModelA, MyModelB ],
                                :ensure_indices => [ 'my_index' ]
{% endhighlight %}

The `:ensure_indices` option ensures 2 things:

1. It copies the complete data from the old index to the new one first (then it will reindex only the models you listed). That ensures you won't miss any data from the old indices. Besides, in case the index is built by more models, that is faster than reimporting all the models from scratch.
2. It checks whether any record/document in your DB would use any index not specifically listed in the `:ensure_indices` option. That would compromise the safety ensured by point #1, so if that happens, it will abort the reindexing and raise an error that will show you the extra index found. You may want to add it to the `:ensure_indices` array and retry the reindex, so ensuring it will be first copied from the old index.

> You can also pass other options, that will be forwarded to the `import` task. You can use the symbolic version of the env options (e.g.: `MODELS` > `:models`) {% see 1.4#flex_import flex:import %}.


### Flex::LiveReindex.migrate_active_models

> Use this live reindex for indexed `ActiveModel` models.

This method works similarly to the `Flex::LiveReindex.import_models` for the options (e.g. `:models` and `:ensure_indices`). However, the transform block will be used to pass ALL the records being reindexed AND the tracked changes at the end of the reindexing. If you don't pass any block, the index will be copied verbatim into the new index.

The full reindex reindexes all the `Flex::Configuration.flex_active_models` and the partial reindex works similarly to the `migrate_models` method.

### Flex::LiveReindex.migrate_indices

> Use this kind of generic live reindex for any index, when you prefer to interact directly with the documents, regardless the models. It migrates directly the content of one or more indices through the transform block that you must pass it.

The transform block will be used to pass ALL the record being reindexed AND the tracked changes at the end of the reindexing. If you don't pass any block, the index will be copied verbatim into the new index.

You can pass the `:indices` option to limit the indices to migrate: if you don't pass any `:indices` option the default indices of your app will be used. (the `:models` is ignored by this method).

## Caveats

### Just Upgraded

When you live-reindex, make sure your live app is running the same version of flex of your new deploy, or you may corrupt your index/indices and/or miss the live changes (made by the old running code during the reindexing). You should never live-reindex in the same deploy you upgrade flex. Instead upgrade, deploy, then live-reindex on one next deploy.

### Flex::Configuration.app_id

When you live-reindex, the `Flex::Configuration.app_id` should be set and match for both the old code (running app) and the new code. If you use `flex-rails` it is already set and matching, however, if you set it explicitly, ensure that the running app processes are using the same id of the new code, or you will miss all the live changes (made by the old running code during the reindexing). In other words, you cannot set and run it in the same commit/deploy: instead you should set it, commit and deploy, then make your changes and reindex on the next deploy.

### Safe live-reindex

Live-reindexing is a potentially dangerous process because it deletes the old indices after a successful reindexing. If you have a bug in the transform block or any issue with the `app_id` (mentioned above), or forget the couple of caveats above, you may lose or corrupt part of the indices. For that reasons you should always backup your indices before proceed, or at least dump the data with the `flex:backup:dump` task. That's very important especially with `Flex::ActiveModel` models, that don't have the data mirrored in a DB. Besides, this is a very new implementation that didn't have the time to be tested thoroughly yet, so please, do backup your indices before live-reindexing.
