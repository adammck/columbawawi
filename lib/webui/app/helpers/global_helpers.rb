module Merb
  module GlobalHelpers
    # helpers defined here available to all views. 
    def pilot_gmcs
    	Gmc.all
    end
  end
end
