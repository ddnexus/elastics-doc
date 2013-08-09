---
layout: doc
title: flex-models - Flex::ModelIndexer
---

# Flex::ModelIndexer

> __Notice__: The `Flex::ModelIndexer` includes also `Flex::ModelSyncer` {% see 4.4.1 %}

Flex avoids polluting your models with many methods: indeed it adds just 1 class method and 3 instance methods, all starting with the `flex` prefix to avoid confusion:

* `Model.flex`
* `record.flex`
* `record.flex_source`
* `record.flex_indexable?`

Besides you can define a `Model.flex_result` method in order to customize the results {% see 2.4#modelflex_resultresult Model.flex_result %}

## Class Methods

{% slim indexer_class_methods_table.slim %}

## Instance Methods

You usually don't need to deal with this methods unless you sync manually or have very special needs.

{% slim indexer_instance_methods_table.slim %}
