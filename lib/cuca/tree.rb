#
# This is a generic tree data structure, it will allow Urlmap2 to build a directory trees,
# perform searches and merge trees etc.. See demo code below.
# It can search by wildcard and can overwrite/replace branches with a separate function (@@update_compare @@find_compare)
#

module Cuca
    class Tree
        attr :root
        class Node
            attr :parent
            attr_writer :parent
            attr :children
            attr_accessor :name
            attr_accessor :value

            # compare a node to override it
            @@update_compare = lambda do |a,b| 
                b.name == a.name
            end

            # compare a node to find out
            @@find_compare = lambda do |a,b| 
                b.name == a.name
            end

            # make sure that __name-type directorys are treated last
            @@file_sorter = lambda do |a,b|
                next 1 if a.name[0] == '_' && b.name[0] != '_'
                next -1 if a.name[0] != '_' && b.name[0] == '_'
                next 0
            end

            def children_sorted
                @children.sort(&@@file_sorter)
            end

            def to_node(x)
                return x if x.instance_of?(Tree::Node)
                Tree::Node.new(x)
            end

            def self.update_compare=(m)
                @@update_compare = m
            end

            def self.find_compare=(m)
                @@find_compare = m
            end


            def initialize(name, value:nil, parent:nil)
                @name = name
                @value = value
                @parent = parent
                @children = []
            end
            def <<(node)
                if node.instance_of?(String)
                    node = Node.new(node)
                end
                node.parent = self
                @children << node
                @children = children_sorted
            end        
            def level
                x = 0
                n = self.parent
                while n 
                    x+=1
                    n = n.parent
                end
                x
            end
            def to_s
                out = []
                out << (('  ' * level) + self.name + " " + self.value.to_s)
                @children.each do |c|
                    out << c.to_s
                end                
                out.join("\n")
            end

            # print one node with parents in gerenic way
            def format(join: ' | ', format: '%n', with_value:false)
                path = []
                x = self
                begin
                    f = format
                    f = f.gsub('%n', x.name)
                    path << f
                    x = x.parent
                end while x
                r = path.reverse.join(join)
                r += " [#{self.value.inspect}]" if with_value
                r
            end

            def inspect
                format(join: ' -> ', with_value: true)
            end
            
            def find_match?(other)
                @@find_compare.call(self,other)
            end
            def update_match?(other)
                @@update_compare.call(self,other)
            end

            def find_child_to_update(name_or_node)
                n = to_node(name_or_node)
                @children.find { |child| child.update_match?(n) }
            end

            def find_child(name_or_node)
                n = to_node(name_or_node)
                @children.find { |child| child.find_match?(n) }
            end


            def find_path_with_method(path, method)
                node = self
                path.each do |p|
                    new_node = method == :update ? node.find_child_to_update(p) : node.find_child(p)
                    if !new_node 
                        return nil
                    end
                    node = new_node
                end
                node
            end

            # %w{ customer ita circuit casa update } then finds
            # node customer __hid circuit __hid update
            def find_path(path)
                find_path_with_method(path, :find)
            end

            def scan_path(path)
                assigns = {}
                node = self
                path.each do |p|
                    new_node = node.children.find do |child| 
                        res = @@find_compare.call(child,to_node(p))
                        assigns = assigns.merge(res) if res.instance_of?(Hash) 
                        res                       
                    end
                    if !new_node 
                        return nil
                    end
                    node = new_node
                end
                { :node => node, :assigns => assigns }
            end

            # %w{ customer __hid circuit __site update } finds
            # customer __name circuit __sitename update }
            def find_path_to_update(path)
                find_path_with_method(path, :update)
            end

            # add a 1-dimensional list of nodes
            def add_nodes_r(nodes)
                cnode = self
                nodes.each do |n|
                    n = Node.new(n) if n.instance_of?(String)
                    x = cnode.find_child_to_update(n) 
                    if x then
                        x.name = n.name
#                        x.value = n.value
                        cnode = x                    
                    else
                        cnode << n
                        cnode = n
                    end
                end
                cnode
            end
        end

        def initialize(root_node = nil)
            @root = root_node || Node.new('root')
        end

        def to_s
            @root.to_s
        end
        def <<(node)
            self.root<<node
        end
    end
end


if __FILE__ == $0  then

    include Cuca

    Tree::Node.update_compare = lambda do |a,b|
        b_name = b.instance_of?(String) ? b : b.name
        return true if b_name[0..1] == '__' && a.name[0..1] == '__'
        b.instance_of?(String) ? a.name == b : b.name == a.name
    end

    Tree::Node.find_compare = lambda do |a,b|
        b_name = b.instance_of?(String) ? b : b.name
        if a.name[0..1] == '__' then 
           return { a.name[2..-1] => b }    
        end
        if b_name =~ /^\-(.*)\-(.*)$/ then 
            action = $2
            return (a.name == action)
        end
        b.instance_of?(String) ? a.name == b : b.name == a.name
    end
    
    
    t = Tree.new 
    t.root << Tree::Node.new("customer", value:"Some data")
    t.root << Tree::Node.new("users", value:"Some data")
    
    t.root.find_path(['users']) << Tree::Node.new('add', value: "Add a user")
    puts "User add is at level: " + t.root.find_path(['users', 'add']).level.to_s
    # puts t.to_s
    
    t.root.add_nodes_r(%w{ my funny path test})
    t.root.add_nodes_r(%w{ my funny path test})
    
    t.root.add_nodes_r(%w{ customer __blah edit })
    
    
    t.root.add_nodes_r(%w{ customer __hid edit })
    t.root.add_nodes_r(%w{ customer __hid edit })
    
    t.root.add_nodes_r(%w{ customer __hid circuits __site graph })
    
    t.root.add_nodes_r(%w{ my funny second test})
    
    
    puts t.to_s
  
    puts '-------------------------------'
    
    puts "Scan Path: customer/ita/edit: " + t.root.scan_path(%w{customer ita edit}).inspect
    puts "Scan Path: customer/ita/circuits/office/graph: " + t.root.scan_path(%w{customer ita circuits office graph}).inspect
    puts "Scan Path: customer/ita/circuits/office/-get-graph: " + t.root.scan_path(%w{customer ita circuits office -get-graph}).inspect

    puts '-------------------------------'   
    
    puts "Finding my->funny: " + t.root.find_path([Tree::Node.new('my'), 'funny']).inspect
end
