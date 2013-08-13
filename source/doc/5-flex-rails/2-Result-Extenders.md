---
layout: doc
badge: flex-rails
title: flex-rails - Result Extenders
---

# {{ page.title }}

The `flex-rails` gem adds an extender to the standard extended `Flex::Result` object {% see 2.4 %}.

* __`Flex::Result::RailsHelper`__<br>
  It extends the results coming from a search query. It adds the following method to the document in the collection:

  * __`document.highlighted_*`__<br>
    This methods return the joined string from the elasticsearch `highlights` for any attribute. If there are no highlights and the attribute exists they return the attribute, in any other case they return an empty string. They always return a string, and that's handy for using them in rails views, in conjuction with strings helpers. You can also pass an hash of options: currently only the `:fragment_separator` string, which is the string that will join the highlights (`" ... "` by default).

For example, if you asked to highlight the 'ruby' term:

{% highlight irb %}
# if there are highlights you gets the joined highlight fragments
>> document.highlighted_content
#=> "the <em>Ruby</em> way ... any <em>ruby</em> method"

# if there are no highlights but the attribute exists ('title' in the following example) you get the attribute
>> document.highlighted_title
#=> "Programming Languages"

# if there are no highlights nor attributes named with that name you get an empty string
>> document.highlighted_some_missing_attribute
#=> ""
{% endhighlight %}
