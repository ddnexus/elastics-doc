---
layout: doc
title: flex-model - ActiveRecord And Mongoid Integration
---

# ActiveRecord And Mongoid Integration

When the data you have to index is managed by `ActiveRecord` or `Mongoid` models, you can keep it transparently synced with the index/indices with just a few declaration at the model level: each time the data will change, the index will be updated in real-time.

Flex can mirror your DBs to the index/indices to the simple 1 to 1 mapping/syncing with just a couple of lines:

{% highlight ruby %}
class MyModel < ActiveRecord::Base
  include Flex::ModelIndexer
  flex.sync self
end
{% endhighlight %}

> Notice that we will use `ActiveRecord` models in these examples, but you can do the same with `Mongoid` models

But most of the times, you need to search just one fraction of the data your app uses, so you don't need to index it all, and you may want to <u>make the index simple to query</u> by organizing it in the most suitable way to ease and improve the performances of your searches.

__Flex allows you to decouple the design of your indices from the structure of your DBs by completely controlling which data get indexed and how and where it gets indexed.__

For example you may have a relational structure with a few tables and you may want to index that data into one single elasticsearch type, skipping some record that wouldn't be useful in the index, indexing only certain related fields from different tables, eventually add some calculated attributes, and certainly, you want also to get the index updated each time any of your table get changed.

Flex allows to do so very easily, by adding a few simple declarations at the model level and/or a few methods to your models, provided by the `Flex::ModelSyncer` or `Flex::ModelIndexer` modules.

## Indexing

The concept of mapping the DB(s) records/documents to some document in the elasticsearch index is very straightforward. For example:

{% highlight ruby %}
class Post < ActiveRecord::Base
  include Flex::ModelIndexer
  flex.index = 'forum'
  flex.type  = 'post'
end
{% endhighlight %}

In this example we set the elasticsearch `index` and `type` explicitly, but we could also omit that and let Flex use the defaults. For example if your application uses just one index named `'forum'`, and you set it in the initializer file, you can omit to declare it in all models. Also the default type for the model class `Post` is `'post'`, so again you can omit to delare it explicitly {% see 2.2.4 %} and `Model.flex.type` in Modules for more details about defaults).

### elasticsearch Parent/Children Relations

If our `Post` `belongs_to` `Thread` you may also want to set that same relation in the `'forum'` index, by using the elasticsearch parent/child feature.

Notice that you don't need to use elasticsearch parent/child relations just because you have a DB relation. That is just in case you want to implement that specific elasticsearch feature, so you have to evaluate its implication. However, if you want it, Flex allows you to implement it in a very simple way, since it will take care of passing the right parent and routing, when indexing and retrieving the document transparently.

{% highlight ruby %}
class Post < ActiveRecord::Base
  include Flex::ModelIndexer
  belongs_to :thread
  flex.parent :thread, 'thread' => 'post'
end
{% endhighlight %}

#### Polymorphism

If you want to use the parent/child feature of elasticsearch automatically from your models, you can map the relationships, both for simple associated models and for polymorphic associations. For example:

{% highlight ruby %}
class Blog < ActiveRecord::Base
  include Flex::ModelIndexer
  flex.sync self
  has_many :comments, :as => :commentable
end

class Review < ActiveRecord::Base
  include Flex::ModelIndexer
  flex.sync self
  has_many :comments, :as => :commentable
end

class Comment < ActiveRecord::Base
  include Flex::ModelIndexer
  belongs_to :commentable, :polymorphic => true
  flex.parent :commentable, 'blog'   => 'blog_comment',
                            'review' => 'review_comment'
  # indexes the record, and its commentable parent when it changes
  flex.sync self, :commentable
end
{% endhighlight %}

The first 2 models have a default type (respectively `blog` and `review`). The Comment model has 2 types: `blog_comment` and `review_comment`, depending on its parent. In other words a comment to a `blog` parent will be of type `blog_comment`, while a comment to a `review` will be of type `review_comment`.

When you create a `Comment` for a review, Flex will index the comment as a `"_type":"review_comment"`, and it will be routed to the right parent's shard transparently. You don't even have to write any explicit mapping, since Flex will do it automatically.

Notice that in order to have the automatic routing and mapping for parent child relationship you must either run the `flex:import FORCE=true` task (which will create a new index), or run the `flex:create_indices` task.

## Indexing Records

By default Flex indexes all the records of the flex models, but you may want to skip the indexing of particular records that may not be useful to index. You have just to define a `flex_indexable?` instance method, returning `true` or `false` based on your own logic.

### record.flex_indexable?

{% highlight ruby %}
def flex_indexable?
  !(title.blank? || text.blank?)
end
{% endhighlight %}

## Indexing Fields

If you just want to index all the fields, nothing more and nothing less, you don't need to do anything, because Flex does that by default. However you are not tied to index the whole record/document as it is. Indeed you can choose which data in the record gets indexed and which doesn't, add calculated attributes (like counts) or embed attributes from other related records, composing the actual `_source` field that elasticsearch will index.

### record.flex_source

If you want to control the data that goes into the index, the only thing you have to do is defining a `flex_source` instance method in your flex model, producing whatever source you want to index. For example:

{% highlight ruby %}
class Parent < ActiveRecord::Base
  include Flex::ModelIndexer
  flex.sync self
  has_many :children
  has_many :not_indexed_models

  def flex_source
    { :title             => title,              # record field
      :text              => text,               # record field
      :children_count    => children.count,     # refers to associated models
      :not_indexed_model => not_indexed_models, # refers to associated models
      :random_number     => random(10000)       # calculated attribute
    }
  end
end

class Child < ActiveRecord::Base
  belongs_to :parent
  include Flex::ModelIndexer
  flex.sync self, :parent
end

class NotIndexedModel < ActiveRecord::Base
  belongs_to :parent
  include Flex::ModelSyncer
  flex.sync :parent
end
{% endhighlight %}

In the `flex_source` method of the example, the only attributes coming from the records are `title` and `text`, the other attributes are either coming from other records or simply calculated.

Besides each time a `Child` or a `NotIndexedModel` changes, the callbacks will reindex the parent document. Notice that the children that are referred or embedded may be synced on their own (like `Child`) or not (like `NotIndexedModel`) {% see 4.4.1 %}.

**Notice**: Since version `0.5.0` syncing manages also to avoid circular references: a parent and a children could sync each other and everything will work as expected.

## Methods

{% see 4.4.2, 4.4.1 %}
