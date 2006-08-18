require 'test/unit'
require File.join(File.dirname(__FILE__), 'ptk_helper')

class Task < ActiveRecord::Base
  acts_as_graph :class_name => "Task", :edge_table => "dependencies"
  def <=> (other)
    self.name <=> other.name
  end
end

class ActsAsGraphTest < Test::Unit::TestCase
  
  def setup
  end
  
  # Replace this with your real tests.
  def test_name_is_saved
    t1 = new_task(:shit)
    assert_equal "shit", t1.name
  end
  
  def test_task_can_have_children
    instantiate_tasks("parent", "child")
    @parent.children << @child
    assert_equal 1, @parent.children.count
    assert_equal "child", @parent.children.first.name
  end
  
  def test_children_recursive_to_a
    all_children = %w{child1 grandchild1 child2 grandchild2 grandchild3}
    instantiate_tasks("parent", *all_children)
    assert_nothing_raised do
      @parent.children << [@child1, @child2]
      assert_equal 2, @parent.children.count
      @child1.children << [@grandchild1, @grandchild3]
      assert_equal 2, @child1.children.count
      @child2.children << [@grandchild2, @grandchild3]
      assert_equal 2, @child2.children.count
    end
    assert_equal all_children.sort, @parent.children.recursive.to_a.sort.map(&:name)
  end
  
  private
  
  def new_task(name)
    t = Task.new(:name => name.to_s)
    assert_nothing_raised { t.save }
    t
  end
  
  def instantiate_tasks(*tasks)
    tasks.each do |t|
      instance_variable_set("@#{t.to_s}".to_sym, new_task(t))
    end
  end
end
