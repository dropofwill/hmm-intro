"use strict"
### Dev Mode: console.logs are running
# window.DEBUG = true
# Prod Mode: console.logs are off
# window.DEBUG = false
###

window.DEBUG = true

###
# l(vals...) allows for easy debug toggling with the global constant DEBUG
# Pass in as many arguments as you like and they will be logged out
###
window.l = (vals...) ->
  console.log(vals...) if DEBUG
  # vals.forEach (v) ->
  #   console.log(v) if DEBUG

###
# Defines a function which creates or adds onto an existing object in the
# global scope
#
# prop: global property on the window object
###
window.configGlobal = (prop) ->
  () ->
    window[prop] = window[prop] || {}

  ###
  # Inclusive random range between to floats a, b
  ###
window.inc_random = (lower=0, upper=1) ->
    lower + Math.floor(Math.random() * (upper - lower + 1))

window.configApp = configGlobal("app")
