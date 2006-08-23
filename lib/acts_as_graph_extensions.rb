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
          
          # Calls &block once for each node in collection, recursively, 
          # passing that node as a parameter.  Currently implemented as 
          # a depth first search.
          #
          # :call-seq:
          #   each { |node| ... }
          def each(seen = [], &block) # :yields: node
            @collection.each do |node|
              if not seen.include?(node)
                seen << node  # mark the node as seen so we don't visit it twice
                node_collection = node.send(@reflection.name)
                node_collection.recursive.each(seen, &block)
                block.call(node)
              end
            end
          end

          # Returns all nodes in the current collection 
          # and all sub-collections (collected recursively).
          def to_a() # :doc:
            self.inject([]) { |ary,x| ary << x }
          end
          
          def method_missing(message, *args)
            self.to_a.send(message, args)
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
            if @reflection.name == :children    # options[:child_collection]
              other_reflection_name = :parents  # options[:parent_collection]
            else 
              other_reflection_name = :children # options[:child_collection]
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