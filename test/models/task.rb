class Task < ActiveRecord::Base
  acts_as_graph :class_name => "Task", 
                :edge_table => "dependencies"
                
  def <=> (other)
    self.name <=> other.name
  end
end
