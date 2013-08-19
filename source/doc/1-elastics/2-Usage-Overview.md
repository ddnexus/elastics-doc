---
layout: doc
badge: elastics-client
title: Usage Overview
---

# {{ page.title }}

Elastics can integrate your code with elasticsearch in 6 different ways that can be handy in different contexts. From a fully automatic integration, to a very low-level manual interaction:

## 1. ActiveRecord and Mongoid Integration

When the data you need to index is in your DB, just add the following lines to your `ActiveRecord` and `Mongoid` model to sync them:

{% highlight ruby %}
class MyModel < ActiveRecord::Base
  include Elastics::ModelIndexer
  elastics.sync self
end
{% endhighlight %}

You can add a few other declarations to your models in order to setup parent and child relationship (eventually also polymorphic), and mapping any DB structure to any index structure you might want to design.

{% see 4.2 %}

## 2. ActiveModel Integration

Manage the elasticsearch index as it were a DB, through `ActiveModel` models. Get validations and callbacks, typecasting, attribute defaults, persistent storage, with optimistic lock update, finders, chainable scopes etc.

This is very useful when the data don't come from a DB or when you want to use the elasticsearch index as a data storage, or simply when you want a familiar way to populate and search your index. For example:

{% highlight ruby %}
class Product
  include Elastics::ActiveModel

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
product      = Product.find('a09rf')
total        = Product.count
{% endhighlight %}

{% see 4.3 %}

## 3. Chainable Scopes and Finders

> Almost no elasticsearch knowledge required: a ruby-rails way that covers most searching needs!

Scopes are a great way to define the criteria to search the index in pure ruby. You can mix and match many scopes to create a new search criteria, and finally get your result by calling the usual `find`,  `count`, `delete`, `first`, `last`, `all`. You can also use `scan_all` when you want to process a lot of documents in batches.


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

# uses the elasticsearch 'scan' search_type
MyClass.red.scan_all do |batch|
  batch.each {|d| do_something_with(d)}
end

{% endhighlight %}

You can use the `elastics-scopes` with every class that includes any Elastics module {% see 3 %}


## 4. Template Based Usage

Easily design complex search queries in simple `YAML` that automatically define methods in your classes.

Elastics implements a very simple but powerful templating system that allows you to define very elaborate queries and automatically generate the methods to use (and reuse) them. This method is typically used for search queries, that may grow quite complex, but internally Elastics uses it everywhere.

{% include template_usage_example.md %}

{% see 2.3 %}

## 5. elasticsearch API Methods Usage

Elastics exposes all the elasticsearch API methods as ready to use class methods. A few examples:

{% highlight ruby %}
Elastics.exist? :index => 'my_index'

Elastics.count :index => 'my_index',
               :type  => 'my_type'

Elastics.get :id    => id,
             :type  => 'my_type',
             :index => 'my_index'

Elastics.multi_get :ids   => ids,
                   :type  => 'my_type',
                   :index => 'my_index'

Elastics.delete_by_query :index  => 'my_index',
                         :params => {:q =>'my_field:value'}

Elastics.more_like_this :id    => id,
                        :index => 'my_index',
                        :type  => 'my_type'

Elastics.stats :index    => %w[my_index my_other_index],
               :type     => %w[my_type my_other_type]
               :endpoint => 'indexing'

{% endhighlight %}

> __Notice__: you don't actually need to pass any explicit `:index` or `:type` if you set them as a defaults {% see 2.3.4 %}

You will probably never need to use the API Methods directly, since Elastics does the heavy lifting for you, but they cover all the elasticsearch API, so they will be available when you will need to do anything special {% see 2.2 %}.

## 6. Curl-like Usage

This usage is very explicit and mostly useful for experimentation and debugging: you can use the methods `HEAD`, `GET`, `PUT`, `POST`, `DELETE` exactly as you would do with curl (also enforced by the unconventional upcase naming):

{% highlight ruby %}
# you can use a json string
Elastics.GET '/my_index/my_type/_search', '{"query":{"match_all":{}}}'

# a ruby hash
Elastics.GET '/my_index/my_type/_search', {:query => {:match_all => {}}}

# or a yaml string
Elastics.GET '/my_index/my_type/_search', <<-yaml
query:
  match_all: {}
yaml
{% endhighlight %}

You don't need to pass the base uri: just the path since the `base_uri` is a configuration setting that defaults to the elasticsearch `http:://localhost:9200` {% see 1.3 %}.

In all methods above you can also use tags in path and data, and get them interpolated with the default or explicit variables, as you do with a regular Elastics template {% see 2.6#curllike_methods Curl-like Methods %})

{% highlight ruby %}
Elastics.GET '/<<index>>/<<type>>/_search', <<-yaml, :index => 'my_index', :my_term => 'any'
query:
  term:
    my_field: <<my_term>>
yaml
{% endhighlight %}
