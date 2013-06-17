---
layout: doc
title: Crawl and Index this Documentation Site
---

# {{ page.title }} (Work in progress for Tiago)

In this tutorial we will create a crawl rake task that will crawl this documentation and index all its content with the elasticsearch-mapper-attachment plugin. Then we will add a search template connected with a search form that will highlight the results and link the original page.

## Prerequisite

You need to install the elasticsearch-mapper-attachment plugin. That's very easy: (Tiago: see the doc https://github.com/elasticsearch/elasticsearch-mapper-attachments)

(Tiago: add the installation command

## Steps

First, we add a Flex::ActiveModel model, that will manage the pages we crawl

     class FlexDocPage
       include Flex::ActiveModel
       attribute :url
       attribute_created_at
       attribute_attachment
     end

The attribute_attachment is a special attribute that integrates the elasticsearch-mapper-attachment plugin. It can index various type of contens, like html, pdf, word, excel etc.

add the FlexDocPage to the flex_models array in the config/initializers/flex.rb

    config.flex_models |= [ Post, FlexDocPage ]

Create the index

    $ rake flex:index:create

Then we add the anemone gem to the Gemfile

    gem 'anemone'

bundle install

Rake task

      desc 'Crawl and index the Flex Doc Site'

      task :index_flex_doc => :environment do
        puts "Crawling The Flex Doc site:"
        # we want to destroy all the pages we eventually already have in the index, so they will be fresh
        FlexDocPage.destroy
        start_url     = 'http://escalatemedia.github.io/flex-doc/doc/'

        Anemone.crawl( start_url, :discard_page_bodies => true, :verbose => true) do |anemone|

          # crawl only the start_url dir
          anemone.focus_crawl do |page|
            page.links.delete_if do |link|
              link.to_s !~ %r{^#{start_url}}
            end
          end

          anemone.on_every_page do |page|
            # index only the pages with some content
            if page.code == 200 && page.body.length > 0
              FlexDocPage.create :url        => page.url.to_s,
                                 :attachment => Base64.encode64(page.body)
          end

        end
      end

(Tiago: please, try it and let me know whether it works as is. Ask me if you have any problem )


Run the task, that will crawl and index the Flex Doc Site

    $ rake index_flex_doc

Play with the index in the console.

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

(Tiago: if everything is ok, please, add a FlexDocController controller and a search action with the relative view. In the view add a form:


      def search
        @results = FlexDocPage.searchable(params[:q]).all(:page => params[:page])
      end

the form snippet

    = form_tag(search_path, :method => 'GET', :id=>'search-form') do
      = text_field_tag(:q, params[:q])

      = submit_tag('Search', :id => 'submit-search')
      '
      = submit_tag('Reset', :name => 'reset', :id => 'reset-button' )

(Tiago: add also Kaminari for pagination in the gemfile and in the result page )

snippet for the pagination in the footer (Tiago:it is in slim, please translate it in erb)

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

(Tiago: please add some css to make the thing nice. )

The highlights need to be highlighted with something like:

    em
      background-color: yellow
      padding-left: 3px
      padding-right: 3px

Now point your browser to the search page and search the Flex Doc Site from your app.

(Tiago: it should be all)


