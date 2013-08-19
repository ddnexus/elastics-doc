---
layout: doc
badge: elastics-models
title: elastics-models - Elastics::ModelIndexer
---

# Elastics::ModelIndexer

> __Notice__: The `Elastics::ModelIndexer` includes also `Elastics::ModelSyncer` {% see 4.4.1 %}

Elastics avoids polluting your models with many methods: indeed it adds just 1 class method and 3 instance methods, all starting with the `elastics_` prefix to avoid confusion:

* `Model.elastics`
* `record.elastics`
* `record.elastics_source`
* `record.elastics_indexable?`

Besides you can define a `Model.elastics_result` method in order to customize the results {% see 2.4#modelelastics_resultresult Model.elastics_result %}

## Class Methods

{% slim indexer_class_methods_table.slim %}

## Instance Methods

You usually don't need to deal with this methods unless you sync manually or have very special needs.

{% slim indexer_instance_methods_table.slim %}
