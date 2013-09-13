---
layout: doc
badge: elastics-models
title: elastics-models - Elastics::ModelIndexer
---

# Elastics::ModelIndexer

> __Notice__: The `Elastics::ModelIndexer` includes also `Elastics::ModelSyncer` {% see 4.4.1 %}

Elastics avoids polluting your models with many methods: indeed it adds just a few methods, all starting with the `elastics_` prefix to avoid confusion:

* `Model.elastics`
* `Model.elastics_in_batches`
* `record.elastics`
* `record.elastics_source`
* `record.elastics_indexable?`

Besides you can define a `Model.elastics_result` method in order to customize the results {% see 2.4#modelelastics_resultresult Model.elastics_result %}

The `Model.elastics_in_batches` is used internally to import the records/documents of the model. It is defined for `ActiveRecord` and `Mongoid` models. You may want to override it if you want to import only a subset of the table/collection (for example if you need to do an incremental import/live-reindex based on a timestamp).

## Class Methods

{% slim indexer_class_methods_table.slim %}

## Instance Methods

You usually don't need to deal with this methods unless you sync manually or have very special needs.

{% slim indexer_instance_methods_table.slim %}
