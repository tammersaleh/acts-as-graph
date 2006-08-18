ActiveRecord::Schema.define(:version => 2) do
  ActiveRecord::Base.logger.info "Creating dependencies table"
  create_table "dependencies", :id => false, :force => true do |t|
    t.column "parent_id", :integer, :default => 0, :null => false
    t.column "child_id", :integer, :default => 0, :null => false
  end

  ActiveRecord::Base.logger.info "Creating tasks table"
  create_table "tasks", :force => true do |t|
    t.column "name", :string
  end  
end