require 'test/unit'
require File.join(File.dirname(__FILE__), 'ptk_helper')

class ActsAsGraphTest < Test::Unit::TestCase

  def self.const_missing(const)
    # This idea is noted as being in "Very poor style" by Dave Thomas in Programming Ruby.
    # But, then, what does Dave Thomas know?

    filename = File.dirname(__FILE__) + "/models/#{const.to_s.tableize.singularize}"
    if File.file? filename + ".rb"
      # Load the file for the model that is being referenced.
      require filename
      return const_get(const)
    else
      super
    end
  end

  def setup
  end
  
  # Replace this with your real tests.
  def test_name_is_saved
    t1 = create_node(Task, :test)
    assert_equal "test", t1.name
  end
  
  def test_task_can_have_children
    instantiate_nodes(Task, "parent", "child")
    @parent.children << @child
    assert_equal 1, @parent.children.count
    assert_equal "child", @parent.children.first.name
  end

  def test_children_recursive_each
    all_children = %w{child1 grandchild1 child2 grandchild2 grandchild3}
    instantiate_nodes(Task, "parent", *all_children)
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
    instantiate_nodes(Task, "parent", *all_children)
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
      instantiate_nodes(Task, *family)
      @parent.children << @child
      @child.children << @grandchild
    end
    assert_equal (family - ["parent"]).sort, @parent.children.recursive.map(&:name).sort
  end
  
  def test_graph_with_named_collections
    assert_nothing_raised do
      instantiate_nodes(Person, "Tammer", "Andy", "Todd")
      @Tammer.people_i_like << @Andy
      @Tammer.people_who_like_me << @Todd
    end
    assert_equal ["Andy"], @Tammer.people_i_like.recursive.map(&:name)
    assert_equal ["Todd"], @Tammer.people_who_like_me.recursive.map(&:name)
  end
  
  private
  
  def create_node(klass, name)
    n = klass.new(:name => name.to_s)
    assert_nothing_raised { n.save }
    n
  end
  
  def instantiate_nodes(klass, *nodes)
    nodes.each do |n|
      instance_variable_set("@#{n.to_s}".to_sym, create_node(klass, n))
    end
  end
end
