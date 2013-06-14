---
layout: doc
title: Quick Start (advanced)
---

# {{ page.title }} (Work in progress for Tiago)

We will add a few ActiveReocrd models to the rails app created in the previous tutorial, and sync it with elasticsearch, so each time any record changes, the index will be updated.

We will also add flex scopes for easy search and flex templates for advanced search

(* we will add a few related model, like Post and Comment for example, so we can show how to sync related models that embeds fields from an associated record. )

(* The structure will be something like the following. Maybe we could add logical steps one at a time, and not all together, so we could explain each part better )

    class Post < ActiveRecord::Base
    end

Add some fields and a migration

We want to index our posts, so we could search them with elasticsearch, so we add:

    include Flex::ModelIndexer
    sync self

(* Add some explanation about the inclusion and the sync. It is documented in the flex-model section. )

add it to the flex_models array in the config/initializers/flex.rb

    config.flex_models |= [ Post ]

create the index

    $ rake flex:index:create

(* Fire the console and add some record )

(* now check the indexed elasticsearch documents )

    >> Flex.match_all :type => 'post'

Notice that we don't pass the :index, since it is already defined - application wide - in the initializer

So as we see the sync does sync the record with a document. The document contains all the fields of the record, but we may want to index only those relevant to our search. In other words, we structure the document in the index with the data that we will use for search and display the result, and that is rarely the same data in the record. So we can use the flex_source method:

    def flex_source
      {:some_field => some_field,
       :some_other_field => some_other_field}
    end

Now create a new record in the console, then check the relative document: notice that now it contains only the fields that we defined in the flex_source.

...

The structure returned by flex_source is not limited to the fields in the record, we can index any arbitrary data we want. In particular we may want to add some data from some associated models. So let's add a Comment model


    class Post < ActiveRecord::Base
      has_many :comments
      include Flex::ModelIndexer
      sync self
    end

    class Comment < ActiveRecord::Base
      belongs_to :post
    end

add another migration and some fields for Comment

Now we could add something from the Comment related record. To make it simple for this tut, we can just add the comments count to the Post document, so we can simply modify the flex_source method:

    def flex_source
      {:some_field => some_field,
       :some_other_field => some_other_field,
       :comments_count => comments.size}
    end

Now each time we save a Post the indexed document will contain also the :comments_count for that post. There is only one missing thing: we should sync the Post also when we add or remove a Comment, or the count will not be correct. We can do so by syncing the Post from the Comment.

    class Comment < ActiveRecord::Base
      belongs_to :post
      include Flex::ModelSyncer
      sync :post
    end

Notice that we include Flex::ModelSyncer, and not Flex::ModelIndexer. That's because we don't need to index the Comment, we need only to sync it.

>__Notice__: Flex::ModelIndexer includes Flex::ModelSyncer, so it can sync as well


(* do something in the console to show that the comment_count gets updated each time we add or delete a comment


## Search

### Flex Scopes
(* Show that we can add flex-scopes and use them for easy search. Please refers to the "Using flex-scopes with ActiveRecord Models" in teh flex-scope doc to setup the scope in the Post model)

### Templates

Scopes are cool and reusable, but sometimes we may need to use the full power of elasticsearch, building complex queries to get exactly what we need. We do so by using the Flex Search Templates.

Add

    include Flex::Templates

to the Post class

Let's suppose we have just one complex query for that particular indexed model. to make this tutorial simple, we don't even use a complex query, just a simple one, but keep in mind that you can build every possible elasticsearch query with templates, without any limitation.

We can do so in 2 ways: one is adding the search template right in the model, and the other is adding a Template Source file and loading it into the model. The first way is probably simpler to understand so we will use that one in this tutorial, but if we need a few templates, and/or if the templates are complex, using a Template Source is a lot cleaner. (refers to the doc in Templating

(* adapt the following code to our example )

    flex.define_search :a_named_template, <<-yaml
      query:
        query_string:
          query: <<the_string>>
        ...
      yaml

As you see we use exactly the same elasticsearc structure, we just use yaml instead of json, since it is easier, but we could use a json string or even a ruby structure. We just create a tag where we want to interpolate some variable.

Use the template in the console: (* adapt it to our example )

    >> result = Post.a_named_template :the_string => '..'

Play also with the result: (* see the doc )

    >> result.collection.each ....
