opts = Jekyll.configuration({})['slim'] || {}
# symbolize keys
opts = opts.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}
Slim::Engine.set_default_options opts

