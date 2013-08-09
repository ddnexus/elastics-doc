---
layout: doc
title: flex-models - Result Extenders
---

# {{ page.title }}

The `flex-models` gem adds a few extender to the standard extended `Flex::Result` object {% see 2.4 %}. They are aware of your models, so you can do, for example:

{% highlight ruby %}

# search the index
result = MyClass.my_search :my_tag => 'the tag value'

# retrieve the document from the index as usual
collection = result.collection
#=> [ ... the hits array ... ]

# you can load one record at a time
document = result['hits']['hits'][0]
document.load
#=> #<Project id: 167017 ...> # ActiveRecord object loaded from the DB

# or easier
collection.first.load
#=> #<Project id: 167017 ...> # same thing

# or retrieve all the records from your DB in one go
loaded_collection = result.loaded_collection
#=> [ #<Project id: 167017 ...>, #<Comment id: 2342 ...>, ... ]

# notice that record can belong to different models

{% endhighlight %}

## Flex Model Result Extenders

* __`Flex::Result::SearchLoader`__<br>
  It extends the results coming from a search query. It adds the following method:

  * __`result.loaded_collection`__<br>
    This method takes the index, types and ids from the collection, map them back to your original models, and query the DB with as less as possible queries, returning a collection of records (instead of a collection of elasticsearch documents). The records might be composed of mixed classes, depending on what you retrieved.

    > This is an operation that requires an extra query per each type returned. For example if your collection contains 20 documents of a total of 3 different types, it generates 3 extra DB queries to retrieve the original models. For this reason it should be used only when the performance is not a problem, besides, when you use it, you can avoid to load the document source, by using `Flex::Template::SlimSearch` templates, which are just regular Search Templates, that don't retrieve the source that in this case is not needed.

* __`Flex::Result::DocumentLoader`__<br>
  Applies to documents that contain (at least, but not limited to) `_index`, `_type`, `_id`. It adds the following method:

  * __`document.load`__<br>
    Maps the document back to the original model and class and retrieves it from the DB.

  * __`document.load!`__<br>
    Like `document.load` but raises a `Flex::DocumentMappingError` if it cannot find the model class for the document.

* __`Flex::Result::ActiveModel`__<br>
    It extends the results when the `context` class (your class) includes `Flex::ActiveModel`. It adds the following methods:

  * __`result.get_docs`__<br>
    This method is used internally, in order to build the objects of your `Flex::ActiveModel` extended class, out of the raw elasticsearch result.

    > You will seldom need to use this method, unless you pass `:raw_result => true`.
