class Person < ActiveRecord::Base
  acts_as_graph :class_name => "Person", 
                :parent_col => "befriender_id", 
                :child_col  => "friend_id"
                
  def <=> (other)
    self.name <=> other.name
  end
end
