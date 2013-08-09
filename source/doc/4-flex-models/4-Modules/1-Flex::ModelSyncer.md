---
layout: doc
title: flex-models - Flex::ModelSyncer
---

# Flex::ModelSyncer

> __Notice__: Syncing is not needed if you use other external means to sync (like rivers or background jobs).


The `Flex::ModelSyncer` model is included in `Flex::ModelIndexer` which is included in `Flex::ActiveModel`, so they all include the sync-related methods {% see 4.4.1#class_methods, 4.4.1#instance_methods %}. However you may need to explicitly include the `Flex::ModelSyncer` {% see 4.4.1#including_flexmodelsyncer Including Flex::ModelSyncer %}.

## Syncing self

Each time you save or destroy a record belonging to a flex model, you may want to sync the changes with the index. You can implement automatic synchronization by just declaring it. For example:

{% highlight ruby %}
class Comment
  include Flex::ModelIndexer
  flex.sync self
end
{% endhighlight %}

That means that each time a Comment record gets saved or destroyed, Flex will sync `self` (the `Comment` instance) with its related elasticsearch document, so the index will always contain the updated data from the DB(s).

## Syncing relating models

Sometimes, you may need to sync also other records that are related with the changing record. That is needed when the other record embeds data from the changing record, as in our example with the `Parent` model {% see 4.2#indexing_fields %}. In that case we mapped the indexed source to contain the `children.count`, so each time we add or remove a `Child` record, we need also to sync its `:parent` record (i.e. the `self.parent`). For example:

{% highlight ruby %}
class Child
  belongs_to :parent
  include Flex::ModelIndexer
  flex.sync self, :parent
end
{% endhighlight %}

That means that besides syncing `self`, Flex will also sync the `:parent` parent record.

## Propagation

Notice that Flex calls `sync` on the synced records as well, so also their defined synced models will be synced as well. This feature automatically propagates the syncronization over models, still keeping its implementation very simple on a per-model basis.

Flex tracks the propagation, so it avoids circular references. For example you can sync both the parent from the child and the child from the parent and it will work in either ways, because the propagation will not go backward.


## Including Flex::ModelSyncer

Sometimes you may have a model that doesn't need to be indexed as a document, however part of its data is referred (and indexed) as part of another model. In that case you don't need the full fledged `Flex::ModelIndexer` which will add typical index related capabilities to your model (like `index`, `type`, `store`, `remove`, ...). Indeed you need just to `sync` some other referring model(s). For example:

{% highlight ruby %}
class NotIndexedModel
  belongs_to :parent
  include Flex::ModelSyncer
  # parts of the data of this model are referred in :parent and :other_model
  flex.sync :parent, :other_model

  def other_model
    # should return the record that needs to be synced
  end

end
{% endhighlight %}

In this example, each time a `NotIndexedModel` record changes, the `:parent` and the `:other_model` records will be synced. Notice that a `Flex::ModelSyncer.sync` cannot sync `self`: indeed you included that module instead of `Flex::ModelIndexer` exactly because you don't need to sync `self`. :-)

## Class Methods

{% slim syncer_class_methods_table.slim %}

## Instance Methods

{% slim syncer_instance_methods_table.slim %}
