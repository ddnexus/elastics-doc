---
layout: doc
title: flex-model - Overview
alias_index: true
---

# {{ page.title }}

The `flex-model` gem provides the means to map and sync your data to elasticsearch. Its interface tries to be as minimalistic and declarative as possible and can integrate your models with elasticsearch basically in 2 ways, handy in different contexts.

## 1. Transparent integration with ActiveRecord and Mongoid models

> This is useful when the data you need to index is in some DB(s) managed by your application.

Index and keep automaticaly synced your DBs with elasticsearch with just a few declarations in your models. You can mirror 1 to 1 your DBs to the index/indices, but you can also map any DB structure to any index structure you may design in order to ease the querying. You have the complete control over which data gets indexed and how it gets indexed, transparently managing elasticsearch parent/child relationships, also polymorphic {% see 4.2 %}.

## 2. Direct integration throught ActiveModel

> This is useful when the index doesn't come from data in any DB(s) or when you want to use the elasticsearch index as a data storage.

Manage the elasticsearch index as it were a DB, through `ActiveModel` models. Get validations and callbacks, typecasting, attribute defaults, persistent storage, with optimistic lock update, finders, chainable scopes etc. {% see 4.3 %}

## Setup

Flex needs to know what are your Flex models, and in which order you want them to be imported in the index (in case of bulk import of the DB and parent/child relations), so each time you add a `include Flex::ModelIndexer` or `include Flex::ActiveModel` statement, remember to add the model class name to the `config.flex_models` array in the initializer file. Remember also that parents go first.

{% highlight ruby %}
config.flex_models = %w[ Thread Post ]
{% endhighlight %}

## elasticsearch Mapping

Flex provides a default mapping that keeps into consideration also your parent/child relations, and the properties declared for `Flex::ActiveModel` models. The default mapping is deep-merged with your `flex.yml` file {% see 1.3 %}, that is expected to contain all the mapping that you may want to define/override, written in friendly `YAML`.

Notice that in order to have the automatic routing and mapping for parent/child relationships you must either run the `flex:import FORCE=true` task (which will create a new index), or the `flex:index:create` task {% see 1.4 %}.
