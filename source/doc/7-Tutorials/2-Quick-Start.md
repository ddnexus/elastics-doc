---
layout: doc
title: Quick Start (easy)
---

# {{ page.title }} (Work in progress for Tiago)

> almost no elasticsearch needed to experiment with this tutorial

In this tutorial we will create a rails app connected with an elasticsearch index, that we will populate and search in pure ruby.

## Prerequisites:

Elasticsearch must be installed and running. If you are on a Mac you can just install it with `homebrew`:

{% highlight bash %}
$ brew install elasticsearch
{% endhighlight %}

If you are on any other OS, just read [elasticsearch installation](http://www.elasticsearch.org/guide/reference/setup/installation/)

## Setup

- create a rails app ( use the flag for no DB )

{% highlight bash %}
$ rails new simple_search --flag-for-no-db
{% endhighlight %}

- follow the first 3 steps in the flex-rails setup documentation {% see 5#setup %}

- create a model like this:

{% highlight ruby %}
class Content

  include Flex::ActiveModel

  attribute :name
  attribute :text
  attribute :category, :analyzed => false
  attribute_timestamps

  validates :name, :presence => true

end
{% endhighlight %}

- open the generated file  `config/initializers/flex.rb` and change it so it will include the `Content` model:

{% highlight ruby %}
config.flex_models = %w[ Content ]
{% endhighlight %}

- create the index

{% highlight bash %}
$ rake flex:index:create
{% endhighlight %}

## Usage

Let's open the rails console and start to play with our new app:

### Check the index

- check whether the index exists (* include the result)
{% highlight irb %}
Flex.exists?
{% endhighlight %}

- check the mapping (notice the :category attribute) (* include the result)
{% highlight irb %}
Flex.get_mapping
{% endhighlight %}

### Populate the index with some content (* add a few documents with different content in a few different categories )

{% highlight irb %}
c = Content.create :name => 'First Content',
                   :text => 'bla bla bla'     (* please add some content that makes sense )
                   :category => 'my_category' (* same for the category )
{% endhighlight %}

Add a few comment on the new created document, saying that it is just like any record, etc... eventually adding a few check of something interesting

- Try to add a record with no name (to experiment with validation)

### Search



### Add some custom scope to the model and use it

