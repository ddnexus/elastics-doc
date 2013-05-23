---
layout: doc
title: flex - Interpolation
---

# Interpolation

> __Notice__: you should know about all the Templating section before reading this {% see 2.2.1, 2.2.2, 2.2.3, 2.2.4 %}.

Flex Templates describe a structure (or a partial structure) that basically reflects the elasticsearch API while tags identify the place where your app can interpolate values or other partial structures. The _interpolation_ is the internal process that creates the actual structure that get sent to the elasticsearch server. This process is driven by the interpolation values, i.e. the runtime data in your application, stored into various `Flex::Variables` hashes {% see 2.2.4 %}.

For example, the following template has the tag `bar` that will be interpolated with the value passed as the `:bar` variable:

{% shighlight yaml %}
my_template:
  foo: <<bar>>
{% endshighlight %}

## Template Interpolation

The data structure sent to the elasticsearch server is dynamically modified by the kind of interpolated value present in your application. Indeed different types of values originate different kind of replacement.

{% slim interpolation_table.slim %}

The replacements for the first 2 type of values are very obvious: if you pass a string or a numeric value it will be simply substituted in place of the respective tag, if you pass any data structure it will just be inserted in place of the tag, so extending the template structure on the fly. The pruning is explained in the next section.

## Pruning

The pruning is a very useful feature, that makes your query much more dynamic and your templates easier to write. When a tag is evaluated as `nil`, `false`, or as an empty `String`, `Array` or `Hash` it obviously produces no output value, but it also causes the removal (pruning) of the parts of the templates that are using it. Indeed their existence wouldn't make sense if they carry a nil/empty value. In other words a nil/empty value will not just be evaluated as a mere empty string while building the request (which would produce a malformed request), but it will actively modify the template structure, and thus the request structure itself.

The pruning is done automatically as the last step of the interpolation. It can occur in the path or in the data tree. If the pruning occurs in the `path`: a nil tag will remove the segment where it is defined, generating a canonical path (i.e. no double slashes). For example:

{% highlight yaml %}
- /<<index>>/<<type>>/_search
{% endhighlight %}
{% highlight ruby %}
{:index => 'a', :type => 'b'} # would produce '/a/b/_search
{:index => nil, :type => 'b'} # would produce '/b/_search'  (not '//b/_search')
{:index => 'a', :type => nil} # would produce '/a/_search'  (not '/a//_search')
{:index => nil, :type => nil} # would produce '/_search'    (not '///_search')
{% endhighlight %}

If the pruning occurs in the data tree, then the entire branch that ends in a nil/empty leaf will be pruned. For example:

{% highlight yaml %}
- a:
    b:
      c: <<tag_c>>
    d:
      e: <<tag_e>>
  f: 12
{% endhighlight %}
{% highlight ruby %}
{:tag_c => 3,   :tag_e => 4}   # would produce {"a":{"b":{"c":3}, "d":{"e":4}}, "f":12}
{:tag_c => nil, :tag_e => 4}   # would produce {"a":{"d":{"e":4}}, "f":12}
{:tag_c => 3,   :tag_e => nil} # would produce {"a":{"b":{"c":3}}, "f":12}
{:tag_c => nil, :tag_e => nil} # would produce {"f":12}
{% endhighlight %}

> __Notice__: You can skip the pruning of arbitrary keys that are expected to containing nil/empty values by just adding them to the `:no_pruning` variable.

Pruning also perform `compact` and `flatten` on `Array` values. That allows easier writing of templates that would be impossible in certain `YAML` structures, like for example extending an array with more items.

If you want to extend the array `[{"a":1},{"b":2}]` with more elements in `{:array_tag => [{"c":3},{"d":4},{"e":5}]}`, the following fragment would generate a YAML parsing error:

{% highlight yaml %}
- a: 1
- b: 2
<<array_tag>>
{% endhighlight %}

so you can write:

{% highlight yaml %}
- a: 1
- b: 2
- <<array_tag>>
{% endhighlight %}
and the interpolation-pruning will `flatten` and `compact` the structure, resulting in the final `[{"a":1},{"b":2},{"c":3},{"d":4},{"e":5}]` array.

Pruning is very useful when you have queries that should be generated dynamically based on values that may or may not be defined, for example boolean queries or facets. With pruning you have just to pass empty values (or don't pass the value at all) in order to build and send pruned requests that matches the values you passed. Besides, by pairing auto-pruning with partials templates you can generate highly dynamic data driven queries with just a few lines of yaml.

## Partial Template Interpolation

{% see 2.2.6#partial_tempate_interpolation %}


## Variable Check

The interpolation process is aware of the required variables. It raises an error if you miss any variable when you call a flex-generated method.
