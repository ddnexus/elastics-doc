window.Toc = class Toc

  constructor: (selectors='h1,h2,h3,table.code-topics tr td:first-child') ->
    @toc     = $('#page-toc')
    @content = $('#content')
    # add the ids to the td.topic so the links will work
    $('body').find('table.code-topics tr td:first-child > code').each ->
      id = $(this).text().replace(/[^\w]/g,'_')
      $(this).parent().attr('id', id)

    @headings  = @content.find(selectors)
    @clicked   = false
    @timeout   = undefined
    @buildToc()
    $(window).bind 'scroll', @highlightOnScroll

    # adjust the hOffsets on page content resize
    @content.resize =>
      @setOffsets()

    @setOffsets()


  setOffsets: ->
    @hOffsets  = []
    @headings.each (i, heading) =>
      @hOffsets.push $(heading).offset().top
      @highlightOnScroll()

  buildToc: ->
    ul  = $('<ul/>')
    toc = this
    @headings.each (i, heading) ->
      $h = $(heading)
      a = $('<a/>').text($h.text())
                   .attr('href', '#' + $h.attr('id'))
                   .click (e) ->
                     $('li', toc.container).removeClass 'toc-active'
                     $(e.target).parent().addClass 'toc-active'
                     toc.clicked = true
                     #$(this).trigger 'selected', $(this).attr('href')
      li = $('<li/>').addClass('toc-' + $h[0].tagName.toLowerCase())
                     .append(a)
      ul.append li
    @toc.append ul


  highlightOnScroll: (e) =>
    clearTimeout @timeout  if @timeout
    @timeout = setTimeout(=>
                            if @clicked is true
                              @clicked = false
                              return
                            top = $(window).scrollTop() + window.scrollOffset + 1
                            i   = 0
                            max = @hOffsets.length-1

                            while i <= max
                              which = switch
                                      when i == 0 && @hOffsets[i] >= top then 0
                                      when @hOffsets[i] >= top           then i-1
                                      when i == max                      then max
                              if which?
                                $('li', @toc).removeClass 'toc-active'
                                $("li:eq(#{which})", @toc).addClass('toc-active')
                                break
                              i++
                          , 100)


$ ->

  window.scrollOffset = 70

  # the page should define the selectors if it needs to override them
  window.toc = new Toc

  animateHighlighted = (el) ->
    $el = $(el)
    old_b = $el.css('backgroundColor')
    $el.animate backgroundColor: '#F99', 700
    $el.animate backgroundColor: old_b, 700

  filterPath = (string) ->
    string.replace(/^\//, '')
      .replace(/(index|default).[a-zA-Z]{3,4}$/, '')
      .replace /\/$/, ''


  # use the first element that is 'scrollable'
  scrollableElement = (els) ->
    i = 0
    argLength = arguments.length
    while i < argLength
      el = arguments[i]
      $scrollElement = $(el)
      if $scrollElement.scrollTop() > 0
        return el
      else
        $scrollElement.scrollTop 1
        isScrollable = $scrollElement.scrollTop() > 0
        $scrollElement.scrollTop 0
        return el if isScrollable
      i++
    []

  locationPath = filterPath(location.pathname)
  scrollElem   = scrollableElement('html', 'body')


  $('a[href*=#]').each ->
    thisPath = filterPath(@pathname) or locationPath
    if locationPath is thisPath and (location.hostname is @hostname or not @hostname) and @hash.replace(/#/, '')
      $target = $(@hash)
      target  = @hash
      if $target.html()?
        $(this).click (event) ->
          event.preventDefault()
          $(scrollElem).animate
            scrollTop: $target.offset().top - window.scrollOffset
          , 400, () ->
            location.hash = target
            $(scrollElem).scrollTop $(target).offset().top - window.scrollOffset
            animateHighlighted($target)

  # when the page loads and has an anchor
  if location.hash
    # webkit needs a delay or the scroll will be lost
    fun = ->
          $(scrollElem).scrollTop $(location.hash).offset().top - window.scrollOffset
          animateHighlighted(location.hash)
    setTimeout(fun, 200)
