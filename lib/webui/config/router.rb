# Merb::Router is the request routing mapper for the merb framework.
#
# You can route a specific URL to a controller / action pair:
#
#   match("/contact").
#     to(:controller => "info", :action => "contact")
#
# You can define placeholder parts of the url with the :symbol notation. These
# placeholders will be available in the params hash of your controllers. For example:
#
#   match("/books/:book_id/:action").
#     to(:controller => "books")
#   
# Or, use placeholders in the "to" results for more complicated routing, e.g.:
#
#   match("/admin/:module/:controller/:action/:id").
#     to(:controller => ":module/:controller")
#
# You can specify conditions on the placeholder by passing a hash as the second
# argument of "match"
#
#   match("/registration/:course_name", :course_name => /^[a-z]{3,5}-\d{5}$/).
#     to(:controller => "registration")
#
# You can also use regular expressions, deferred routes, and many other options.
# See merb/specs/merb/router.rb for a fairly complete usage sample.

Merb.logger.info("Compiling routes...")
Merb::Router.prepare do
  match("/messages/").to(:controller => :messages, :action => :index)
  
  # maps for each scope (global/district/gmc); matched before the
  # other views to avoid confusing "map" with a gmc or district
  match("/:district/:gmc/map").to(:controller => :gmc_app, :action => :map)
  match("/:district/map"     ).to(:controller => :district_app, :action => :map)
  match("/map"               ).to(:controller => :global_app, :action => :map)
  
  # provides an overview of what's happening in each scope
  match("/:district/:gmc/").to(:controller => :gmc_app, :action => :index)
  match("/:district/"     ).to(:controller => :district_app, :action => :index)
  match("/"               ).to(:controller => :global_app, :action => :index)
  
  # returns a list of gmcs as json data for each scope
  match("/:district/gmc.json").to(:controller => :district_app, :action => :all_gmc)
  match("/gmc.json"          ).to(:controller => :global_app, :action => :all_gmc)
end
