---
layout: doc
title: Crawl and Index this Documentation Site
---

# {{ page.title }} (Work in progress)

In this tutorial we will create a crawl rake task that will crawl this documentation and index all its content with the elasticsearch-mapper-attachment plugin. Then we will add a search form that will search in the elasticsearch index, highlight the results and link to the original page.

## Prerequisite

Elasticsearch must be installed and running. If you are on a Mac you can just install it with `homebrew`:

{% highlight bash %}
$ brew install elasticsearch
{% endhighlight %}

If you are on any other OS, just read [elasticsearch installation](http://www.elasticsearch.org/guide/reference/setup/installation/)

For the purpose of this tutorial, you need also to install the elasticsearch-mapper-attachment plugin. That's very easy:

The command should be something like the following (please, check the latest version in its [github page](https://github.com/elasticsearch/elasticsearch-mapper-attachments))
{% highlight bash %}
$ bin/plugin -install elasticsearch/elasticsearch-mapper-attachments/1.7.0
{% endhighlight %}

## Setup

Create a rails app:

{% highlight bash %}
$ rails new flex_doc_search --skip-active-record --skip-bundle
{% endhighlight %}

> we don't need any database for this tutorial, and we will run `bundle install` later

Now open the `Gemfile` and add the `rest-client`, `flex` and the `anemone` gem (that we will use in this tutorial in order to crawl the flex-doc site)

{% highlight ruby %}
gem 'rest-client'
gem 'flex-rails'
gem 'anemone'
{% endhighlight %}

Now run the bundle install command:

{% highlight bash %}
$ bundle install
{% endhighlight %}

When it finishes, run the generator:

{% highlight bash %}
$ rails generate flex:setup
{% endhighlight %}

## Steps

### 1

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

### 2

Add the FlexDocPage to the flex_active_models array in the `config/initializers/flex.rb`

{% highlight ruby %}
config.flex_active_models |= [ FlexDocPage ]
{% endhighlight %}

### 3

Create the index with the rake task:

{% highlight bash %}
$ rake flex:index:create
{% endhighlight %}

### 4

Now we can create the rake task that will crawl the `flex-doc` site and will index its content. Just create the file `lib/tasks/crawler.rake` and paste the following content in it:

{% highlight ruby %}
desc 'Crawl and index the Flex Doc Site'

task :index_flex_doc => :environment do
  puts "Crawling The Flex Doc site:"
  # we want to destroy all the pages we eventually already have in the index, so they will be fresh each time we re-crawl
  FlexDocPage.destroy

  root_url  = 'http://escalatemedia.github.io/flex-doc/doc/'
  start_url = 'http://escalatemedia.github.io/flex-doc/doc/1-Global-Doc/1-Overview.html'

  Anemone.crawl( start_url, :discard_page_bodies => true, :verbose => true) do |anemone|

    # crawl only the start_url dir
    anemone.focus_crawl do |page|
      page.links.delete_if do |link|
        link.to_s !~ %r{^#{root_url}}
      end
    end

    anemone.on_every_page do |page|
      # index only the pages with some content
      if page.code == 200 && page.body.length > 0
        # we index the page content by just passing it as a Base64 encoded string
        FlexDocPage.create :url        => page.url.to_s,
                           :attachment => Base64.encode64(page.body)
      end

    end
  end
end
{% endhighlight %}

> Most of the code in the task is related to the `anemone` crawling, which will fetch the pages. Then we index each page by just creating a new `FlexDocPage` document, as we would do in order to store the content in a DB.

### 5

Run the task, that will crawl and index the whole Flex-Doc site:

{% highlight bash %}
$ rake index_flex_doc
{% endhighlight %}

We now have all the content in the index, so let's play with it in the console.

....

## Search

We add the :searchable scope. The `attribute_attachment` declaration predefines the `attachment_scope`: we can use it to include in our result also the meta-fields (like title, author, content-type, etc.).

> __Notice__: The attachment_scope excludes the attachment field itself from the result. It contains the Base64-encoded content, and we don't need it, since we will link the original page.


    scope :searchable do |q='*'|
       attachment_scope
      .highlight(:fields => { :attachment          => {},
                              :'attachment.title'  => {} })
      .query(q)
    end

we chained togeter a few scopes: the attachment_scope is predefined by the attribute_attachment declaration, the highlight will add the highlights to our results, and the query is what we need to search and will be passed to the scope as a string.

> __Notice__: if the query string passed contains some syntax error, flex will clean it up and will transparently retry the query {% see 2.2.4#cleanable_query %}.

Let's try it in the console:

    my_scope = FlexDocPage.searchable 'flex'

That scope is chainable with other scopes as well. If we need the actual results from that scope, we should call one of the query-scopes, (all, first, last, etc.):

    results = my_scope.all

(Edit-note: if everything is ok, please, add a FlexDocController controller and a search action with the relative view. In the view add a form:


      def search
        @results = FlexDocPage.searchable(params[:q]).all(:page => params[:page])
      end

the form snippet

    = form_tag(search_path, :method => 'GET', :id=>'search-form') do
      = text_field_tag(:q, params[:q])

      = submit_tag('Search', :id => 'submit-search')
      '
      = submit_tag('Reset', :name => 'reset', :id => 'reset-button' )

(Edit-note: add also Kaminari for pagination in the gemfile and in the result page )

snippet for the pagination in the footer (Edit-note:it is in slim, please translate it in erb)

    #pagination
      = page_entries_info @results.collection, :entry_name => 'result'
      = paginate(@results.collection)

The result page will contain some loop like:

    - @results.collection.each do |page|
      .title
        a href=page.url target='_blank'
          b = page.attachment_title


That will provide only a list of page titles and the link to the original page. It will work, but we want to do something nicer, so let's use the `highlighted_*` helpers to manage the highlights in the views:

    - @results.collection.each do |page|
      .title
        a href=page.url target='_blank'
          b = page.highlighted_attachment_title

      .content = page.highlighted_attachment

> __Notice__: the `highlighted_\*` methods return the joined string from the elasticsearch `highlights`, if there are no highlights and the attribute exists they return the attribute, or an empty string in any other case.

(Edit-note: please add some css to make the thing nice. )

The highlights need to be highlighted with something like:

    em
      background-color: yellow
      padding-left: 3px
      padding-right: 3px

Now point your browser to the search page and search the Flex Doc Site from your app.

(Edit-note: it should be all)


