---
layout: doc
title: Flex Overview
alias_index: true
alias: /doc
---

# {{ page.title }}

Flex is the ultimate ruby client for [elasticsearch][], it is powerful, fast and efficient, easy to use and customize.

It covers ALL the elasticsearch API, and transparently integrates it with your app and its components (like `Rails`, `ActiveRecord`, `Mongoid`, `ActiveModel`, `will_paginate`, `kaminari`, `elasticsearch-mapper-attachments`, ...).

It also implement and integrates very advanced features, (like chainable scopes, live-reindex, cross-model syncing, query fragment reuse, parent/child relationships, templating, self-documentation tools, detailed debugging, ...).


* __Easy to use even for beginners__<br>
If you have almost no elasticsearch knowledge, fear not! You can populate and search the elasticsearch index as it were an `ActiveRecord` DB, using very familiar chainable scopes and finders, validation and callbacks that you are used to master in your models {% see 3, 4.3 %}

* __Powerful for experts__<br>
Flex provides 6 different ways to interact with elasticsearch, useful in different contexts. From a fully automatic integration, to a very low-level manual interaction; a clever and powerful templating system that covers all the elaticsearch API {% see 2.2 %}; <u>all</u> the standard elasticsearch API as ready to use methods; very detailed debugging info, high configurable logging, etc. {% see 1.2 %}, very easy to use live-reindexing {% see 4.6 %}

* __Easy to learn__<br>
Flex doesn't try to create any "powerful DSL" on top of the elasticsearch API: it just transparently uses the elasticsearch API, so you will never have to learn anything twice or adapt any elasticsearch query to use with ruby, a very common practice needed with other clients {% see 7.1 %}.

* __DRY__<br>
You can reuse full queries, or part of them to build other queries, interpolate variables into queries at request time, or define and use smart cascading defaults to reduce clutter and duplications. Flex creates the needed methods in your classes for you, so 99% of the times you will have just to use them in your code, and for the other 1% you will just need to define a simple wrapper method.

* __Self Documenting__<br>
Flex creates the documentation of your custom templates complete with usage examples. You can get it by simply calling a method... also very handy in the console {% see 2.4 %}.

* __Fast and Efficient__<br>
Flex uses a fast libcurl HTTP client that is at least twice as fast as a pure ruby client (but you can fallback to pure ruby if you need to). It reuses the same HTTP session between different requests saving time and resources. It extends the elasticsearch result objects instead of duplicating new structures, saving memory. It compiles the YAML templates into ruby code at startup time and just calls it at render time for faster execution.

* __Clean separation of the elasticsearch logic from the application logic__<br>
Flex uses simple YAML documents (templates that you define) to encapsulate the whole request/response cycle with the elasticsearch server, relegating the elasticsearch logic away from the application logic. Your code will be clean, easy to write and read, and very short: "poetic-short".

* __Easily Extendable__<br>
Flex provides a simple mechanism to extend all or just specific elasticsearch results with your own methods. That is a lot cleaner and self contained than extending the results in the application code {% see 2.3 %}.

* __Fully Integrated__<br>
{% see 1.1#out_of_the_box_integrations %}

## Gems

The functionality of flex are conveniently organized and integrated by a few gems. You can use them together or separately, depending on your needs.

{% slim gems_table.slim %}

## Tech Specs

### Requirements

* `ruby` >= 1.8.7
* `elasticsearch` >= 0.19.2

### Installation

1. Install the gem `patron` (faster, libcurl C based) or `rest-client` (pure ruby)
2. Install the flex gem(s) {% see 1.1#gems %}

> __Temporary Note__: The `patron` gem currently available on rubygem (v0.4.18) is missing the support for sending data with delete queries. As the result it fails with the `delete_by_query` elasticsearch API, when the query is the request body and not the param. If you want full support until a new version will be pushed to rubygems, you should download [patron-0.4.18.flex.gem]({{site.baseurl}}/patron-0.4.18.flex.gem), install it with `gem install /path/to/patron-0.4.18.flex.gem --local` and be sure your app will use that version, or switch to the `rest-client` gem.

### Out Of The Box Integrations

* `ActiveRecord` 2, 3 and 4 {% see 4.2 %}
* `ActiveModel` 2, 3 and 4 {% see 4.3 %}
* `Mongoid` 2 and 3 {% see 4.2 %}
* `Rails` 2, 3 and 4 {% see 5 %}
* `elasticsearch-mapper-attachments` plugin {% see 4.4.3#attribute_attachment %}
* `will_paginate` and `kaminari` recent versions

## Configuration

Flex needs just a few lines of configuration. However you can use more configuration settings to fine-tune its behavior and/or defining smart defaults that will reduce the need to pass variables explicitly {% see 1.3 %}.
