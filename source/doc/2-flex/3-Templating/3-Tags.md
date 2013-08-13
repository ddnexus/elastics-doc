---
layout: doc
badge: flex
title: flex - Tags
---

# Tags

Templates are actually a very clean way to define a query method, but a template without tags generates a completely static method. For example the following template will always request the same query:

{% highlight yaml %}
my_request:
- query:
    term:
      user_id: 25
{% endhighlight %}

That may make sense in some context, but typically we would like to use the same template with a different `user_id` for example. So let's replace the parts that we want to be dynamic with a simple named tags:

{% highlight yaml %}
my_request:
- query:
    term:
     user_id: <<user_id>>
{% endhighlight %}

Now we can interpolate the `user_id` tag by just passing its value as a variable, matching tag names with variable keys.

{% highlight ruby %}
results1 = MyClass.my_request :user_id => 25
results2 = MyClass.my_request :user_id => 49
{% endhighlight %}

## Tags Syntax

Tags are used as placeholder for the real values that will be interpolated into the structure just before executing the http request. The syntax follows a few very simple rules:

* their name must be suitable to be ruby method names
* they must not be one of the reserved variable names {% see 2.3.4#special_variables %}
* you can use or omit spaces around names
* they may contextually define a default (similar to the arguments of a ruby method)

Here are a few examples of tags:

    <<a_tag>>
    << another_tag >>
    <<a_tag_with_default= the default >>
    << an_optional_tag= ~ >>
    << _a_partial_template >>
    "<<a_quote_wrapped_tag= {query: '*'} >>" # (the wrapping quotes avoid a YAML parsing error due to the ':')
    << a_nested.tag.1 >> # (will be interpolated with :a_nested[:tag][1] variable value)

You are not limited to use tag as value placeholder: you can use them anywhere in the yaml, also as key placeholder or partial keys or values if it makes sense to you:

{% highlight yaml %}
most_counted:
- sort:
    <<counter>>_count: desc
{% endhighlight %}

Just remember that they will be substituted by the values that a variable key of the same name will contain, so for example using the above template:

{% highlight ruby %}
blog_sorted = MyClass.most_counted :counter => 'blog'
post_sorted = MyClass.most_counted :counter => 'post'
{% endhighlight %}

will respectively generate `{"sort":{"blog_count":"desc"}}` `{"sort":{"post_count":"desc"}}` data queries.

{% see 2.3.5 %}

## Tag defaults

Tags interpolation is very easy and straightforward, but tags can do more for you. For example, let's say we want to use a default `user_id` when we don't have any specific one. So let's add a default:

{% highlight yaml %}
my_request:
- query:
    term:
      user_id: <<user_id= 10 >>
{% endhighlight %}

With this template/method if we don't pass any `:user_id` variable, the default value will be used. So we can use the query method like:

{% highlight yaml %}
results1 = MyClass.my_request # will use :user_id => 10
results2 = MyClass.my_request :user_id => 45
{% endhighlight %}

Tags defaults work very similarly to the argument defaults of ruby methods. Notice however that the default string (from the `=` to the closing `>>`) is evaluated as a `YAML` string as well, so you may need to wrap the tag in quotes if you want to pass valid `YAML` as a default. Besides, if you want to define a `nil` value as a default, you should use the `~` character (that `YAML` explicitly evaluates to nil). Besides, `nil` as a default will also make the tag optional.

{% see 2.3.4 %}
