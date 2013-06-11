---
layout: doc
title: Usage Overview
---

# {{ page.title }}

Flex can integrate your code with elasticsearch in 6 different ways that can be handy in different contexts. From a fully automatic integration, to a very low-level manual interaction:

## 1. ActiveRecord and Mongoid Integration

When the data you need to index is in your DB, just add the following lines to your `ActiveRecord` and `Mongoid` model to sync them:

{% highlight ruby %}
class MyModel < ActiveRecord::Base
  include Flex::ModelIndexer
  flex.sync self
end
{% endhighlight %}

You can add a few other declarations to your models in order to setup parent and child relationship (eventually also polymorphic), and mapping any DB structure to any index structure you might want to design.

{% see 4.2 %}

## 2. ActiveModel Integration

Manage the elasticsearch index as it were a DB, through `ActiveModel` models. Get validations and callbacks, typecasting, attribute defaults, persistent storage, with optimistic lock update, finders, chainable scopes etc.

This is very useful when the data don't come from a DB or when you want to use the elasticsearch index as a data storage, or simply when you want a familiar way to populate and search your index. For example:

{% highlight ruby %}
class Product
  include Flex::ActiveModel

  attribute :name
  attribute :color, :analyzed => false
  attribute :price, :properties => {'type' => 'float'}, :default => 0
  attribute_timestamps

  validate :name, :presence => true

  scope :red, term(:color => 'red')

end

# indexes the data in elasticsearch
Product.create :name  => 'my_name',
               :color => 'blue',
               :price => 9.99

red_products = Product.red.all
product = Product.find('a09rf')
total   = Product.count
{% endhighlight %}

{% see 4.3 %}

## 3. Chainable Scopes and Finders

> Almost no elasticsearch knowledge required: a ruby-rails way that covers most searching needs!

Scopes are a great way to define the criteria to search the index in pure ruby. You can mix and match many scopes to create a new search criteria, and finally get your result by calling the usual `find`,  `count`, `destroy`, `first`, `last`, `all`. You can also use `scan_all` when you want to process a lot of documents in batches.


{% highlight ruby %}
class MyClass
  include Flex::Scopes

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

# uses the elasticsearch 'scan' search_type
MyClass.red.scan_all do |batch|
  batch.each {|d| do_something_with(d)}
end

{% endhighlight %}

You can use the `flex-scopes` with every class that includes any Flex module {% see 3.1 %}


## 4. Template Based Usage

Easily design complex search queries in simple `YAML` that automatically define methods in your classes.

Flex implements a very simple but powerful templating system that allows you to define very elaborate queries and automatically generate the methods to use (and reuse) them. This method is typically used for search queries, that may grow quite complex, but internally Flex uses it everywhere.

Define the Flex source `my_source.yml`: it's just a `YAML` document containing a few elasticsearch queries and placeholder tags:

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
  include Flex::Templates
  flex.load_search_source 'my_source.yml'
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

{% see 2.2 %}

## 5. elasticsearch API Methods Usage

Flex exposes all the elasticsearch API methods as class methods. A few examples:

{% highlight ruby %}
Flex.exist? :index => 'my_index'

Flex.count :index => 'my_index',
           :type  => 'my_type'

Flex.get :id    => id,
         :type  => 'my_type',
         :index => 'my_index'

Flex.multi_get :ids   => ids,
               :type  => 'my_type',
               :index => 'my_index'

Flex.delete_by_query :index  => 'my_index',
                     :params => {:q =>'my_field:value'}

Flex.more_like_this :id    => id,
                    :index => 'my_index',
                    :type  => 'my_type'

Flex.stats :index    => %w[my_index my_other_index],
           :type     => %w[my_type my_other_type]
           :endpoint => 'indexing'

{% endhighlight %}

> __Notice__: you don't actually need to pass any explicit `:index` or `:type` if you set them as a defaults {% see 2.2.4 %}

You will probably never need to use the API Methods directly, since Flex does the heavy lifting for you, but they cover all the elasticsearch API, so they will be available when you will need to do anything special {% see 2.1 %}.

## 6. Curl-like Usage

This usage is very explicit and mostly useful for experimentation and debugging: you can use the methods `HEAD`, `GET`, `PUT`, `POST`, `DELETE` exactly as you would do with curl (also enforced by the unconventional upcase naming):

{% highlight ruby %}
# you can use a json string
Flex.GET '/my_index/my_type/_search', '{"query":{"match_all":{}}}'

# a ruby hash
Flex.GET '/my_index/my_type/_search', {:query => {:match_all => {}}}

# or a yaml string
Flex.GET '/my_index/my_type/_search', <<-yaml
query:
  match_all: {}
yaml
{% endhighlight %}

You don't need to pass the base uri: just the path since the `base_uri` is a configuration setting that defaults to the elasticsearch `http:://localhost:9200` {% see 1.3 %}.

In all methods above you can also use tags in path and data, and get them interpolated with the default or explicit variables, as you do with a regular Flex template {% see 2.5#curllike_methods Curl-like Methods %})

{% highlight ruby %}
Flex.GET '/<<index>>/<<type>>/_search', <<-yaml, :index => 'my_index', :my_term => 'any'
query:
  term:
    my_field: <<my_term>>
yaml
{% endhighlight %}
