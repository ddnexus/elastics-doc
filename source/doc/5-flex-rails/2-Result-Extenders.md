---
layout: doc
title: flex-rails - Result Extenders
---

# {{ page.title }}

The `flex-rails` gem adds an extender to the standard extended `Flex::Result` object {% see 2.3 %}.

* __`Flex::Result::RailsHelper`__<br>
  It extends the results coming from a search query. It adds the following method to the document in the collection:

  * __`document.highlighted_*`__<br>
    This methods return the joined string from the elasticsearch `highlights` for any attribute, if there are no highlights and the attribute exists they return the attribute, or an empty string in any other case. They always return a string (even if empty), and that's handy for using them in rails views, in conjuction with strings helpers.

For example, if you asked to highlight the 'ruby' term:

{% highlight ruby %}
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