---
layout: doc
badge: flex
title: Index and Search External Data
---

# {{ page.title }}

> __Notice__: This tutorial is complemented by the previous one, please read both of them {% see 7.3 %}.

When the data you want to search is not managed by your app, you can index and search it as easily as it were in your own DB. Indeed you can use elasticsearch as it were a sort of DB itself, managing its indices and types with your models as you do with databases and tables.

In this tutorial we will create a small Rails app that will crawl this very documentation and index all its content with the `elasticsearch-mapper-attachment` plugin. It will do so without using any DB, using only one elasticsearch index, managed by a simple model. Then we will add a search form that will search in the elasticsearch index, highlight the results and link to the original documentation page, so you will learn also how to use the results that you pull from your searches.

## Prerequisite

Elasticsearch must be installed and running. If you are on a Mac you can just install it with `homebrew`:

{% highlight bash %}
$ brew install elasticsearch
{% endhighlight %}

If you are on any other OS, read [elasticsearch installation](http://www.elasticsearch.org/guide/reference/setup/installation/)

For the purpose of this tutorial, you need also to install the elasticsearch-mapper-attachment plugin. That's very easy:

The command should be something like the following (but please, check the latest version in its [github page](https://github.com/elasticsearch/elasticsearch-mapper-attachments))
{% highlight bash %}
$ bin/plugin -install elasticsearch/elasticsearch-mapper-attachments/1.7.0
{% endhighlight %}

## Setup

Create a rails app:

{% highlight bash %}
$ rails new flex_doc_search --skip-active-record --skip-bundle
{% endhighlight %}

> we don't need any database for this tutorial, and we will run `bundle install` later

Now open the `Gemfile` and add a few gems that we will use in this tutorial in order to crawl and index the flex-doc site, search it and paginate the results:

{% highlight ruby %}
gem 'rest-client'
gem 'flex-rails'
gem 'anemone'
gem 'kaminari'
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

## Model and Index

First, we add a `Flex::ActiveModel` model, that will manage the pages we crawl. It will use the elasticsearch index as it were a database.  You can just add the file `app/models/flex_doc_page.rb`:

{% highlight ruby %}
class FlexDocPage

  include Flex::ActiveModel

  attribute :url
  attribute_created_at
  attribute_attachment

end
{% endhighlight %}

> The `attribute :url` is a custom attribute that we will use to store the original url of any crawled page<br>
> The `attribute_created_at` will automatically add a field with the creation date<br>
> The `attribute_attachment` is a special attribute that integrates the elasticsearch-mapper-attachment plugin: it can index various type of contenTs, like html, pdf, word, excel etc.

{% see 4.4.3#class_methods Flex::ActiveModel Attributes %}

Now we must add the `FlexDocPage` to the `flex_active_models` array in the `config/initializers/flex.rb`, because flex needs to know it in order to create the index/indices:

{% highlight ruby %}
config.flex_active_models |= [ FlexDocPage ]
{% endhighlight %}

Create the index with the rake task:

{% highlight bash %}
$ rake flex:index:create
{% endhighlight %}

## Crawler

Now we can create the rake task that will crawl the `flex-doc` site and will index its content. Just create the file `lib/tasks/crawler.rake` and paste the following content in it:

{% highlight ruby %}
desc 'Crawl and index the Flex Doc Site'

task :index_flex_doc => :environment do
  puts "Crawling The Flex Doc site:"
  # we want to delete all the pages we eventually already have in the index, so they will be fresh each time we re-crawl
  FlexDocPage.delete

  Anemone.crawl('http://ddnexus.github.io/flex/', :verbose => true) do |anemone|

    anemone.on_every_page do |page|
      # index only the successful html pages with some content
      if page.code == 200 && page.url.to_s =~ /\.html$/ && page.body.length > 0
        # remove the common parts not useful for searching
        %w[#page-nav #footer .breadcrumb].each{|css| page.doc.css(css).remove}
        # we index the page content by just passing it as a Base64 encoded string
        FlexDocPage.create :url        => page.url.to_s,
                           :attachment => Base64.encode64(page.doc.to_s)
      end

    end
  end
end
{% endhighlight %}

> Most of the code in the task is related to the `anemone` crawling, which will fetch the pages. The important thing is the last line, where we create a new `FlexDocPage` document, as we would do in order to store the content in a DB: that will analyze and store the page content into the index.

Run the task, that will crawl and index the whole Flex-Doc site:

{% highlight bash %}
$ rake index_flex_doc
{% endhighlight %}

## Check the Index

Now we have all the content in the index managed by our application, so let's play with it in the console.

Let's start just with checking the existence of the index:

{% highlight irb %}
>> Flex.exist?
FLEX-INFO: Rendered Flex.exist? from: (irb):1:in `irb_binding'
FLEX-DEBUG: :request:
FLEX-DEBUG:   :method: HEAD
FLEX-DEBUG:   :path: /flex_doc_search_development
=> true
{% endhighlight %}

> As you see, each time flex sends any query, it prints the request on your screen. That's useful to check what is the actual request that has been sent to the elasticsearch server. That is just the basic logging default: you may want to disable it or you may need more info. You can experiment with different settings of the logger by just changing them in the console. For example you may want to whatch the raw result returned by elasticsearch: to enable that you have just to type `Flex::Conf.logger.debug_result = true` right in the console {% see 1.3 %}.

{% highlight irb %}
>> FlexDocPage.count
FLEX-INFO  Rendered Flex::Scope::Query.get from: (irb):2:in `irb_binding'
FLEX-DEBUG  :request:
FLEX-DEBUG    :method: GET
FLEX-DEBUG    :path: /flex_doc_search_development/flex_doc_page/_search?version=true&search_type=count
FLEX-DEBUG    :data:
FLEX-DEBUG      query:
FLEX-DEBUG        query_string:
FLEX-DEBUG          query: ! '*'
=> 30
{% endhighlight %}

You can also get an indexed page, for example:

{% highlight irb %}
>> FlexDocPage.first
... long Base64 encoded content ...
{% endhighlight %}

And if you want to avoid the encoded content, just use the `attachment_scope`:

{% highlight irb %}
>> FlexDocPage.attachment_scope.first
...
>> FlexDocPage.attachment_scope.all
...
>> FlexDocPage.attachment_scope.all(:page => 2)
...
{% endhighlight %}


## Searching

Now that we have an index, let's add a custom scope to our `FlexDocPage` model: we will use it to search the index easily. Let's call it `:searchable`. Here is how the model will appear after adding our scope:

{% highlight ruby %}
class FlexDocPage

  include Flex::ActiveModel

  attribute :url
  attribute_created_at
  attribute_attachment

  scope :searchable do |q|
     attachment_scope
    .highlight(:fields => { :attachment          => {},
                            :'attachment.title'  => {} })
    .query(q)
  end

end
{% endhighlight %}

In the block of our scope we have chained together a few predefined scopes {% see 3 %}.

The `attribute_attachment` declaration (that we added to the `FlexDocScope`) added the `attachment_scope` to our class: we can use it to include in our result also the meta-fields of the page (like title, author, content-type, etc.), and - as we have just experimented in the console session above - it will also exclude the attachment field itself from the result, so it will be easier to handle {% see 4.4.3#attribute_attachment attribute_attachment%}.

> The `attachment` field contains the Base64-encoded content, and unless we need to display it in some view, we can omit it from the result (indeed in this tutorial we will link the original page). However, although we omit it from the result, it is searched by our queries.

The `highlight` scope will add the highlights for the `attachment` and the `attachment.title` fields to our results and the `query` scope will handle the query_string that we will use to search (passed to the scope as an argument).

Let's try it in the console:

{% highlight irb %}
>> my_scope = FlexDocPage.searchable('flex')
=> #<Flex::Scope ...>
{% endhighlight %}

Notice that the `searchable` scope is like any other scope (predefined or custom), so it is chainable with other scopes as well if we want to modify our search criteria. If we need the actual results from that scope, we should call one of the query-scopes, like `all`, `first`, `last`, etc. {% see 3.2#query_scopes %}:

{% highlight irb %}
>> result = my_scope.all
=> ...
{% endhighlight %}

## User Interface

So let's add the `app/controllers/searches_controller.rb` with just one action in it:

{% highlight ruby %}
class SearchesController < ApplicationController

  def search
    return if params[:q].blank?
    @result = FlexDocPage.searchable(params[:q]).all(:page => params[:page])
  end

end
{% endhighlight %}

We will search the pages by passing the query string to our `searchable` scope. We pass also the special variable `:page` that will get the right page of the pagination.

We make the `search` action the root route in `config/routes.rb`

{% highlight ruby %}
root 'searches#search'
{% endhighlight %}

Then we need to create the `app/views/searches/search.html.erb`, with a form, a loop to display all the paginated result, and the pagination header and footer. Let's paste the following content in it:

{% highlight erb %}
<h3> Search the FlexDoc Site:</h3>

<%= form_tag(root_path, :method => 'GET', :id=>'search-form') do %>
  <%= text_field_tag(:q, params[:q]) %>
  <%= submit_tag('Search', :id => 'submit-search') %>
  <%= submit_tag('Reset', :name => 'reset', :id => 'reset-button' ) %>
<% end %>


<% if @result %>

  <div class="pagination">
    <%= page_entries_info(@result.collection, :entry_name => 'result') %>
  </div>

  <% @result.collection.each do |page| %>
    <div class="hit">
      <div class="attachment_title">
        <%= link_to page.highlighted_attachment_title, page.url, :target => '_blank' %>
      </div>
      <div class="attachment">
        <%= page.highlighted_attachment %>
      </div>
    </div>
  <% end %>

  <%= paginate(@result.collection) %>

<% end %>
{% endhighlight %}


> __Notice__: the `highlighted_*` methods are special helpers generated by the `flex-rails` gem. They return the joined string from the elasticsearch `highlights`, if there are no highlights and the attribute exists they return the attribute, or an empty string in any other case {% see 5.2 document.highlighted_* %}.


Now let's add just a minimum of CSS rules to make our search page easy to read. Let's create the file `app/assets/stylesheets/search.sass` and paste the following content in it:

{% highlight sass %}
body
  margin: 3em

em
  background-color: yellow
  padding
    left: .2em
    right: .2em

.hit
  margin-top: 2em

.attachment_title a
  font-weight: bold

.pagination
  margin-top: 2em
  border-top: 1px solid gray
  padding-top: .5em
  span
    margin-right: .5em
{% endhighlight %}

Job done! Now we can start the rails server, and point the browser to our new search app.

> __Notice__: This tutorial is complemented by the previous one, please read both of them {% see 7.3 %}.
