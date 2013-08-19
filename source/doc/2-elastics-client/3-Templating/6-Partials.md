---
layout: doc
badge: elastics-client
title: elastics-client - Partial Templates
---

# Partial Templates

> __Notice__: you should know about all the Templating section before reading this {% see 2.3.1, 2.3.2, 2.3.3, 2.3.4, 2.3.5 %}.

Elastics Partial Templates are templates that will be inserted into other templates at interpolation time. They are used in a few different ways in order to make the templating system more dynamic and powerful. For example:

{% highlight yaml %}
_a_partial_template:
  foo: <<bar>>

_another_partial_template:
  alpha: <<beta>>

a_template:
  <<_a_partial_template>>
{% endhighlight %}

The name of a partial template must start with `'_'`. Its content can be inserted into another template in a couple of ways: the most common is simply creating a tag with the same name in the other template (in our example the `<<_a_partial_template>>` tag). Then the value of the variable with the same name (in our example the `:_a_partial_template` variable) will determine what will be inserted in place of the tag.

## Partial Template Interpolation

There are a few possible cases of interpolation, depending on the value of the variable with the same partial template name:

{% slim partial_interpolation_table.slim %}

## Example

The most common case of partial usage is when you need to generate a repetition. The structure you pass must be a (possibly empty) Array of Hashes, each hash containing the variables to interpolate with each single repeated fragment. For example:

{% highlight yaml %}
_the_terms:
  term:
    <<attr>>: <<term>>

my_search:
- query:
    bool:
      must:
      - query_string:
          query: <<q= '*' >>
      - << _the_terms= ~ >>
{% endhighlight %}


The `_the_terms` template is a partial, its structure will be repeated and interpolated with the data passed as `:_the_terms` variable and will be inserted in place of `_the_terms` tag. If `:_the_term` is nil (or if it is an empty Array) the partial will be pruned.

Here are a couple possible usages of the same template, and the final data query they produce (translated in YAML for readability):

{% highlight ruby %}
results1 = MyClass.my_search(:_the_terms => [{:attr => 'color', :term => 'blue'}, {:attr => 'year', :term => 1984}, ...])
{% endhighlight %}

{% highlight yaml %}
# produced data query
query:
  bool:
    must:
      - query_string:
          query: "*"
      - term:
          color: blue
      - term:
          year: 1984
      ...
{% endhighlight %}

{% highlight ruby %}
results2 = MyClass.my_search(:q => 'Chevrolet OR Fiat')
{% endhighlight %}

{% highlight yaml %}
# produced data query
query:
  bool:
    must:
      - query_string:
          query: "Chevrolet OR Fiat"
{% endhighlight %}

But you could do the same with less, that may be simpler in your context. This partial would produce exactly the same data query, providing the simpler interpolation values:

{% highlight yaml %}
_the_terms:
  term: <<terms>>
{% endhighlight %}

{% highlight ruby %}
results1 = MyClass.my_search(:_the_terms => [{:terms => {'color'=> 'blue'}}, {:terms => {'year' => 1984}}, ...])
{% endhighlight %}
