window.Nav = class Nav

  constructor: ->
    @container = $('#nav-menu')
    @init()

  init: ->
    $('.isLabel').click (event) ->
      $(this).blur() # FF fix
      event.preventDefault()

$ ->
  window.nav = new Nav

