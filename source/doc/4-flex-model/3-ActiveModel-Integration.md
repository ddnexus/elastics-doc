---
layout: doc
title: flex-model - ActiveModel Integration
---

# ActiveModel Integration

When you want a familiar way to populate and search your index without even need to know elasticsearch or when the data you have to index is external to your app (for example if you crawl a site and want to build a searchable index out of it), you can just manage the index like you were managing any active model, still keeping the searching capability of `Flex::Scopes` and/or `Flex::Templates`.

> __Notice__: The result returned by querying elasticsearch with a `Flex::ActiveModel` model, return always regular instance of your class, not the original elasticsearch result structure. However you can always get the raw result by just calling `raw_result` on the array collection or any model instance.

The key concept is that you create a model per (elasticsearch) `type`, similarly to what you would do with a DB: a model per table/collection. You do so by including `Flex::ActiveModel` which also includes `Flex::ModelIndexer`, so you will have all the `flex.*` methods available both at the class level and at the instance level {% see 4.4.2 %}.

Then you declare the model attributes names, and optionally their default and typecasting. You can eventually set also the elasticsearch mapping properties for each attribute that may need it, and you can use it as any other model. For example:

{% highlight ruby %}
class Product
  include Flex::ActiveModel

  # if we omit the next line, the elasticsearch type would have been 'product' by default
  flex.type = 'goods'

  attribute :name
  # optional elasticsearch properties mapping
  attribute :price, :properties => {'type' => 'float'}, :default => 0

  # :analyzed => false is a shortcut to :properties => { 'type' => 'string', 'index' => 'not_analyzed' }
  attribute :color, :analyzed => false

  # this adds a :created_at and :updated_at attributes
  attribute_timestamps

  # standard validation
  validate :name, :presence => true

  # standard callback
  before_create { self.name = name.titleize }

  # named scope
  scope :red, term(:color => 'red')

end

# indexes the data in elasticsearch
product = Product.new :name  => 'my_name',
                      :color => 'blue',
                      :price => 9.99

product.save if product.valid?

red_products = Product.red.all
product = Product.find('a09rf')
total   = Product.count
{% endhighlight %}

## Capabilities

By including `Flex::ActiveModel` your model gets the following capabilities:

### Validation

Validation is provided verbatim by `ActiveModel` (see [activemodel](https://github.com/rails/rails/tree/master/activemodel)) so you an use all its standard validation methods.

### Callbacks

`Flex::ActiveModel` provides the `create`, `update`, `save` and `destroy` callbacks backed by `ActiveModel`, so you can use them as usual with the `before_*` and `after_*` prefixes.

### Attributes

By including `Flex::ActiveModel` you include also the `ActiveAttr::Model`. It provides a lot of useful goodies, like attribute declarations with defaults and typecasting (see [active_attr][]). Besides, flex extends it with a few features {% see 4.4.3#class_methods %}

### Versioning and optimistic lock updating

`Flex::ActiveModel` adds the versioning to your models (see [elasticsearch Versioning](http://www.elasticsearch.org/blog/2011/02/08/versioning.html), so your model has always a `_version` attribute. Besides, it implements the lock updating throught the method `lock_update` {% see 4.4.3#safe_update %}.

### Finders, Scopes and Templates

`Flex::ActiveModel` includes also the `Flex::Scopes` by default, so you have all the cool finders and chainable scopes ready to use in your model {% see 3.1 %}

Besides, if you need more power to easily write complex queries, you can include the `Flex::Templates` module and use it as usual {% see 2.2 %}

## Methods

{% see 4.4.3, 4.4.2, 4.4.1 %}
