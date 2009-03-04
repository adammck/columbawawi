# Go to http://wiki.merbivore.com/pages/init-rb
 
require 'config/dependencies.rb'
 
use_orm :datamapper
use_test :rspec
use_template_engine :erb
 
Merb::Config.use do |c|
  c[:use_mutex] = false
  c[:session_store] = 'cookie'  # can also be 'memory', 'memcache', 'container', 'datamapper
  
  # cookie session store configuration
  c[:session_secret_key]  = '70625ecda7f5d764f95a22432291d7e4e8b76138'  # required for cookie session store
  c[:session_id_key] = '_webui_session_id' # cookie session id key, defaults to "_session_id"
end

 
Merb::BootLoader.before_app_loads do
  # This will get executed after dependencies have been loaded but before your app's classes have loaded.
    Merb.push_path(:model, Merb.root / "../" / "models", "/*.rb")
end
 
Merb::BootLoader.after_app_loads do
  # This will get executed after your app's classes have been loaded.
end

Merb.add_mime_type :xls, nil, %w[application/vnd.ms-excel]
Merb.add_mime_type :png, nil, %w[image/png]

#require "gruff"
