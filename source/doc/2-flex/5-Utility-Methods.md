---
layout: doc
title: flex - Utility Methods
---

# Utility Methods

Flex defines some utility class methods: a few are useful for collection management, and a few are mostly useful for quick prototyping and debugging.

## Collection Management Methods

This methods are mostly used internally by the rake tasks {% see 1.4 %}, but in special cases you may need to use them directly.

### Flex.process_bulk(args)

This method accepts a `:collection` of objects, that can be hashes or Models, creates the formatted bulk data-string suitable to be passed to the elasticsearch server for bulk operations, and posts them. You can pass an `:action` that can be 'index' (default) or 'delete', and also a few other arguments like: `:index`, `:type`, `:version`, `:routing`, `:percolate`, `:parent`, `:timestamp`, `:ttl` that will be used as default for all the documents in the collection.

**Notice**: If you have an already formatted bulk data-string you should use `Flex.bulk` {% see 2.6#flexbulk Flex.bulk %}, in order to bulk-index or bulk-delete the whole collection.

### Flex.import_collection(collection, args)

It just calls `Flex.process_bulk` setting the `:collection` to the first argument, and the `:action` to `"index"`

### Flex.delete_collection(collection, args)

It just calls `Flex.process_bulk` setting the `:collection` to the first argument `:action` to `"delete"`

## Curl-like Methods

You can use the methods `HEAD`, `GET`, `PUT`, `POST`, `DELETE` exactly as you would do with curl (also enforced by the unconventional upcase naming).

They accept 3 arguments:

* path (required): It will be joined with the `Flex::Configuration.base_uri` (default `http:://localhost:9200`) to build the url
* data (optional): The data structure to send with the request (if needed). It can be a JSON or YAML string or a ruby structure.
* variables (optional): the usual variable hash used for interpolation (in case you use tags in the path or in the data)

For example:

{% highlight ruby %}
# with JSON
Flex.GET '/_search', '{"query":{"match_all":{}}}'

# same thing with a ruby structure
Flex.GET '/_search', {:query => {:match_all => {}}}

# same thing with YAML
Flex.GET '/_search', <<-yaml
query:
  match_all: {}
yaml

# using also tags and variables (for the sake of it)
Flex.GET '/_search', '{"query":{"<<a_tag>>":{}}}', :a_tag => 'match_all'
Flex.GET '/_search',  {:query => {'<<a_tag>>' => {}}}, :a_tag => 'match_all'
Flex.GET '/_search', <<-yaml, :a_tag => 'match_all'
query:
  <<a_tag>>: {}
yaml
{% endhighlight %}

## Other methods

### Flex.search

This method allows you to define and use a Search Template {% see 2.2.1#flex_search_tempaltes %} on the fly. It is very useful in the console or for quick prototyping, but it is not as efficient as a regular Template loaded from source (which gets compiled), so don't use it in your production code.

For example:

{% highlight ruby %}
result = Flex.search <<-yaml, :index => 'a_non_default_index'
query:
  match_all: {}
yaml
{% endhighlight %}

As the curl-like methods, the data can be a `JSON` or `YAML` string or a `ruby` structure, and you can also pass the optional variable hash as usual.

### Flex.slim_search

Same as `Flex.search` but uses a Slim Search Template {% see 2.2.1#flex-slim_search_templates %}.

### Flex.json2yaml

Converts a `JSON` string to a `YAML` string

### Flex.yaml2json

Converts a `YAML` string to a `JSON` string

