---
layout: doc
badge: elastics-models
title: elastics-models - Overview
alias_index: true
---

# {{ page.title }}

The `elastics-models` gem provides the means to map and sync your data to elasticsearch. Its interface tries to be as minimalistic and declarative as possible and can integrate your models with elasticsearch basically in 2 ways, handy in different contexts.

## 1. Transparent integration with ActiveRecord and Mongoid models

> This is useful when the data you need to index is in some DB(s) managed by your application.

Index and keep automaticaly synced your DBs with elasticsearch with just a few declarations in your models. You can mirror 1 to 1 your DBs to the index/indices, but you can also map any DB structure to any index structure you may design in order to ease the querying. You have the complete control over which data gets indexed and how it gets indexed, transparently managing elasticsearch parent/child relationships, also polymorphic {% see 4.2, 7.3 %}.

## 2. Direct integration throught ActiveModel

> This is useful when the index doesn't come from data in any DB(s) or when you want to use the elasticsearch index as a data storage.

Manage the elasticsearch index as it were a DB, through `ActiveModel` models. Get validations and callbacks, typecasting, attribute defaults, persistent storage, with optimistic lock update, finders, chainable scopes etc. {% see 4.3, 7.4 %}

## Setup

Elastics needs to know your Elastics models, and in which order you want them to be imported in the index (in case of bulk import of the DB and parent/child relations), so each time you add a `include Elastics::ModelIndexer` or `include Elastics::ActiveModel` statement, remember to add the model class name to the `config.elastics_models` and/or `config.elastics_active_models` arrays in the initializer file.

{% highlight ruby %}
config.elastics_models = %w[ Thread Post ]
config.elastics_active_models = %w[ WebContent ]
{% endhighlight %}

## Elasticsearch Mapping

Elastics provides a default mapping that keeps into consideration also your parent/child relations, and the properties declared for `Elastics::ActiveModel` models. The default mapping is deep-merged with your `elastics.yml` file {% see 1.3 %}, that is expected to contain all the mapping that you may want to define/override, written in friendly `YAML`.

Notice that in order to have the automatic routing and mapping for parent/child relationships you must either run the `elastics:import FORCE=true` task (which will create a new index), or the `elastics:index:create` task {% see 1.4 %}.

## Dynamic Indices

You can implement dynamic indices very easily by just defining an instance method in your model:

{% highlight ruby %}
def elastics_index
  old_creation_date? ? 'old_index' : 'new_index'
end
{% endhighlight %}

> You can also override other metafields by defining a similar method {% see 4.4.2#overriding_elastics_metafields %}
