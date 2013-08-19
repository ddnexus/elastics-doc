---
layout: doc
badge: elastics-scopes
title: elastics-scopes - Overview
alias_index: true
---

# {{ page.title }}

The `elastics-scopes` gem implements the same concept of the `ActiveRecord` scopes: they define search criteria that can be used (reused and merged) to query the elasticsearch indices in pure ruby.

## Built-in Scopes

There are a few built-in scopes, like `terms`, `range`, `sort`, `fields`, `script_fields`, etc. that you can use to define some search criteria. For example:

{% highlight ruby %}
class MyClass
  include Elastics::Scopes
end

red_scope   = MyClass.terms :color => 'red'
cheap_scope = MyClass.range :price => {:to => '99.99'}
{% endhighlight %}

{% see 3.2#filter_scopes, 3.2#variable_scopes %}

## Query Scopes

On that search criteria, you can call any of the query scopes like the usual `find`,  `count`, `delete`, `first`, `last`, `all`, etc.:

{% highlight ruby %}
first_red   = red_scope.first
cheap_count = cheap_scope.count
{% endhighlight %}

> __Notice__: The query scopes return the actual result from querying elasticsearch, not a scope.

{% see 3.2#query_scopes %}

## Chaining Scopes

You can also chain scopes in different ways, so they will return a resultig scope including all the search criteria chained together (that is a sort of deep-merging of scopes). Then, you can call any finder method on the resulting scope:

{% highlight ruby %}
# default and
red_and_cheap = red_scope.cheap_scope
# same thing but with explicit and
red_and_cheap = MyClass.and{ red_scope.cheap_scope }
red_or_cheap  = MyClass.or{ red_scope.cheap_scope }

first_red_and_cheap = red_and_cheap.first
{% endhighlight %}

## Custom Named Scopes

You can also define your own custom named scopes with the `scope` method, also passing arguments, and chain them with other scopes:

{% highlight ruby %}
class MyClass
  include Elastics::Scopes

  scope :red, terms(:color => 'red')

  scope :size do |size|
    terms(:size => size)
  end

  scope :cheaper_than do |p|
    range :price => {:to => p}
  end

end

my_scope      = MyClass.red.size('big')
all_big_red   = my_scope.all
big_red_cheap = my_scope.cheaper_than(10).all

in_range_scope = MyClass.range :price =>{:from => 10, :to => 99.99}
first_in_range = in_range_scope.first

{% endhighlight %}

{% see 3.2#scope scope, 3.2#scoped scoped%}

## Elastics Module

The `elastics-scopes` gem automatically extends also the `Elastics` module, so you can use any scope directly on `Elastics`. For example:

{% highlight ruby %}
Elastics.query('big AND red').first(:index => 'my_index', :type => 'my_type')
{% endhighlight %}

## Chosing the right tool

Elastics scopes are cool tools, very useful in most situations, particularly when the search criteria are quite simple, however, when the search criteria get more complex, using templates may be a cleaner technique {% see 2.3.2 %}.

For that reason, the `elastics-scopes` gem is not a complete interface to the elasticsearch search API: it's just a handy tool, useful to simplify and reuse the most common searching needs.
