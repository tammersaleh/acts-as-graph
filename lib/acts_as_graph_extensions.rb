module TammerSaleh #:nodoc:
  module Acts #:nodoc:
    module Graph #:nodoc
      module Extensions #:nodoc:
        class Recursive
          #--
          # XXX Should make this a proxy obj like AssociationProxy
          #++
          include Enumerable
          
          def initialize(collection, reflection) #:nodoc:
            @collection = collection
            @reflection = reflection
          end
          
          # Yields once for each node in the collection, and 
          # recursively for all nodes in sub-collections.
          def each(&block) # :yields: node
            @collection.each do |node|
              node_collection = node.send(@reflection.name)
              node_collection.recursive.each(&block)
              block.call(node)
            end
          end

          # Returns all nodes in the current collection 
          # and all sub-collections (collected recursively).
          def to_a() # :doc:
            ary = []
            @collection.each { |x| ary << x }
            # @collection.inject([]) { |ary,x| ary << x }
          end
        end

        module HABTM
          #--
          # remember that @reflection.name is set to :children, :parents or :neighbors
          # @owner is set to node that owns collection
          #++
          
          # Returns the recursive object.  This allows you to work on all of the children or parents
          # of the given node.  
          #
          # See link:classes/TammerSaleh/Acts/Graph/Extensions/Recursive.html for details.
          def recursive
            @recursive ||= TammerSaleh::Acts::Graph::Extensions::Recursive.new(self, @reflection)
          end

          # Insert a node into the collection.  Raises an exception if the insertion would create
          # a cycle.
          def <<(*nodes)
            if node_in_collection_twice(nodes) or nodes_already_in_current_collection(nodes)
              raise ArgumentError,
                    "Attempt to add a child node twice when " +
                    ":allow_cycles is set to false."
            elsif not adding_nodes_maintains_DAC?(nodes)
              raise ArgumentError,
                    "Adding #{nodes.size > 1 ? "nodes": "node"} " + 
                    "#{nodes.map(&:id)} to node #{@owner.id} " + 
                    "would create a cycle when " +
                    ":allow_cycles is set to false."
            else  
              super(nodes)
            end
          end
          
          private
          
          def nodes_already_in_current_collection(nodes)
            # The intersection of the args and my immediate children 
            # should be empty
            return (not (nodes & self).empty?)
          end
          
          def node_in_collection_twice(nodes)
            return (nodes.size < nodes.uniq.size)
          end
          
          def adding_nodes_maintains_DAC?(nodes)
            if @reflection.name == :children
              other_reflection_name = :parents
            else 
              other_reflection_name = :children
            end
            
            nodes.each do |new_node|
              return false if @owner.send(other_reflection_name).recursive.include? new_node
            end
            
            return true
          end
        end

      end
    end
  end
end