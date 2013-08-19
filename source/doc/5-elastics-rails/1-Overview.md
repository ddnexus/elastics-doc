---
layout: doc
badge: elastics-rails
title: elastics-rails - Overview
alias_index: true
---

# {{ page.title }}

The `elastics-rails` gem provides the engine and generators to integrate the elastics gems with `Rails`. It also loads the `elastics-client`, `elastics-scopes` and `elastics-models` gems, so you don't have to explicitly include them in the Gemfile, unless you need to force some special version or commit. On the other hand you may want to add the `elastics-admin` gem which is optional.

## Setup

### 1. Customize the `Gemfile`

Add the following to your Gemfile:

{% highlight ruby %}
# use one of the following
# libcurl C based http client - faster
gem 'patron'
# pure ruby http client - more compatible
# gem 'rest-client'
gem 'elastics-rails'
# use elastics-admin if you need to dump/load/rename/live-reindex
# gem 'elastics-admin'
{% endhighlight %}

> __Temporary Note__: The `patron` gem currently available on rubygem (v0.4.18) is missing the support for sending data with delete queries. As the result it fails with the `delete_by_query` elasticsearch API, when the query is the request body and not the param. If you want full support until a new version will be pushed to rubygems, you should use `gem 'patron', '0.4.18', :git => 'https://github.com/elastics/patron.git'` or switch to the `rest-client` gem.

### 2. Run `bundle install`

### 3. Run `rails generate elastics:setup`

That will install the needed files with comments and stubs.

## Work Flow

### 1. Customize your models

Add the `include Elastics::<some_model_module>` to the model that need it {% see 4 %}.

- Each time you include a `Elastics::ModelIndexer` or `Elastics::ActiveModel` you should add its name to the `config/initializers/elastics.rb`
- Each time you alter the way your models generate the source that will be indexed (for example by changing your `elastics_source` methods or adding/changing a `elastics.parent` relation in a model) you should reindex your DB(s) {% see 6.2 %}

### 2. Customize the `config/initializers/elastics.rb`

In this initializer you must add the `elastics_models` and/or `elastics_active_models` arrays. They are the names or the classes of the models that you customized with `include Elastics::ModelIndexer` or `include Elastics::ActiveModel`, and may want to customize other configuration variables. For example:

{% highlight ruby %}
Elastics::Configuration.configure do |config|
  config.elastics_models = %w[ Project ]
  config.elastics_active_models = %w[ WebContent ]
  config.result_extenders |= [YourResultExtenderA, YourResultExtenderB, ...]
  config.variables.deep_merge! :index => 'test',
                               :type  => 'project'
end
{% endhighlight %}

{% see 1.3 %}

### 3. Customize `config/elastics.yml`

This is an optional yaml file used to add custom mapping to your index or indices. You don't need to use it unless you start to map your index/indices better. Elastics provides a quite detailed mapping by default, keeping into consideration all your indexed models and also parent/child relationships. Your file will be deep merged with the structure that Elastics will prepare on its own. You can inspect the mapping in the console with one of:

{% highlight irb %}
>> Elastics.get_mapping
>> Elastics.get_mapping :index => 'the_index', :type => nil
{% endhighlight %}


While at it you can get info about the method and the usage of `get_mapping` by doing as usual:

{% highlight irb %}
>> Elastics.doc :get_mapping
{% endhighlight %}

{% see 2.5 %}

### 4. Run `rake elastics:index:create` or `rake elastics:import`

You sould use either `rake elastics:index:create` or `rake elastics:import` (if you already have data to index from your DB) in order to create a new index and its auto-generated mapping.

### 5. Customize the `app/elastics/*`

Usually contains your search classes (those that include any of `Elastics::Templates`, `Elastics::ModelIndexer`, etc.) and your Tempates Sources {% see 2.3.2 %}. Average applications usually have just one class and one source template file but your mileage may vary. Here you can also add your Result Extenders modules {% see 2.4 %}, so keeping all the Elastics related files together.

## Rails 3 and 4

Elastics comes with a Rails engine that integrates with your app very easily. The engine sets a few configuration defaults:

 * `config.elastics.variables[:index]` to your application's underscored name, plus the current `Rails.env` (e.g. `'my_app_development'`)
 * `config.elastics.config_file` default path to `"#{Rails.root}/config/elastics.yml"`
 * `config.elastics.elastics_dir` default path to `"#{Rails.root}/app/elastics"`
 * `config.elastics.logger.level` to `Logger::DEBUG` in development mode (`Logger::WARN` otherwise)
 * `config.elastics.logger.log_to_rails_logger` to `true` for the Rails server and `false` for the Rails console
 * `config.elastics.logger.log_to_stderr` to `false` for the Rails server and `true` for the Rails console
 * `config.elastics.logger.debug_result` to `true` for the Rails server and `false` for the Rails console

{% see 1.3 %}

## Per Environment Configuration

You might want to have different configuration settings for different environments. You can do so by using the `config.elastics` object in the environment file, for example:

{% highlight ruby %}
config.elastics.http_client          = Elastics::HttpClients::RestClient
config.elastics.http_client.base_uri = 'http://localhost:9400'
{% endhighlight %}

## Rails 2

You can use Elastics with Rails 2 applications as well, just remember that you should require `elastics-rails` so it will set the `config_file` and `elastics_dir` paths for you {% see 1.3 %}, but remember that the default `config.elastics.variables[:index]` variable and the `config.elastics.app_id` for Rails 2 are not set so you better configure them, somewhere. Also remember that you should explicitly call `Elastics::Rails::Helper.after_initialize` to complete the rails integration. Except this little difference in the configuration, there is no other difference from Rails 3 and 4.

