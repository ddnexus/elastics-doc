---
layout: doc
badge: elastics-client
title: elastics-client - Templates
alias_index: true
---

# Templates

With Elastics Templates you almost don't need to write the code for searching: you can focus on writing bare elasticsearch queries, and Elastics will generate the code for you. You can write all your custom queries in friendly `YAML` instead of `JSON`, add your own placeholder-tags where you want dynamic values instead of static strings, and Elastics will automatically generate the methods to use in your code.

## Usage Overview

{% include template_usage_example.md %}

### Advantages

This approach drastically cuts down time and effort to interface your app to elasticsearch, substancially reducing the whole search logic to a simple `YAML` file {% see 7.3#adding_elastics_templates %}.

Besides, `YAML` adds its own advantages to the whole:

- `YAML` is very easy to write and read, so you can save a lot of typing and squinting
- `YAML` maps 1 to 1 to the `JSON` structures that you need for elasticsearch, so you don't have to learn anything new
- `YAML` natively allows you to define and reuse part of queries into other queries, so you will write less lines, avoiding potential errors

Elastics Templates enforce a clean separation of the elasticsearch logic from the application logic, also allowing elasticsibility: indeed you can keep the elasticsearch queries in a central file, or split them in separated files {% see 2.3.2 %}

Besides, the auto generated methods give you a few other useful advantages for free, without the need to write any code:

* variables validation
* cascading defaults
* data driven dynamic requests
* interpolation

{% see 2.3.4, 2.3.5, 2.3.6 %}

## General Concepts

A basic principle of any templating systems (like ERB, Mustache, etc) is that you define your templates by separating the static part (that doesn't change between renderings) from the dynamic part (that may change each time). That way, a template defines a self-contained logic that needs only a hash of variables to interpolate in order to render the final output.

Elastics Templates use the same basic principles of any templating system, but instead of describing and rendering a text output, its templates describe a http request to the elasticsearch server, that will be interpolated with variables and rendered as the resulting structure returned by elasticsearch.

## Template Types

Elastics implements different types of templates, useful in different context:

* __Generic Templates__ `Elastics::Template` base class
* __Search Templates__ `Elastics::Template::Search` (subclass of `Elastics::Template`)
* __Slim Search Templates__ `Elastics::Template::SlimSearch` (subclass of `Elastics::Template::Search`)
* __Partial Template__ `Elastics::Tempalte::Partial` class

The Generic Templates can handle all sort of requests, but they are mostly useful to internally define all the elasticsearch API Methods {% see 2.2 %}. Indeed you will mostly use Search (or SlimSearch) templates, which are search-specialized subclass of templates, easier to use. Partial Templates are used to generate repeating structures (similar to the ERB Rails partials) or dynamic structures.

### Elastics Generic Templates

> __Notice__: you will probably never have to define Generic Templates, and stick on the simpler Search Templates, however this section explains the basic concepts that apply to all the Template subclasses, so reading it may be useful.

In practice a Elastics Template encapsulates the whole request/response logic that leads to the returned result.

For example, consider this curl request:

{% highlight sh %}
curl -XGET 'http://localhost:9200/my_index/my_type/_search' -d '{"query":{"term":{"user_id":25}}}'
{% endhighlight %}

A very basic and static Elastics template definition (without dynamic interpolation in order to make this example easier) would represent the whole named request in a simple very readable `YAML` fragment:

{% highlight yaml %}
my_request:
  - GET
  - /my_index/my_type/_search
  - query:
      term:
        user_id: 25
{% endhighlight %}

As you see the 'my_request' is a named array, that in this case contains 3 items, that are the http `method`, `path` and `data` arguments that Elastics will use to perform the same curl request above, through an internally created instance of `Elastics::Template` (or any of its subclasses). The missing `base_uri` in the `path` argument is a configuration settings defaulted to 'http://localhost:9200'.

As you see in the previous example, the template definitions are basically named arrays of the arguments that will be internally passed to the `Elastics::Template#new` method in order to create a template instance. In its most complete form they are arrays of 4 items/arguments (being the last 2 optionals):

* http method
* path
* request body (optional data structure understood by elasticsearch)
* variables (optional list of hashes)

Elastics uses the Generic Templates internally, in order to implement the elasticsearch API methods and as the base class for the more specialized and less verbose Search Templates. You will probably never need to define Generic Templates directly, so from now on we will focus on Search Templates. If you need to recur to Generic Templates for any reason, take a look at the templates listed in the API Methods section {% see 2.2 %}.

### Elastics Search Templates

Search Templates are simplified Generic Templates. For an elasticsearch search request, the http method is is always `'GET'` and the path end point is always `'_search'`, so Search Templates omit the first 2 arguments. This is how the above request would be rewritten as a Search Template:

{% highlight yaml %}
my_request:
- query:
    term:
      user_id: 25
{% endhighlight %}

Search Templates are basically named search queries written in `YAML` in a Source file {% see 2.3.2 %}. Comparing the above example with the Generic Template example, you can notice that we removed the path argument and also the index and the type segments with it, so how can we pass them now?

It turns out that `:index` and `:type` are variables that can be set at different levels, and have a nice cascading behavior as any other variable in Elastics. Just to give you the simpler (and lover level) example, you can set them contextually to the method call, by explicitly passing them:

{% highlight ruby %}
results = MyClass.my_request :index => 'my_index', :type => 'my_type'
{% endhighlight %}

Notice however that, variables are very very elasticsible in Elastics, so depending on your app, you can easily avoid to pass them at all, or hard-code them in the template itself. For example if your app uses one single index you may want to set it at a general level, so you will not have to pass it with each request. More about this topic in the Variables section {% see 2.3.4 %}.

Search Templates are also loaded with a different statement, that specify that they are search sources (not just generic sources):

{% highlight ruby %}
elastics.load_search_source 'your/template/search_source.yml'
{% endhighlight %}

{% see 2.3.2 %}

#### Multi Search

Elastics implements also the elasticsearch multi-search capability with a very handy method that allows you to do multiple searches with one request {% see 2.2#YourClass_elastics_multi_search MultiSearch %}

### Elastics Slim Search Templates

Slim Search Templates are just Search Templates that don't retrieve the document `_source`. They are useful to save a little memory when the `_source` is not used directly, for example if you use `result.loaded_collection` which loads the resulting records from the DB(s).

### Elastics Partial Templates

{% see 2.3.6 %}
