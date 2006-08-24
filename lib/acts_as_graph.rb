#require_dependency 'options'
require_dependency 'acts_as_graph_extensions'

# Adds the following collections:
#
# * +self.children+
# * +self.parents+
#
module TammerSaleh  #:nodoc:
  module Acts  #:nodoc:
    module Graph  #:nodoc:
      
      def self.included(mod)  #:nodoc:
        mod.extend(ClassMethods)
      end

      #--
      # declare the class level helper methods which
      # will load the relevant instance methods
      # defined below when invoked
      #++
      module ClassMethods
        
        # Specify this act if you want to model a graph structure by providing a parents association 
        # and a children association. This act requires that you have an edge table (used in the HABTM
        # relationship), which by default is called +CLASS_edges+, which has two columns (+child_id+ and 
        # +parent_id+) where +CLASS+ is the name of your model.
        # 
        # <b>Currently, only DAGs (Directed, Acyclic graphs) are supported</b>.  
        # See {here}[http://en.wikipedia.org/wiki/Directed_acyclic_graph] and
        # {here}[http://mathworld.wolfram.com/AcyclicDigraph.html] for more information.
        # 
        #   class Task < ActiveRecord::Base
        #     acts_as_graph :class_name => "Task", :edge_table => "dependencies"
        #   end
        # 
        #   Example : 
        #   task1
        #    +- task2 
        #    |   +- task3
        #    |   +- task4
        #    \- task3
        # 
        #   task1 = Task.new(:name => "Task 1")
        #   task2 = Task.new(:name => "Task 2")
        #   task3 = Task.new(:name => "Task 3")
        #   task4 = Task.new(:name => "Task 4")
        # 
        #   task1.children << [task2, task3]
        #   task2.children << task3
        #   task2.children << task
        # 
        #   task1.parents                 => []
        #   task3.parents                 => [task1, task2]
        #   task1.children                => [task2, task3]
        #   task1.children.recursive.to_a => [task2, task3, task4]
        # 
        # The +recursive+ object is added to the +parents+ and +children+ associations.  When coerced into an 
        # array, it gathers all of the child or parent records recursively (obviously) into a single array.  
        # When +each+ is called on the +recursive+ object, it yields against each record in turn.  This means 
        # that some operations will be faster when run with the +each+ implementation.
        # 
        # The following options are supported, but some have yet to be implemented:
        # 
        # +class_name+:: Set to the ActiveRecord class that represents nodes.
        # +edge_table+:: HABTM table that represents graph edges.  Defaults to +class_name_id+.
        # +parent_col+:: Column in +edge_table+ that references the parent node.  Defaults to +parent_id+.
        # +child_col+:: Column in +edge_table+ that references the child node.  Defaults to +child_id+.
        # +allow_cycles+:: Determines whether or not the graph is cyclic.  Defaults to +false+. <i>Cyclic graphs are not yet implemented</i>.
        # +directed+:: Determines whether or not the graph is directed.  Defaults to +true+. <i>Undirected graphs are not yet implemented</i>.
        # +child_collection+:: Name of the child collection.  Defaults to +children+.
        # +parent_collection+:: Name of the child collection.  Defaults to +parents+.
        def acts_as_graph(opts)
          #--
          # Note: self.name == "Task"
          extend  TammerSaleh::Acts::Graph::SingletonMethods
          include TammerSaleh::Acts::Graph::InstanceMethods
          
          # This is kinda messy, but I'm not sure of a better way.  It polutes the AR-model's
          # namespace w/ the options class variable.
          TammerSaleh::Acts::Graph::options = TammerSaleh::Acts::Graph::process_options(opts)

          # define HABTM relationships
          has_and_belongs_to_many TammerSaleh::Acts::Graph::options[:parent_collection],
            :class_name              => TammerSaleh::Acts::Graph::options[:class_name].to_s,
            :join_table              => TammerSaleh::Acts::Graph::options[:edge_table].to_s,
            :association_foreign_key => "parent_id",
            :foreign_key             => "child_id" do
            include TammerSaleh::Acts::Graph::Extensions::HABTM
          end
          
          has_and_belongs_to_many TammerSaleh::Acts::Graph::options[:child_collection],
            :class_name              => TammerSaleh::Acts::Graph::options[:class_name].to_s,
            :join_table              => TammerSaleh::Acts::Graph::options[:edge_table].to_s,
            :association_foreign_key => "child_id",
            :foreign_key             => "parent_id" do
            include TammerSaleh::Acts::Graph::Extensions::HABTM
          end
        end
        #++
      end

      mattr_accessor :options
      
      def self.process_options(opts)
        default_options = {
          :class_name        => self.name,
          :edge_table        => "#{self.name.to_s.underscore.pluralize}_edges",
          :parent_col        => "parent_id",
          :child_col         => "child_id",
          :allow_cycles      => false,
          :directed          => true,
          :child_collection  => :children,
          :parent_collection => :parents,
        }

        original_caller = caller[1..-1] # for exceptions
        
        opts.keys.each do |key|
          unless default_options.has_key? key
            raise ArgumentError, "#{key} is not a supported option.", original_caller
          end
        end
        opts = default_options.update(opts)

        unfilled = opts.select { |k,v| v == :REQUIRED }.map { |k,v| k }
        unless unfilled.empty?
          raise ArgumentError, 
                "The following required fields are not given: " + 
                "#{unfilled.join(', ')}", original_caller
        end
        
        # XXX Need to set default for :edge_table here...
        
        if opts[:allow_cycles] then
          raise(ArgumentError, "Cyclic graphs not yet supported", original_caller)
        end
        
        if not opts[:directed] then
          raise(ArgumentError, "Undirected graphs not yet supported", original_caller)
        end
        
        return opts
      end

      module SingletonMethods #:nodoc:
      end

      module InstanceMethods  #:nodoc:
      end

    end
  end
end

