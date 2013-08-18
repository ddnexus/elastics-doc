---
layout: doc
badge: flex-admin
title: Live Reindex
---

# {{ page.title }}

If you ever tried to reindex your production app while it is running you know that it might be quite a difficult task. You have the old code running and constantly updating the old index/indices, and you need to deploy some new search feature with the new code, that would produce and need a new index, so what should you do? If the production index/indices are small, you may shut-down your site for a few minutes in order to deploy the new code, reindex and restart the site. No big deal: problem solved! But quite typically your index/indices are big, so the reindexing would require you to shut down your site (or part of it) during a few hours, and that wouldn't be acceptable. If your app is making money, shutting it down would likely cost you a lot of bucks.

So you could try a live update, i.e. re-import the data while the old data is still in place. From a commercial point of view, that solution is probably better than shutting down the site, but it is still a bad one from a technical point of view. Your index will stay in an inconsistent state during the time of the update, and that may probably cause both your old and new code to fail during the process. The "deploy-then-update" will not be better than the "update-then-deploy" technique: both will likely produce a quite bad user experience during the process - depending on the magnitude of your changes.

The flex live-reindex feature is what you need in this case. You can leave your production app running the old code/index (and keep updating the old index) while the live-reindex rebuilds a new index by using your new code. During the rebuild, all the changes made by the old code (still running live) get tracked and mirrored on the new index. When the new index is complete, the hot-swap of the old code and index with the new code and index can take place. Just a few lines of code to write, practically no down-time, no index inconsistency so no code failures and a very smooth user experience.

> __Personal Note__: Live-reindexing is tricky per se, but finding a way to perform it easily and regardless the app structure has been an even trickier challenge.

> Live-reindex is very useful also when your app is not changing the index while you are reindexing, for example when your index/indices are updated only periodically. It provides a smooth reindexing with all the features you need, like index renaming, hot-swap, etc.

## Requirements

The live-reindex feature rely on a `redis` list in order to track the changes made by the processes of your running app during the reindex. You need to install redis and the `redis` gem, and/or you may need to add it to your Gemfile.

If you are on a Mac you can install redis with `homebrew`:

{% highlight bash %}
$ brew install redis
{% endhighlight %}

If you are on any other OS, read [redis installation](http://www.redis.io/download).

The `reindex_models` and the `reindex_active_models` methods require the `flex-models` gem (if you use `flex-rails` it is automatically required).

## Usage

The live-reindex feature is very easy to use, but reindexing while the indices and the DBs change is a tricky process, so you must understand the basics about how it works in order to use it properly, or you might corrupt your indices {% see 6.2#important_warnings %}.

The live reindexing should be the last step of your new deployment, performed just before you swap the old code with the new one. It will take care of reindex your data in new index/indices, including the changes being made during the reindexing itself.

> If you deploy with `capistrano`, you should run the reindex method (perhaps in a migration) right before the `create_symlink`

### Index Renaming

The live-reindex process must reindex the data in new indices, so it will automatically create a new index name for each index being reindexed.

The names of the new indices will be prefixed with a timestamp similar to the timestamp prepended to the `ActiveRecord` migrations. For example for an old index named `my_index` (or an old index already prefixed like `20120805095424_my_index`) it will be something like `20130608103457_my_index` (where the prefix is the current timestamp).

When the reindex will be completed each old index involved in the reindexing will be deleted and the new indices will be aliased with the original base name (e.g. unprefixed `my_index`). That means that your app will continue to use e.g. the `my_index` name, but it will automatically point to the new `20130608103457_my_index` index. No intervention is required on your side: you will continue to use the old index basename everywhere in your code and templates, but no surprise when you will inspect a document with a prefixed index name.

> You can always get the original basename, by calling `index_basename` on any elasticsearch document structure.

> All the index, delete and bulk operations made by the process that is running the live-reindex will automatically rename the index to the current timestamped index name. Any other process running during the live-reindex (e.g. your live app) will index, delete and bulk on the old index/indices, so there will be no automatic renaming.

### Tracking Changes

During the reindexing, your live app may change some document in the old index/indices. The changes made to the old index/indices by the live processes are tracked in a redis list and will be indexed at the end of the reindexing. If you configure an `on_each_change` block within the reindex method it will receive (also) the changes done during the reindexing, so giving you the chance to update the new index/indices consistently with the change in the old index/indices {% see 6.2#id2 on_each_change %}.

> All the index, delete and bulk operations made by the process that is running the live-reindex are not tracked because they are performed directly on the new index/indices.

If your indices may get modified by some custom method, by other applications or by some elasticsearch river (none of which uses the above methods), the changes during the reindexing will not be tracked, hence will not be mirrored to the new index/indices. In that case, you must explicitly keep track of the changes by using the `track_change` or the `track_external_change` methods. Pease, take a look at the code and if you need some assistance, send me an email.

## Configuration

There are 4 reindexing methods and they all accept a configuration block. You can use that block in order to define what the reindex should do `on_each_change`, `on_stop_indexing` and in advanced usage also `on_reindex`. For example:

{% highlight ruby %}
Flex::LiveReindex._any_reindexing_method_(my_options) do |config|

  config.on_stop_indexing do
    ...
  end

  config.on_each_change do |action, raw_document_hash|
    ...
  end

  # ignored in all reindexing method but reindex
  config.on_reindex do
    ...
  end

end
{% endhighlight %}

### `on_stop_indexing`

It's important to understand that code and index must constantly match when the app is running: the old code with the old index; the new code with the new index.
So in order to ensure that consistency the live-reindex feature needs to stop the indexing during the swapping (old code and index / new code and index). The elapsed time from the indexing-stop to the indexing-restart will probably be just a few milliseconds or a few seconds at worse, but that is a critical step if you want a consistent and complete index and a smooth swapping. For that reason you must define the `on_stop_indexing` proc that must ensure to prevent all the processes that use the old code to change the index during the swapping (e.g. put the app in maintenance mode, wait for eventual `resque` tasks in the queue to complete before returning, flush the indices, etc.).

The `on_stop_indexing` proc will be called (almost) at the end of the live-reindexing, just before the index swap. Just remember that the reindex methods will: 1) reindex, 2) call the `on_stop_indexing` proc to stop the indexing and 3) swap the old index with the new one. After that you must: 1) swap the old code with the new one and 2) resume the indexing that your proc stopped (or maybe just restart the new deployed app).

> If you deploy with `capistrano`, you should resume the indexing right after the `restart`

You can set the `on_stop_indexing` as a configuration setting in the flex initializer file:

{% highlight ruby %}
Flex::Configuration.on_stop_indexing = proc{Rake::Task('maintenance:start').invoke}
{% endhighlight %}

However you can also define it as a configuration block. For example:

{% highlight ruby %}
Flex::LiveReindex._a_reindex_method_(my_options) do |config|

  config.on_stop_indexing do
    Rake::Task('maintenance:start').invoke
  end

  ...
end
{% endhighlight %}

> The `on_stop_indexing` is explicitly required for your production environment when the index may change during the reindexing. However when your app doesn't change the index, or when you are experimenting in your development environment, you don't need to stop anything, so you can silence the `MissingStopIndexingProcError` error by explicitly pass a `:on_stop_indexing => false` option to the method or set `Flex::Configuration.on_stop_indexing = false`. You may also want to set a different `Flex::Configuration.on_stop_indexing` for different environments.

### `on_each_change`

The `on_each_change` block will receive the action (`'index'` or `'delete'`) as the first argument, and the hash document pulled from elasticsearch. It is expected to optionally change the passed document and return one of the following:

- a Hash with a single key/value pair of action/document: `{ action => document }`, where `document` can be a hash in the same elasticsearch format received by the block or a record/document (flex-models instance) to index/delete.
- an array of Hashes like the above (when you need to split one single action into a few different actions): `[ { action => document },{ action => document }, ... ]`
- a nil value (when you want to skip the indexing/deletion for a particular document)

The returned result(s) will be bulk-processed.

For example:

{% highlight ruby %}
# a simple block
Flex::LiveReindex._any_reindex_method_(my_options) do |config|

  config.on_each_change do |action, raw_document_hash|
    if action == 'index'
      raw_document_hash['_source']['some_field'] = my_transform(raw_document_hash['_source']['some_field'])
      raw_document_hash['_source'].delete('some_other_field')
    end
    # you must return the action and the modified document
    {action => raw_document_hash}
  end

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
Flex::LiveReindex._a_reindex_method_(my_options) do |config|

  config.on_each_change do |action, raw_document_hash|
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

end
{% endhighlight %}

> __Important__: Your `on_each_change` block should not directly store or delete anything, it should only return the (eventually modified) action/documents that the live-reindexing method will index/delete.

If you don't pass any configuration block, the reindex methods will use specific defaults: see the details about each default in the specific method session.

### `on_reindex`

{% see 6.2#id7 reindex %}

## Reindexing Methods

There are 4 different reindexing methods, useful in different contexts but working quite similarly. 2 methods are added by the `flex-models` gem: `reindex_models` and `reindex_active_models`. The other 2 methods are the `reindex_indices` and the generic and advanced `reindex` method. You can use only one of the 4 methods and only one time in one live-reindex session, then you have to swap the code and deploy. If you need to use more than one method, you must do it in different deploys.

> If you try to use more than one of the reindexing method in the same session, the execution of the second method will raise a `MultipleReindexError` error. In that case the first reindexing execution took place regularly (and the error will tell you the new index/indices that have been swapped successfully), but the other reindexing(s) have been aborted so you have still the old index/indices in place. If the code-changes that you were about to deploy rely on the successive reindexings that have been aborted, your app may fail, so you should complete the other reindexing in single successive deploys ASAP.
>
> If you are in development environment and you know what you are doing, you can restart the process and silence that error by passing `:safe_reindex => false`.

If any other (not `MultipleReindexError`) error is raised during the process, the live-reindex will be aborted. In that case, your old index/indices have not been touched at all. The new index/indices being built are probably incomplete, so they have already been deleted by a rescue block, so they left no trace in your elasticsearch server.

### `reindex_models`

> This method is added by the `flex-models` gem: use it to import/reimport `ActiveRecord` and `Mongoid` models.

The `on_each_change` block will receive __ONLY__ the tracked changes at the end of the reindexing.

If you don't configure any `on_each_change` block a default proc will be used. It will simply pull the current record/document from the DB and index it in the new index, or delete the elasticsearch document from the new index in case of a `'delete'` action. That's fine when you don't change the structure of your models, and change only the `flex_source` method for example. But if you delete or rename models, it will fail. In that case you could alias the models or split the changes in 2 deploys, or you  must configure an explicit `on_each_change` block that will receive as usual the action and the document hash pulled from the old elasticsearch index at the moment of the change: you must do the changes in the document (like changing the type for example, or reindexing some other record, etc.) and return the proper result {% see 6.2#id2 on_each_change %}.

#### Full Reindex

You can reindex all the `Flex::Configuration.flex_models`:

{% highlight ruby %}
# if you don't configure any block the method will use a default on_each_change block
Flex::LiveReindex.reindex_models

# explicit on_each_change block
Flex::LiveReindex.reindex_models(my_options) do |config|
  config.on_each_change do |action, raw_document_hash|
    ...
  end
end
{% endhighlight %}

#### Partial Reindex

In case you want to limit the reindexing to a few models (that really changed), you can pass an array of `:models`, but in that case you must also pass the `:ensure_indices` option that will ensure the completeness of the indices being reindexed.

{% highlight ruby %}
Flex::LiveReindex.reindex_models( :models         => [ MyModelA, MyModelB ],
                                  :ensure_indices => [ 'my_index' ] ) do
  ...
end
{% endhighlight %}

The `:ensure_indices` option ensures 2 things:

1. It copies the complete data from the old index to the new one first then it reindexes only the models you listed. That ensures you won't miss any data from the old indices. Besides, in case the index is built by more models, that is faster than reimporting all the models from scratch.
2. It checks whether any record/document in your DB would use any index not specifically listed in the `:ensure_indices` option. That would compromise the safety ensured by point #1, so if that happens, it will abort the reindexing and raise an error that will show you the extra index found. You may want to add it to the `:ensure_indices` array and retry the reindex, so ensuring it will be first copied from the old index.

> Don't use partial reindex to fix a corrupted index, because the `:ensure_indices` option will copy the old (and corrupted) indices first, and reindexing on that copy might not fix the corruption.

> You can also pass other options, that will be forwarded to the `import` task. You can use the symbolic version of the env options (e.g.: `MODELS` > `:models`) {% see 1.4#flex_import flex:import %}.

### `reindex_active_models`

> This method is added by the `flex-models` gem: use it for indexed `ActiveModel` models.

This method works similarly to the `reindex_models` for the options `:models` and `:ensure_indices` and similarly to the `reindex_indices` for the `on_each_change` block. Indeed the `on_each_change` block will be used to pass __ALL__ the documents being reindexed __AND__ the tracked changes at the end of the reindexing. If you don't configure any `on_each_change` block, the index will be copied verbatim into the new index.

The full reindex reindexes all the `Flex::Configuration.flex_active_models` and the partial reindex works similarly to the `reindex_models` method.

### `reindex_indices`

> Use this live reindex method for any index, if you prefer to interact directly with the documents, regardless the models. It migrates directly the content of one or more indices through the `on_each_change` block that you must configure.

The `on_each_change` block will be used to pass __ALL__ the documents being reindexed __AND__ the tracked changes at the end of the reindexing. If you don't configure any block, the index will be copied verbatim into the new index.

You can pass the `:indices` option to limit the indices to migrate: if you don't pass any `:indices` option the default indices of your app will be used (the `:models` option is obviously ignored by this method). For example:

{% highlight ruby %}
# reindex and swap all the known indices without doing any change (not very useful)
Flex::LiveReindex.reindex_indices

# reindex and swap only the 'my_index' and 'my_other_index' indices, changing them with the on_each_change block
Flex::LiveReindex.reindex_indices(:indices => ['my_index', 'my_other_index']) do
  on_each_change do |action, raw_document_hash|
    ...
  end
end
{% endhighlight %}


### `reindex`

> Use this live reindex method if you need to do some special reindexing not covered by any other reindexing method.

All the other reindexing methods have the `on_reindex` block internally configured: the `reindex` method hasn't, so you must configure it with the code you want to be executed in order to reindex, along with the `on_each_change` and eventually with the `on_stop_indexing` blocks. For example, the following will practically perform the same reindexing of the `reindex_model` method (used with the default `on_each_change` block):

{% highlight ruby %}
Flex::LiveReindex.reindex(my_options) do |config|

  config.on_reindex do
    ModelTasks.new.import_models
  end

  config.on_each_change do |action, document|
    if action == 'index'
      begin
        { action => document.load! }
      rescue Mongoid::Errors::DocumentNotFound, ActiveRecord::RecordNotFound
        nil # record already deleted
      end
    else
      { action => document }
    end
  end

end
{% endhighlight %}

## Reindexing from another host

You may want to reindex from another host rather than the host of your live app. The live-reindex needs to connect with the 3 data storages your live app is connected to: elasticsearch, DB(s) and redis. If the reindex host has a transparent replication of all 3 data storages you can use the live-reindex as it were run from the live app host, otherwise you may need to change:

- the `Flex::Configuration.http_client.base_uri`
- the `Flex::Configuration.redis` redis client
- the connection settings for your DBs (if you are reindexing `ActiveRecord` or `Mongoid` models)

If you are using `Rails` you can set it all in a specific environment, that you will use for the reindexing from that host.

## Important Warnings

### Flex Upgrade

When you live-reindex, make sure your live app is running the same version of flex of your new deploy, or you may corrupt your index/indices and/or miss the live changes (made by the old running code during the reindexing). __You should never live-reindex in the same deploy you upgrade flex.__ Instead upgrade, deploy, then live-reindex on one next deploy.

### Flex::Configuration.app_id

When you live-reindex, the `Flex::Configuration.app_id` should be set and match for both the old code (running app) and the new code. If you use `flex-rails` it is already set and matching, however, if you set it explicitly, ensure that the running app processes are using the same id of the new code, or you will miss all the live changes (made by the old running code during the reindexing). In other words, __you cannot set and run it in the same commit/deploy__: instead you should set it, commit and deploy, then make your changes and reindex on the next deploy.

### Safe live-reindex

Live-reindexing is a potentially dangerous process because it deletes the old indices after a "successful" reindexing. Flex considers as "successful" a reindexing that raised no errors, but if you have a bug in any configuration block or forget the couple of warnings above, you may lose or corrupt part of the indices. For that reasons __you should always backup your indices before proceed__, or at least dump the data with the `flex:admin:dump` task. That's very important especially with `Flex::ActiveModel` models, that don't have the data mirrored in a DB. Besides, this is a very new implementation that lacks the time to be tested thoroughly yet, so please, do backup your indices before live-reindexing.
