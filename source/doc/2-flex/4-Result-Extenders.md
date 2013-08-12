---
layout: doc
title: flex - Result Extenders
---

# {{ page.title }}

Each result that comes from a Flex request is the same data structure that comes from the elasticsearch response. It is the untouched structure (hash) that you would expect from the request you did, so you can always inspect and interact with it directly.

However Flex implements also a mechanism that allows to extend the structure in place, with the useful methods that makes sense with the particular result retrieved. Flex do so with a few Extender modules, that extend the original `Flex::Result` hash object. Writing your own extender is extremely easy and recommended for more specialized methods.

For example the structure returned from a search query, is the regular structure that elasticsearch serves, but you can call more methods on that hash or on part of that structure, because Flex extends them in place. For example:

{% highlight ruby %}

# search the index
result = MyClass.my_search :my_tag => 'the tag value'
#=> { ... tipical response from elasticsearch ... }

# get the document directly from the elasticsearch structure
collection = result['hits']['hits']
#=> [ ... the hits array ... ]

# or use a method added by flex
collection = result.collection
#=> [ ... same object as above ... ]

# also the collection array is extended with the tipical methods for pagination as well
collection.is_a?(Array) #=> true
collection.total_entries
collection.per_page
collection.total_pages
collection.current_page

# the documents gets also extended
document = collection.first
document.id
document.type
document.any_attribute
{% endhighlight %}

The important concept to know is that the Flex extension mechanism leaves the elasticsearch structure received always intact, it just extends the structure with utility methods and shortcuts where it makes sense.

## Flex Result Extenders

The `flex` gem comes with a few extenders (documented here) and more are added by other gems {% see 4.5 %}. They are applied to the particular structure they make sense for. So a single structure could be extended by more than one extender or by none, depending on what applies to that structure.

* __`Flex::Result::Search`__<br>
  It extends the results coming from a search query. It adds the following methods:

  * __`result.collection`__<br>
    It is the shortcut to `result['hits']['hits']` from search results. The collection is extended by the typical pagination methods {% see 2.4#flexresultcollection Flex::Result::Collection %}, Besides, each hit in the array gets extended also by the `Flex::Result::Document` extender (see below).

  * __`result.facets`__<br>
    Just a shortcut for `result['facets']`

* __`Flex::Result::MultiGet`__<br>
  It extends the results coming from a multi-get query. It adds the following methods:

  * __`result.docs`__ or __`result.collection`__<br>
    It is the shortcut to `result['docs']` from multi-get results. The collection is extended by the typical pagination methods {% see 2.4#flexresultcollection Flex::Result::Collection %}, Besides, each hit in the array gets extended also by the `Flex::Result::Document` extender (see below).

* __`Flex::Result::Document`__<br>
  Applies to documents that contain (at least, but not limited to) `_index`, `_type`, `_id`. It adds the following methods:

  * __`document.index`__, __`document.type`__, __`document.id`__<br>
    Shortcuts methods pointing to `document['_index']`, `document['_type']`, `document['_id']`

  * __`document.index_basename`__<br>
    Returns the unprefixed index name:  `my_index` for the `20130608103457_my_index` index {% see 6.2#index_renaming %}.

  * __`method_missing`__<br>
    This module extends the `_source` by supplying object-like readers methods. It also exposes the meta fields like \_id, \_source, etc. For example:

* __`Flex::Result::Bulk`__<br>
  Applies to the responses returned after sending a bulk post. Used internally by the `flex::import` rake task {% see 1.4 %}. Adds the following methods:

  * __`successful`__<br>
    Array of the items that elasticsearch marked as 'ok'

  * __`failed`__<br>
    Array of the items that elasticsearch marked as not 'ok'

## Flex::Result::Collection

Provides the pagination-like methods and aliases in order to support both `will_paginate` and `kaminari`

* `total_entries`
* `per_page`
* `total_pages`
* `current_page`
* `previous_page`
* `next_page`
* `offset`
* `out_of_bounds?`
* `limit_value`
* `total_count`
* `num_pages`
* `offset_value`

## Custom Result Extenders

An extender is simply a module that is included in the `Flex::Configuration.result_extenders` array. You can manipulate that array if you wish, by adding or removing modules, so adding or removing methods to the original result structure returned by elasticsearch. For example, let's say that you would like to be able to do:

{% highlight ruby %}
result = MySearch.some_search
custom_structure = result.type_counts
{% endhighlight %}

and the `type_counts` should do some arbitrary aggregation on the returned facet counts, returning a custom structure that you need to pass around.

First you write a module with the methods that will be used to extend the original result. A simplified real world example:

{% highlight ruby %}
module MyExtender

  # returns a structure like:
  # {:total=>294, :blogs=>5, :projects=>1, :products=>1, :forums=>287}
  def type_counts
    counts = Hash.new(0)
    self['facets']['type_counts']['terms'].each do |t|
      term = t['term'] + 's'
      counts[term.to_sym] = t['count']
    end
    counts[:forums] = counts[:threads] + counts[:posts]
    counts[:total] = self['facets']['type_counts']['total']
    counts
  end

  # tells Flex whether to extend the result with this module or not
  def self.should_extend?(result)
    result.response.url =~ /\b_search\b/ && result['facets'] && result['facets']['type_counts']
  end

end
{% endhighlight %}

 Notice that in that module `self` is the returned elasticsearch structure. As you see the method `type_counts` elaborates the facets 'type_counts' returning the custom structure that we need.

Also notice that unless we want to extend ALL the results returned from elasticsearch, we define a `should_extend?` class method that will check if the result contains what we expect, so extending only when it makes sense.

Now you want to add it to the list of extenders (usually in the `flex.rb` initializer if you are doing it in Rails)

{% highlight ruby %}
Flex::Configuration.result_extenders << MyExtender
{% endhighlight %}

You could have done the same thing with an external helper, passing it the facet object, something like:

{% highlight ruby %}
result = MySearch.some_search
custom_structure = type_count(result.facets)
{% endhighlight %}

It all depends whether you want to put the logic of what you are doing. Personally I prefer the first approach, which looks more OO and self-contained, specially if you have a lot of result related methods, but in this particular case even the functional approach might be OK.

### Model.flex_result(result)

If your context class defines it, it is internally called by flex just before returning the result, so you can change it as you prefer, maybe creating objects, extending, checking, whatever. You have also access to the final variables through the passed result. For example:

{% highlight ruby %}
def self.flex_result(result)
  vars = result.variables
  vars[:my_class_wrapper] ? vars[:my_class_wrapper].new(result) : result
end
{% endhighlight %}
