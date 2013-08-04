---
layout: doc
title: Configuration
---

# {{page.title}}

This class is also aliased as `Flex::Conf`.

You can configure the flex gems by changing their configuration settings. You can set them directly in any part of your code or the console like:

{% highlight ruby %}
Flex::Configuration.logger.debug_result = true
{% endhighlight  %}

or setting them inside a `Flex::Configuration.configure` block:

{% highlight ruby %}
Flex::Configuration.configure do |conf|
  conf.http_client.base_uri = 'http://localhost:9222'
  conf.http_client.options  = {:timeout => 10}
  conf.variables[:index]    = 'my_index'
  ...
end
{% endhighlight  %}

If you use the rails integration, you usually do so in an initializer, usually generated by the `flex:setup` generator {% see 5 %}.

## Settings

{% slim config_table.slim %}