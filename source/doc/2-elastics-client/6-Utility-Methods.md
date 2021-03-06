---
layout: doc
badge: elastics-client
title: elastics-client - Utility Methods
---

# Utility Methods

Elastics defines some utility class methods: a few are useful for bulk management, and a few are mostly useful for quick prototyping and debugging.


## Curl-like Methods

You can use the methods `HEAD`, `GET`, `PUT`, `POST`, `DELETE` exactly as you would do with curl (also enforced by the unconventional upcase naming).

They accept 3 arguments:

* path (required): It will be joined with the `Elastics::Configuration.base_uri` (default `http:://localhost:9200`) to build the url
* data (optional): The data structure to send with the request (if needed). It can be a JSON or YAML string or a ruby structure.
* variables (optional): the usual variable hash used for interpolation (in case you use tags in the path or in the data)

For example:

{% highlight ruby %}
# with JSON
Elastics.GET '/_search', '{"query":{"match_all":{}}}'

# same thing with a ruby structure
Elastics.GET '/_search', {:query => {:match_all => {}}}

# same thing with YAML
Elastics.GET '/_search', <<-yaml
  query:
    match_all: {}
  yaml

# using also tags and variables (for the sake of it)
Elastics.GET '/_search', '{"query":{"<<a_tag>>":{}}}', :a_tag => 'match_all'
Elastics.GET '/_search',  {:query => {'<<a_tag>>' => {}}}, :a_tag => 'match_all'
Elastics.GET '/_search', <<-yaml, :a_tag => 'match_all'
query:
  <<a_tag>>: {}
yaml
{% endhighlight %}

## Bulk Support

This methods are mostly used internally by the rake tasks {% see 1.4 %}, but you may want to use them directly.

### Elastics.post_bulk_collection

This method accepts a `collection` of objects as the first argument and a hash of options. It passes each object in the `collection` (and the options) to the `Elastics.build_bulk_string` and collects the formatted bulk string and posts it.

**Notice**: If you have an already formatted bulk string you should use `Elastics.post_bulk_string` {% see 2.2#Elastics_post_bulk_string Elastics.post_bulk_string %}.

### Elastics.build_bulk_string

Accepts an object as the first argument and a hash of options. The object can be a `Hash` in the same format of the elasticsearch document results, or a record/document (elastics-models instance).

 You can pass an `:action` option that can be `'index'` (default), `'create'`, `'update'` or `'delete'`. It will return the bulk string understood by the [elasticsearch bulk API](http://www.elasticsearch.org/guide/reference/api/bulk/), that can be joined with other bulk strings in order to collect the complete bulk string to pass to the `Elastics.post_bulk_string` method.

## Other methods

### Elastics.reload!

This method is useful in the console, when you are editing some template source: it reloads all the sources, so you can try the changes without restarting the console.

### Elastics.search

This method allows you to define and use a Search Template {% see 2.3.1#elastics_search_tempaltes %} on the fly. It is very useful in the console or for quick prototyping, but it is not as efficient as a regular Template loaded from source (which gets compiled), so don't use it in your production code.

For example:

{% highlight ruby %}
result = Elastics.search <<-yaml, :index => 'a_non_default_index'
           query:
             match_all: {}
         yaml
{% endhighlight %}

As the curl-like methods, the data can be a `JSON` or `YAML` string or a `ruby` structure, and you can also pass the optional variable hash as usual.

### Elastics.slim_search

Same as `Elastics.search` but uses a Slim Search Template {% see 2.3.1#elastics-slim_search_templates %}.

### Elastics.json2yaml

Converts a `JSON` string to a `YAML` string

### Elastics.yaml2json

Converts a `YAML` string to a `JSON` string

## Quasi API Methods

{% see 2.2#elastics_additions %}

