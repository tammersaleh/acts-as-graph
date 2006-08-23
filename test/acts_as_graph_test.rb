require 'test/unit'
require File.join(File.dirname(__FILE__), 'ptk_helper')

class ActsAsGraphTest < Test::Unit::TestCase

  def self.const_missing(const)
    # This idea is noted as being in "Very poor style" by Dave Thomas in Programming Ruby.
    # But, then, what does Dave Thomas know?

    # Load the model that is being referenced.
    if require(File.dirname(__FILE__) + "/models/#{const.to_s.tableize.singularize}")
      return const_get(const)
    else
      super
    end
  end

  def setup
  end
  
  # Replace this with your real tests.
  def test_name_is_saved
    t1 = new_task(:test)
    assert_equal "test", t1.name
  end
  
  def test_task_can_have_children
    instantiate_tasks("parent", "child")
    @parent.children << @child
    assert_equal 1, @parent.children.count
    assert_equal "child", @parent.children.first.name
  end

  def test_children_recursive_each
    all_children = %w{child1 grandchild1 child2 grandchild2 grandchild3}
    instantiate_tasks("parent", *all_children)
    assert_nothing_raised do
      @parent.children << [@child1, @child2]
      @child1.children << [@grandchild1, @grandchild3]
      @child2.children << [@grandchild2, @grandchild3]
    end
    temp = []
    @parent.children.recursive.each { |x| temp << x.name }
    assert_equal all_children.sort, temp.sort
  end
    
  def test_children_recursive_to_a
    all_children = %w{child1 grandchild1 child2 grandchild2 grandchild3}
    instantiate_tasks("parent", *all_children)
    assert_nothing_raised do
      @parent.children << [@child1, @child2]
      @child1.children << [@grandchild1, @grandchild3]
      @child2.children << [@grandchild2, @grandchild3]
    end
    assert_equal all_children.sort, @parent.children.recursive.to_a.sort.map(&:name)
  end
  
  def test_children_recursive_method_missing
    family = %w{parent child grandchild}
    assert_nothing_raised do
      instantiate_tasks(*family)
      @parent.children << @child
      @child.children << @grandchild
    end
    assert_equal (family - ["parent"]).sort, @parent.children.recursive.map(&:name).sort
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
