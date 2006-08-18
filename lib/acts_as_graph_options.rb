module TammerSaleh #:nodoc:
  module Acts #:nodoc:
    module Graph #:nodoc:
      module Options #:nodoc:
        DEFAULTS = {
          :class_name        => :REQUIRED,
          :edge_table        => "#{self.class.to_s.underscore}_edges",
          :parent_col        => "parent_id",
          :child_col         => "child_id",
          :allow_cycles      => false,
          :directed          => true,
          :child_collection  => :children,
          :parent_collection => :parents,
        }

        def self.process(options)
          original_caller = caller[1..-1]
          options.keys.each do |key|
            unless DEFAULTS.has_key? key
              raise ArgumentError, "#{key} is not a supported option.", original_caller
            end
          end
          options = DEFAULTS.update(options)

          unfilled = options.select { |k,v| v == :REQUIRED }.map { |k,v| k }
          unless unfilled.empty?
            raise ArgumentError, 
                  "The following required fields are not given: " + 
                  "#{unfilled.join(', ')}", original_caller
          end
          
          # XXX Need to set default for :edge_table here...
          
          if options[:allow_cycles] then
            raise(ArgumentError, "Cyclic graphs not yet supported", original_caller)
          end
          if not options[:directed] then
            raise(ArgumentError, "Undirected graphs not yet supported", original_caller)
          end
          return options
        end
        
      end
    end
  end
end