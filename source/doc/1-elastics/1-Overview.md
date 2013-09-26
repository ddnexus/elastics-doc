---
layout: doc
badge: elastics-client
title: Elastics Overview
alias_index: true
alias: /doc
---

# {{ page.title }}

__Elastics__ _(used as a plural noun, meaning "rubber bands")_ is a collection of ruby tools for [elasticsearch][]. It is powerful, fast and efficient, easy to use and customize.

It covers ALL the elasticsearch API, and transparently integrates it with your app and its components, like `Rails`, `ActiveRecord`, `Mongoid`, `ActiveModel`, `will_paginate`, `kaminari`, `elasticsearch-mapper-attachments`, ...

It also implements and integrates very advanced features like chainable scopes, live-reindex, cross-model syncing, query fragment reuse, parent/child relationships, templating, self-documenting tools, detailed debugging, ...


* __Easy to use even for beginners__<br>
If you have almost no elasticsearch knowledge, fear not! You can populate and search the elasticsearch index as it were an `ActiveRecord` DB, using very familiar chainable scopes and finders, validation and callbacks that you are used to master in your models {% see 3, 4.3 %}

* __Powerful for experts__<br>
Elastics provides 6 different ways to interact with elasticsearch, useful in different contexts. From a fully automatic integration, to a very low-level manual interaction; a clever and powerful templating system that covers all the elaticsearch API {% see 2.3 %}; <u>all</u> the standard elasticsearch API as ready to use methods; very detailed debugging info, high configurable logging, etc. {% see 1.2 %}, very easy to use live-reindexing {% see 6.2 %}

* __Easy to learn__<br>
Elastics doesn't try to create any "powerful DSL" on top of the elasticsearch API: it just transparently uses the elasticsearch API, so you will never have to learn anything twice or adapt any elasticsearch query to use with ruby, a very common practice needed with other clients {% see 7.1 %}.

* __DRY__<br>
You can reuse full queries, or part of them to build other queries, interpolate variables into queries at request time, or define and use smart cascading defaults to reduce clutter and duplications. Elastics creates the needed methods in your classes for you, so 99% of the times you will have just to use them in your code, and for the other 1% you will just need to define a simple wrapper method.

* __Self Documenting__<br>
Elastics creates the documentation of your custom templates complete with usage examples. You can get it by simply calling a method... also very handy in the console {% see 2.5 %}.

* __Fast and Efficient__<br>
Elastics uses a fast libcurl HTTP client that is at least twice as fast as a pure ruby client (but you can fallback to pure ruby if you need to). It reuses the same HTTP session between different requests saving time and resources. It extends the elasticsearch result objects instead of duplicating new structures, saving memory. It compiles the YAML templates into ruby code at startup time and just calls it at render time for faster execution.

* __Clean separation of the elasticsearch logic from the application logic__<br>
Elastics uses simple YAML documents (templates that you define) to encapsulate the whole request/response cycle with the elasticsearch server, relegating the elasticsearch logic away from the application logic. Your code will be clean, easy to write and read, and very short: "poetic-short".

* __Easily Extendable__<br>
Elastics provides a simple mechanism to extend all or just specific elasticsearch results with your own methods. That is a lot cleaner and self contained than extending the results in the application code {% see 2.4 %}.

* __Fully Integrated__<br>
{% see 1.1#out_of_the_box_integrations %}

## Quick Start

The Elastics documentation is very complete and detailed, so starting from the right topic for you will save you time. Please, pick the starting point that better describes you below:

### For Tire Users

1. You may be interested to start from [Why you should use Elastics rather than Tire](http://elastics.github.io/elastics/doc/7-Tutorials/1-Elastics-vs-Tire.html) that is a direct comparison between the two projects.

2. Depending on your elasticsearch knowledge you can read below the "Elasticsearch Beginner" or the "Elasticsearch Expert" starting point sections.

### For Flex 0.x Users

1. If you used an old flex version, please start with [How to migrate from flex 0.x](http://elastics.github.io/elastics/doc/7-Tutorials/2-Migrate-from-0.x.html).

2. Depending on your elasticsearch knowledge you can read below the "Elasticsearch Beginner" or the "Elasticsearch Expert" sections.

### For Elasticsearch Beginners

1. You may want to start with the [Index and Search External Data](http://elastics.github.io/elastics/doc/7-Tutorials/4-Index-and-Search-External-Data.md) tutorial, since it practically doesn't require any elasticsearch knowledge. It will show you how to build your own search application with just a few lines of code. You will crawl a site, extract its content and build a simple user interface to search it with elasticsearch.

2. Then you may want to read the [Usage Overview](http://elastics.github.io/elastics/doc/1-Elastics-Project/2-Usage-Overview.html) page. Follow the links from there in order to dig into the topics that interest you.

3. You will probably like the [elastics-scopes](http://elastics.github.io/elastics/doc/3-elastics-scopes) that allows you to easy search, chain toghether and reuse searching scopes in pure ruby.

### For Elasticsearch Experts

1. Elastics provides the full elasticsearch APIs as ready to use methods. Just take a look at the [API Methods](http://elastics.github.io/elastics/doc/2-elastics/2-API-Methods.html) page to appreciate its completeness.

2. Then you may want to read the [Usage Overview](http://elastics.github.io/elastics/doc/1-Elastics-Project/2-Usage-Overview.html) page. Follow the links from there in order to dig into the topics that interest you.

3. If you are used to create complex searching logic, you will certainly appreciate the [Templating System](http://elastics.github.io/elastics/doc/2-elastics/3-Templating) that gives you real power with great simplicity.

4. As an elasticsearch expert, you will certainly appreciate the [Live-Reindex](http://elastics.github.io/elastics/doc/6-elastics-admin/2-Live-Reindex.html) feature: it encapsulates the solution to a quite complex problem in just one method call.

## Gems

The functionality of elastics are conveniently organized and integrated by a few gems. You can use them together or separately, depending on your needs.

{% slim gems_table.slim %}

## Tech Specs

### Requirements

* `ruby` >= 1.8.7
* `elasticsearch` >= 0.19.2

### Installation

1. Install the gem `patron` (faster, libcurl C based) or `rest-client` (pure ruby)
2. Install the elastics gem(s) {% see 1.1#gems %}

> __Temporary Note__: The `patron` gem currently available on rubygem (v0.4.18) is missing the support for sending data with delete queries. As the result it fails with the `delete_by_query` elasticsearch API, when the query is the request body and not the param. If you want full support until a new version will be pushed to rubygems, you should use `gem 'patron', :git => 'https://github.com/patron/patron.git'` or switch to the `rest-client` gem.

### Out Of The Box Integrations

* `ActiveRecord` 2, 3 and 4 {% see 4.2 %}
* `ActiveModel` 2, 3 and 4 {% see 4.3 %}
* `Mongoid` 2 and 3 {% see 4.2 %}
* `Rails` 2, 3 and 4 {% see 5 %}
* `elasticsearch-mapper-attachments` plugin {% see 4.4.3#attribute_attachment %}
* `will_paginate` and `kaminari` recent versions

## Configuration

Elastics needs just a few lines of configuration. However you can use more configuration settings to fine-tune its behavior and/or defining smart defaults that will reduce the need to pass variables explicitly {% see 1.3 %}.
