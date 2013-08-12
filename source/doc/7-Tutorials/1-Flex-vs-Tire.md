---
layout: doc
title: Why you should use Flex rather than Tire
alias_index: true
---

# {{ page.title }}

I wrote this page because it looks like it is still not very clear what flex does and what are the differences with Tire (as you can read [here](http://stackoverflow.com/questions/14517686/integrating-elasticsearch-with-activerecord)), and also because I honestly think that if you are serious with elasticsearch, you have plenty of reasons to use Flex rather than Tire.

> __Notice__: Being the author of Flex, it's difficult not being biased, but I will try to present the facts that support my opinions. Please, correct me if I am wrong or imprecise and I will fix any eventual mistake right away. Thanks.

## Quick Facts Comparison Table

This is just a quick overview showing the main differences between the 2 projects: the rest of this writeup is dedicated to the detailed analysis of the differences.

{% slim comparison_table.slim %}

## Detailed Analysis

### My experience with Tire

I had to refactor a few quite similar Rails apps that were using Tire to index a few ActiveRecord and Mongoid models. At that time I didn't have any experience with Tire, so I just assumed everything was OK and I focused only on removing the mess in the ruby code. There were lots of `Tire.search('lots,of,indices'){lots{of{nested{blocks}}}}` scattered everywhere in the apps. That didn't look nice nor easy to maintain, so as the first step, I decided to create a central module, moving all the search logic in one single place, hopefully trying to reduce the duplications with well designed methods.

After working on that first step, the controllers were cleaner, but the search module looked like a bunch of long wrapper methods: one per each `Tire.search` calls extracted from the controllers. There was a lot of duplicated or very similar code inside that blocks, so I though I could extract the common parts to some helper method, but I soon discovered that it's a problem with Tire.

### The Tire DSL

Tire uses its own DSL to express elasticsearch queries. Cool, isn't it? Well, in practice... it isn't, and here's why.

#### Difficult Variable Interpolation

A very natural need when you search, is interpolating your variables into the elasticsearch query. With the Tire DSL you don't have access to any variable or methods external to the search block, unless you use a cumbersome way suggested in the Tire doc. In practice you have to pass around the objects of the outer block:

{% highlight ruby %}
@query = 'title:T*'
Tire.search 'articles' do |search|
  search.query do |query|
    query.string @query
  end
end
{% endhighlight %}

That block looks pretty verbose, isn't it? Specially if you know that the only thing it does is generating a simple structure:

{% highlight ruby %}
{query: {query_string: {query: @query}}}
{% endhighlight %}

> It gets even worse if you add other stuff, like order or facets, but this simple example is enough to get the point.

The elasticsearch API is very clear and simple because it is expressed by basic data structures, that are simple to write, read and merge with variables or other structures. A ruby DSL seems just to make these simple things more difficult without adding any benefit.

> Flex variable interpolation is really a no-brainer with its simple placeholder tags, placed right in the queries where they have to be interpolated {% see 7.3#adding_flex_templates %}.

#### Difficult and Very Limited Reusability

Another natural need using elasticsearch would be reusing fragments of structures for many queries. With the Tire DSL you cannot merge parts of queries. You have only a very limited and vague resemblance of reusability: saving procs of boolean queries and sort of "reuse" them inside the DSL.

{% highlight ruby %}
tags_query = lambda do |boolean|
  boolean.should { string 'tags:ruby' }
  boolean.should { string 'tags:java' }
end

published_on_query = lambda do |boolean|
  boolean.must   { string 'published_on:[2011-01-01 TO 2011-01-02]' }
end

Tire.search 'articles' do
  query do
    boolean &tags_query
    boolean &published_on_query
  end
end
{% endhighlight %}

As if that alone wouldn't be enough complex even without variables, at some point you will have also to interpolate your variables into that boolean queries by using some closure, and eventually you will have to wrap the procs in a method just to pass the variables. Ouch!

> Flex allows you to reuse any fragment of any query into any other query {% see 2.3.2#query_fragment_reuse %}. You can even use chainable scopes to pure ruby reusability {% see 3 %}

#### Hard Coded Limitations

Tire creates a search object each time you search anything. The search object expects a fixed number of possible data parts and uses that parts to compose the query. That strategy has many limitations (as you have just read), but in particular, it is limited to what the search class explicitly allows and is aware of. For example, you cannot use any query not explicitly known by Tire, and if I am not mistaken, they are just about 7 at the moment of this writing, which means that you don't have access to the 80% of the elasticsearch search queries. Besides, if you need any other elasticsearch API or feature not explicitly known by Tire, you are on your own.

IMO Elasticsearch is very powerful and rich: limiting it is sort of defeating the very reason you choose it.

> Flex is query-agnostic: you can use it for every query, even for the queries that will be implemented in some future version of elasticsearch.

#### Reverse Engineering Required

There is another flaw with the Tire DSL: often you know exactly how to express a structured elasticsearch query (and you know it because you have probably just found it in the elasticsearch doc). If you are lucky enough, that may be a query that Tire supports: great! But then you have to think about how to tell Tire to express the same structure with its own different DSL.

For example you have to pass the index/indices as the first param, but you have to pass the type as a key/value pair in the options hash. You may also have to pass other key/values that in elasticsearch are part of the query structure itself, but in Tire have been moved to the options. Then you have to write the query in nested ruby blocks: some looks quite similar to the elasticsearch query structure, but others don't.

All that reverse-engineering effort... only to make Tire generate the same simple structure you wanted and knew from the beginning. That looks quite twisted to me. I often wished to get rid of Tire and get straight to elasticsearch.

> You don't need to reverse-engineer anything with Flex, because it can express queries by using exactly the same elasticsearch structures, just easier to read, write and reuse since you can express them in `YAML` {% see 7.3#adding_flex_templates %}.

#### Pros and Cons

I can guess that the goal behind the Tire DSL is simplifying the elasticsearch query structure and making it more ruby-like, so to simplify the elasticsearch structure a bit. For example with Tire you can "just" write `{|search| search.query {|query| query.string @query }}` instead of `{query: {query_string: {query: @query}}}` as you whould do with elasticsearch.

> If you are seeking simplicity, with `flex-scopes` you can just write `query(@query)` to express the same, and you can even chain it to other scopes at any time, so easily merging search criteria {% see 3 %}.

 The Tire DSL looks more verbose and less elegant of the original elasticsearch structure that it's supposed to simplify, however, if you carefully count the brackets, you can spot that Tire saved one nesting level, so maybe that one is the advantage. Anyway, it looks like the cons are overwhelmingly more than the pros (if any). Indeed the Tire DSL forces you to renounce to a lot of benefits:

- lost match with the original and documented elasticsearch structure (reverse-engineering needed)
- lost direct options coming from the elasticsearch nested level that Tire removes
- lost easy variable interpolation
- lost merging and reuse of partial structures
- lost all the queries that the Tire DSL doesn't explicitly know

And if you want to have the lost benefits back (if at all possible), you end up with something a lot more complex than what Tire tries to simplify. So despite the good intentions, using a ruby DSL to manage data structures, doesn't seem a good idea.

>__Notice__: The `flex-scopes` gem pursues a goal quite similar to the Tire DSL: simplifying the elasticsearch query structure and making it more ruby-like. However, unlike Tire, it adds quite a few benefits, effectively simplifying your code and making it very reusable {% see 3 %}.

### Model Integration

The model integration support in Tire is very basic.

#### No Cross-syncing

Tire does not provide any mean to cross-sync models, i.e. you may need to reindex one or more records when another record changes. With Tire, if you want to do that you must do it by yourself by using `:touch` (so re-saving the related record, which will trigger the callback that will reindex it), or you have to define your own callbacks and explicitly index the related records.

Cross-syncing is a very useful tool when you don't want to mirror your DBs structure into your index structure, but you want to design your index in such a way that it will be easy and efficient to search.

> Flex manages (and propagates) cross-syncing with a simple one-line declaration {% see 4.4.1 %}

#### No parent/children relations

Tire does not support parent/child relations. Implementing it on your own for each application that may need it, requires quite an effort: you have to set the right mapping, pass around the parent and the routing when any record in the relationship changes. If you have several models involved that may be quite time consuming and error prone.

> Flex manages all that internally: you need only to write a one-line declaration {% see 4.2#elasticsearch_parentchildren_relations Parent/Children Relations %}

#### Dispersed Settings and Mapping

And what about defining the index settings and mappings in the model itself? Again, you have to reverse engineer the elasticsearch structure to the Tire's own DSL in order to do that, but the real design problem here is that you should be allowed to design an optimized index structure that may be completely different from the DB/model structure.

That suggests that the index structure should play an application-global role, rather than a local-model role, so you should be allowed to manage the index/indices centrally, in a single application-wide file, instead of being forced to manage that at the model level. And besides the design advantage, a central file would also allow less polluted models and easy sharing of common properties among different models.

> Flex allows you to map any DB structure to any index structure. It generates for you the mapping defaults that keep into consideration also parent/child relations and properties you may define in your models. However you can fine-tune them in a central `YAML` file (a sort of `database.yml` for indices).

#### Model Centric Defaults

Surprisingly, the Tire's defaults generate one index per model, each index populated by one single type. That means that - by default - you have a completely _model-centric_ design, instead of a more useful _application-centric_ design (as already outlined in the previous topic). Beside there is another surprise if you run multiple applications that have some model class with the same name. By default, your indices will be shared among different applications because they define the same model classes. I don't think you want to index the posts of the "Racing Forum" app in the same index of the "Furniture Forum" app just because they are both managed by a `Post` model.

That doesn't look like the best default design to start an application with. For example, a simple and basic "one index per app, one type per model" default would do for most apps: it would be _application-centric_ and would avoid unwanted index sharing by default. Besides, that's similar to the familiar concept "one DB per app, one table per model".

> Flex is application-centric by default: it embraces "one index per app, one type per model" design to start with, however, if your particular app needs to split apart the index or manage the indices dynamically, it's just a matter of adding a simple definition in the model {% see 4.4.2#overriding_flex_metafields %}.

### Flex Project

At a certain point of that refactoring I get tired of complaining about Tire, and decided to roll up my sleeves and write an alternative. Many thanks to [Escalate Media](http://www.escalatemedia.com) and [Barquin International](http://www.barquin.com) that supported the idea of releasing it as an Open Source Software and keep sponsorizing the project.

Here is the list of requirements for the first version of flex, and how they have been implemented.

{% slim flex_requirements_table.slim %}

### Migrating from Tire to Flex

After migrating the apps (described in the [previous section](#my_experience_with_tire)) from Tire to Flex, the searching code became stunnigly short: the search module shrinked down from more than 300 lines to just 4 lines! All the search logic was in a single, very readable `YAML` file of less than 100 lines. The queries were beautifully matching 1 to 1 with the elasticsearch API, and the variable interpolations were elegantly represented by simple placeholder tags, right in the queries (where they have to be interpolated). Besides, we could easily implement polymorphic parent/children relations in several models with just one line per model, and with another line we could cross-sync a few others.

Not bad for the first version of the gem!

> __Notice__: Migrating an app from Tire to Flex is not difficult, but the 2 interfaces are very different, so you should already have played with flex a little in order to know how to reorganize your app.

### Improvements in Flex 1.0

Now, after one year of active usage and development, the current version of flex includes a lot of improvements and additions. Its code has been optimized and organized into 5 gems that you can use together or separately.

It's easier to use also for elasticsearch beginners, since it implements `ActiveRecord`-like chainable scopes for easy searching and reusability, plus the `ActiveModel` integration to manage elasticsearch as it were an `ActiveRecord` DB.

It's also more powerful for experts, since it covers all the elasticsearch APIs {% see 2.2 %} and offers a lot of useful tools like index dumping and loading {% see 6 %}, a very advanced live-reindex feature {% see 6.2 %}, very detailed debugging info, high configurable logging, a self documenting tool, a lot of out of the box integrations, and a better documentation with some tutorial {% see 1.1 %}.

> Flex does not have a dedicated testing suite yet: its testing is still embedded in a few applications that exploit its features. If you have some spare time, please, contribute.


### Conclusion

Flex is very different from Tire: it enforces almost the opposite concepts in most areas. In its basic usage it is easier to use than Tire, and in its advanced usage it implements a lot more tools and features. So which one should you choose for your elasticsearch interactions?

I honestly don't see any reason to choose Tire, while I see plenty of compelling reasons to choose Flex, but I may be biased, so if you have a different opinion I would like to know it and possibly learn from you. Please, don't hesitate to send me your comments on this writeup. Thanks.
