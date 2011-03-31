# Unused, keeping for later use.
module Gofer
  class Options
    VALID_OPTIONS => %w{identity_file}

    def valid_options
      VALID_OPTIONS
    end
  
    def initialize
      @options = {}
    end

    def merge_in opts={}
      opts.each |k,v|
        set k, v
      end
    end
  
    def set k, v
      k = option_valid_check(k)
      @options[k] = v
    end

    def get k
      k = option_valid_check(k)
      @options[k] 
    end
   
    private

    def option_valid_check(k) 
      k = k.to_s
      raise "Invalid option #{k}" unless valid_options.include?(k)
    end
  end
end
