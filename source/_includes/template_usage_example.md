Define the Elastics source `my_source.yml`: it's just a `YAML` document containing a few elasticsearch queries and placeholder tags:

{% highlight yaml %}
my_template:
  query:
    term:
      my_attr: <<the_term>>
  facets:
    my_facet:
      ...
{% endhighlight %}

Create a class and load the source in the class:

{% highlight ruby %}
class MySearch
  include Elastics::Templates
  elastics.load_search_source 'my_source.yml'
end
{% endhighlight %}

Use the automatically generated class methods by just passing a hash of variables/values to interpolate:

{% highlight ruby %}
result = MySearch.my_template :the_string => params[:the_string]
 # or simply
result = MySearch.my_template params
{% endhighlight %}

The results contains the untouched structure returned by elasticsearch, just extended (and easily custom-extendable) with the methods you may need to use:

{% highlight ruby %}
result.collection.each do |document|
  puts document.id, document.title, ...
end

my_facet = result.facets['my_facet']
{% endhighlight %}
