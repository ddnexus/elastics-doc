---
layout: doc
title: flex - Template Sources
---

# Template Sources

Notice: you should know about Templates before reading this section {% see 2.2.1 %}.

Flex Template Sources are just `YAML` files that can contain multiple template definitions (being the keys the template names). For example:

{% highlight yaml %}
a_named_template:
  query:
    query_string:
      query: <<the_string>>
  ...

another_named_template:
  query:
    term:
      my_attr: <<the_term>>
  ...
{% endhighlight %}

The magic of loading the source, parsing the templates, instantiating them as objects and make their queries available as methods of your own class is made by adding just a couple of lines to your class:

{% highlight ruby %}
class MyClass
  include Flex::Templates
  flex.load_search_source 'your/template/source.yml'
end
{% endhighlight %}

With that 2 lines you will be able to write for example:

{% highlight ruby %}
result1 = MySearch.a_named_template       :the_string => params[:the_string]
result2 = MySearch.another_named_template :the_term   => params[:the_term]

# or simply
result1 = MySearch.a_named_template       params
result2 = MySearch.another_named_template params
{% endhighlight %}

and so retrieving the results from the elasticsearch server by just calling the generated methods.

## Loader Module

Sources are loaded through the `Flex::Templates` module that you include in your class. You can load one source per class, or more than one source in the same class, even if they are different types of templates. However one source can contain only templates of the same type plus any number of partials templates.

You load different source types with different loading methods (that will use different `Flex::Template::*` classes):

{% highlight ruby %}
class MyClass
  include Flex::Templates
  flex.load_source             'your/template/generic_source.yml'       # uses Flex::Template
  flex.load_search_source      'your/template/search_source.yml'        # uses Flex::Template::Search
  flex.load_slim_search_source 'your/template/slim_search_source.yml'   # uses Flex::Template::SlimSearch
end
{% endhighlight %}

If you put the sources into the `Configuration.flex_dir` path (e.g. `/path/to/flex`) you can avoid to specify the full path:

{% highlight ruby %}
class MyClass
  flex.load_source   :generic_source    # loads '/path/to/flex/generic_source.yml'
  flex.load_source                      # loads '/path/to/flex/my_class.yml'
end
{% endhighlight %}

You can also load your custom subclasses with:

{% highlight ruby %}
flex.load_source_for Your::Flex::Template::Subclass, '/source/path/as/usual'
{% endhighlight %}

### Inline Source

You can also pass the source content string, so defining your templates inline instead in a file:

{%highlight ruby %}
flex.load_search_source <<-yaml
  a_named_template:
    query:
      query_string:
        query: <<the_string>>
    ...

  another_named_template:
    query:
      term:
        my_attr: <<the_term>>
    ...
  yaml
{% endhighlight %}

You can define a single Search Template inline, with the `define_search` method:

{%highlight ruby %}
flex.define_search :a_named_template <<-yaml
  query:
    query_string:
      query: <<the_string>>
    ...
  yaml
{% endhighlight %}

>  __Notice__: since you passed the name of the template as an argument, the `YAML` string defining the source must not include it.

## The 'ANCHORS' key

Any Template Source file may contain an optional `ANCHORS` key, which is simply a literal key that you may use as a sort of storage for fragments of structures. By using the `YAML` anchor/alias mechanism you can reuse them in more than one templates. The following is a real world example:

{% highlight yaml %}
ANCHORS:

  - &not_forbidden_areas
      must_not:
      - terms:
          area_id: << forbidden_areas >>

  - &sort_by_recent
    sort:
    - created: desc

  - &filter_type
    filter:
      term:
        _type: <<filter_type= ~ >>

 ### TEMPLATES ###

last_content:
- query:
    bool:
      <<: *not_forbidden_areas
  <<: *sort_by_recent
  <<: *filter_type

user_activity:
- query:
    bool:
      <<: *not_forbidden_areas
      should:
      - term:
          user_id: <<user_id>>
  <<: *sort_by_recent

{% endhighlight %}

The `'ANCHORS'` key and its content will not be parsed as a template.

> Notice that since version 1.0 you can use any ALL CAPS key as an anchor, and they will not be parsed as a template.

## ERB in the sources

You can use erb tags in any Flex source. It can be useful to get some variable or creating some static loop, that will avoid you to write multiple times the same structure, like in this source snippet:

{% highlight erb %}
search_facets:
- query:
    query_string:
      query: <<q= "*" >>
  facets:
    <% APP_SETTINGS['facets'].each do |name| %>
    <%= name %>:
      terms:
        field: <%= name %>
    <% end %>
{% endhighlight %}

