---
layout: doc
badge: flex
title: Index and Search your Models
---

# {{ page.title }}

> __Notice__: This tutorial is complemented by the next one, please read both of them {% see 7.4 %}.

In this tutorial you will learn how to index the data in your own models and a few different options for searching it. You will also learn how you can easily transform any (even complex) elasticsearch query to a ready to use method in no time.

We will not explicitly create any new app as we did in the previous tutorial. It is better if you just experiment with one of your apps and just add what it needs to index and search its data (eventually in a new branch). So let's start with the prerequisites and the setup to make a rails app work with flex.

## Prerequisites

Elasticsearch must be installed and running. If you are on a Mac you can just install it with `homebrew`:

{% highlight bash %}
$ brew install elasticsearch
{% endhighlight %}

If you are on any other OS, read [elasticsearch installation](http://www.elasticsearch.org/guide/reference/setup/installation/)

## Setup

Open the `Gemfile` and add a couple of gems:

{% highlight ruby %}
gem 'rest-client'
gem 'flex-rails'
{% endhighlight %}

Now run the bundle install command:

{% highlight bash %}
$ bundle install
{% endhighlight %}

When it finishes, run the generator:

{% highlight bash %}
$ rails generate flex:setup
# press return when asked
{% endhighlight %}

## Enabling the Models

If you just want to add indexing and searching capability to your models, you need to add just 2 lines of code per model, and all your records will be indexed in the same structure they have in the DB. Let's start by doing it in a couple of related models:

{% highlight ruby %}
class Blog < ActiveRecord::Base
  has_many :comments
  include Flex::Indexer
  flex.sync self
end

class Comment < ActiveRecord::Base
  belongs_to :blog
  include Flex::Indexer
  flex.sync self
end
{% endhighlight %}

That's trivially easy, isn't it? That will create 2 elasticsearch types of indexed documents: `'blog'` and `'comment'`, and it will index all the fields in each record at each record change. That's what you get by default with only 2 lines.

### Fine-tuning the indexing

For the purpose of this tutorial, the default is fine, but keep in mind that you should design your index to make it simple to search, and most importantly to contain all the data you have to display, so avoiding to query your DB in order to get what is missing from your indexed data.

So it is likely that indexing all (but only) the fields is not the most suitable way for your specific needs. You may need to display some data that is not a field of your model, or you may decide to implement parent/children relationships between your models because you need to search them with the `has_child` query. With flex you can easily finetuning your models at the class level, by adding some simple declarations or methods to your model, in order to get the index you want {% see 4.2 %}.

## Updating the Setup

Before we restart our app and try to index or search anything, we must do one more thing. We must add your models to the `flex_models` array in the `config/initializers/flex.rb`, because flex needs to know it in order to create the index/indices:

{% highlight ruby %}
config.flex_models |= %w[ Blog Comment ]
{% endhighlight %}

Now we can import the data into the index. We can do so by running a rake task:

{% highlight bash %}
$ rake flex:import_models
{% endhighlight %}

That will create the default index and will import all the `Blog` and `Comment` records in it.

> During the development you can use the same rake task to reindex from scratch each time you change something that will affect the structure of the index (just pass `FORCE=true` to also delete the old index). When your app will be in production, the problem will get more complex, so you should use the live-reindex feature that allows a lot smoother transition {% see 6.2 %}.

## How to Search

So how can your search your new indexed data now? Flex offers 2 different ways to search your data: flex scopes and flex templates. You can use them separately or toghether, inside your models and/or inside your `FlexSearch` module in any combination suits your needs. So let's analyze the pros and the cons of each combination so you will be able to easily pick the best one for you.

### Adding to the models or to the FlexSearch module?

You can add flex scopes and flex template to your own models. That is a good option if all your searches are scoped to one single model/type at a time, and you use different criteria to search different models, since it will keep the search logic within the model logic, and in that case it will be cleaner.

However if you need to search more than one model at a time, you should move scopes and templates from your models to the `FlexSearch` module that the flex generator created. That will keep the search logic in a single place but separated from the application logic and will not suffer the limitation of searching only one specific model/type.

Since it is the most common and versatile option, in this tutorial we will add our flex scopes and templates to the `FlexSearch` module.

> __Notice__: You can split the `FlexSearch` into as many different classes as it makes sense to you, reorganizing your files/classes as you prefer.

### Using flex scopes or templates?

Flex scopes are a very easy way to search your data in pure ruby and almost without any knowledge of elasticsearch. They work very similarly to the `ActiveRecord` scopes, and are perfect for simple search criteria that can make your code very simple, readable and reusable. You have plenty of predefined scopes ready to use, you can chain them together to create more elaborated search criteria, and you can define custom named scopes that can encapsulate many search criteria in one single scope. All that done in pure, clear and simple ruby.

However, they are not an all purpose searching tool: they are just an easy to use tool. Indeed they tend to be less useful or even useless, when your search logic starts to require very complex queries.

On the other hand, flex templates are the all purpose searching (and querying) tool, that can express very easily any possible query, regardless its complexity. They are very powerful but they require you to know elasticsearch a bit, or at least... to know how to find and copy the right query from the elasticsearch documentation :-).

In this tutorial we will use a bit of both flex scopes and templates, so you will get an idea about both.

### Using Flex::Scopes

If you look into the `FlexSearch` you will see that it already includes `Flex::Scopes`. That means that you can already search with the predefined scopes included in the `FlexSearch` model. So let's try a couple of predefined scopes in the console.

{% highlight irb %}
>> FlexSearch.term('ruby').all
>> FlexSearch.query('ruby AND rails').all
{% endhighlight %}

> You can find more predefined scopes in the flex scopes documentation page, and learn how to chain together many scopes and define custom scopes {% see 3 %}.

If you want to add your own custom scope, just do so in the `flex/flex_search.rb` module, and use it as any other predefined scope.

### Adding Flex Templates

The `FlexSearch` loads also one predefined template. It is defined in the `flex/flex_search.yml` file. It is ready to use:

{% highlight irb %}
>> FlexSearch.search(:cleanable_query => 'ruby AND rails')
{% endhighlight %}

But usually your searching needs are not so simple: may be you need to run some quite complex query that you find in internet, and you need to transform it into some method to use in your app. For example, you may find a json query that is exactly what you need: how could you transform it in a ready to use method?

That's easy with the flex Templates. The first thing you should do is making it a little easier to manage, by transforming it in `YAML`. You can do so very easily by using the `Flex.json2yaml` utility method in the console.

{% highlight irb %}
>> puts Flex.json2yaml '{
                           "query": {
                               "filtered" : {
                                   "query" : {
                                       "query_string" : {
                                           "query" : "some query string here"
                                       }
                                   },
                                   "filter" : {
                                       "term" : { "user" : "kimchy" }
                                   }
                               }
                           }
                       }'
---
query:
  filtered:
    query:
      query_string:
        query: some query string here
    filter:
      term:
        user: kimchy
 => nil
{% endhighlight %}

Now let's copy just the yaml output (without the `---`) and paste it as the content of a new template in the `flex/flex_search.yml` template source (right after the predefined `search` query). Let's call it `my_test`:

{% highlight yaml %}
my_test:
- query:
    filtered:
      query:
        query_string:
          query: some query string here
      filter:
        term:
          user: kimchy
{% endhighlight %}

We obviously don't want to search the `some query string here`, nor the `kimky` as the user, but we want to change that dynamically. So we can remove those string and change them with a couple of placeholder tags:

{% highlight yaml %}
my_test:
- query:
    filtered:
      query:
        query_string:
          query: <<my_query>>
      filter:
        term:
          user: <<the_user>>
{% endhighlight %}

Done!

Yeah, really! We now have the `FlexSearch.my_test` method ready to use and it is also aware of the placeholder that you defined, because it will complain if you miss any variable. Let's try it:

{% highlight irb %}
>> Flex.reload!
true

>> FlexSearch.my_test
...
Flex::MissingVariableError: the required :my_query variable is missing.

>> FlexSearch.my_test :my_query => 'ruby', :the_user => 'whoever'
... successful query result ...
{% endhighlight %}

> __Remember__: During a console session you must use `Flex.reload!` each time you add or change a template in any source or the changes will not be available in the session. That doesn't apply to the rails server: in development mode the rails server will automatically reload the changes in the sources at each request, so you will just have to reload the page in order to see the effect of your changes.

Flex Templates are not only easy to implement and use, they are also very powerful. They can generate very dynamic queries based on the variables you send them, automatically adding or removing part of their queries. {% see 2.3.5, 2.3.6 %}

> __Notice__: This tutorial is complemented by the next one, please read both of them {% see 7.4 %}.
