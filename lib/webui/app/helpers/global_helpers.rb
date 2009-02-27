module Merb
  module GlobalHelpers
    def pilot_gmcs
    	Gmc.all
    end
    
    # Returns a generic-looking HTML tag
    # which says "nothing interesting here!"
    def na
    	%q{<span class="na">n/a</span>}
    end
  end
end
