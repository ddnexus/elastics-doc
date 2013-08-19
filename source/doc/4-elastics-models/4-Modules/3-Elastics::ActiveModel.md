---
layout: doc
badge: elastics-models
title: elastics-models - Elastics::ActiveModel
---

# Elastics::ActiveModel

The `Elastics::ActiveModel` inclues the `Elastics::ModelIndexer`, which includes `Elastics::ModelSyncer` so you can use their method too {% see 4.4.2, 4.4.1 %}. Besides it includes the `ActiveAttr::Model` module from the [active_attr][], and the `ActiveModel` validations and callbacks, so refer to them for the documentation.

> We list here only the specific methods or overrides that are not documented elsewhere. We also omit the standard CRUD methods that `Elastics::ActiveModel` implements on its own but behave like in standard `ActiveRecord`.

## Class Methods

{% slim activemodel_class_methods_table.slim %}


## Instance Methods

{% slim activemodel_instance_methods_table.slim %}

## Elastics::RefreshCallback

You can include this module if you want elastics to refresh the index automatically. It will add 2 callbacks: `after_save` and `after_destroy` with a call to the `Elastics.refresh_index` API method.
