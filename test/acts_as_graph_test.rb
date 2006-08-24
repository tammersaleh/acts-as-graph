require 'test/unit'
require File.join(File.dirname(__FILE__), 'ptk_helper')

class ActsAsGraphTest < Test::Unit::TestCase

  def self.const_missing(const)
    # This idea is noted as being in "Very poor style" by Dave Thomas in Programming Ruby.
    # But, then, what does Dave Thomas know?

    filename = File.dirname(__FILE__) + "/models/#{const.to_s.tableize.singularize}"
    if File.file? filename + ".rb"
      # Load the file for the model that is being referenced.
      #puts "Loading #{const}"
      require filename
      return const_get(const)
    else
      super
    end
  end

  def setup
  end
  
  def test_task_graph_options
    task_options = { :parent_collection => :parents,
                     :parent_col        => "parent_id",
                     :edge_table        => "dependencies",
                     :child_col         => "child_id",
                     :allow_cycles      => false,
                     :directed          => true,
                     :child_collection  => :children }
    task_options.each do |k, v|
      assert_equal v, Task.acts_as_graph_options[k], "Task.acts_as_graph_options[#{k}]"
    end
  end

  def test_person_graph_options
    person_options = { :parent_collection => :people_who_like_me,
                       :parent_col        => "befriender_id",
                       :edge_table        => "people_edges",
                       :child_col         => "friend_id",
                       :allow_cycles      => false,
                       :directed          => true,
                       :child_collection  => :people_i_like  }
    person_options.each do |k, v|
      assert_equal v, Person.acts_as_graph_options[k], "Person.acts_as_graph_options[#{k}]"
    end
  end
  
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

  def test_task_children_recursive_each
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
  
  def test_task_parents_recursive_each
    all_parents = %w{mom dad grandma grandpa1 grandpa2 child}
    instantiate_nodes(Task, "me", *all_parents)
    assert_nothing_raised do
      @me.parents  << [@mom, @dad]
      @mom.parents << [@grandma, @grandpa1]
      @dad.parents << [@grandma, @grandpa2]
      @me.children << @child
    end
    temp = []
    @me.parents.recursive.each { |x| temp << x.name }
    assert_equal (all_parents - ["child"]).sort, temp.sort
  end
    
  def test_task_children_recursive_to_a
    all_children = %w{child1 grandchild1 child2 grandchild2 grandchild3}
    instantiate_nodes(Task, "parent", *all_children)
    assert_nothing_raised do
      @parent.children << [@child1, @child2]
      @child1.children << [@grandchild1, @grandchild3]
      @child2.children << [@grandchild2, @grandchild3]
    end
    assert_equal all_children.sort, @parent.children.recursive.to_a.sort.map(&:name)
  end
  
  def test_task_children_recursive_enumerable
    family = %w{parent child grandchild}
    assert_nothing_raised do
      instantiate_nodes(Task, *family)
      @parent.children << @child
      @child.children << @grandchild
    end
    assert_equal (family - ["parent"]).sort, @parent.children.recursive.map(&:name).sort
  end
  
  def test_task_children_recursive_method_missing
    family = %w{parent child grandchild}
    assert_nothing_raised do
      instantiate_nodes(Task, *family)
      @parent.children << @child
      @child.children  << @grandchild
    end
    # Test []
    assert_equal (family - ["parent"]).sort[1], 
                 @parent.children.recursive.sort[1].name
    # Test -
    assert_equal (family - ["parent", "grandchild"]).sort,
                 (@parent.children.recursive - [@grandchild]).sort.map(&:name)
    
  end
  
  def test_graph_with_named_collections
    assert_nothing_raised do
      instantiate_nodes(Person, "tammer", "andy", "todd")
      @tammer.people_i_like << @andy
      @tammer.people_who_like_me << @todd
    end
    assert_equal ["andy"], @tammer.people_i_like.recursive.map(&:name)
    assert_equal ["todd"], @tammer.people_who_like_me.recursive.map(&:name)
  end
  
  def test_people_friends_recursive_each
    all_friends = %w{brian chad dick ronald}
    instantiate_nodes(Person, "me", *all_friends)
    assert_nothing_raised do
      @me.people_i_like << [@brian, @chad]
      @brian.people_i_like << [@dick, @ronald]
      @chad.people_i_like << [@dick, @ronald]
    end
    temp = []
    @me.people_i_like.recursive.each { |x| temp << x.name }
    assert_equal all_friends.sort, temp.sort
  end
  
private
  
  def create_node(klass, name)
    n = klass.new(:name => name.to_s)
    assert_nothing_raised { n.save }
    assert_equal klass, n.class
    assert n
    n
  end
  
  def instantiate_nodes(klass, *nodes)
    nodes.each do |n|
      instance_variable_set("@#{n.to_s}".to_sym, create_node(klass, n))
    end
  end
end
