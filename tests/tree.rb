require 'test/unit'

$: << File.expand_path(File.dirname(__FILE__) + '/../lib')


require 'cuca/tree'

# configure the default finder methods as in urlmap2:

Cuca::Tree::Node.update_compare = lambda do |a,b|
    return true if b.name[0..1] == '__' && a.name[0..1] == '__'
    b.name == a.name
end

Cuca::Tree::Node.find_compare = lambda do |a,b|
    if a.name[0..1] == '__' && b.value[:type] == :directory then 
        return { a.name[2..-1] => b.name }    
    end
    if b.name =~ /^\-(.*)\-(.*)$/ then 
        action = $1
        return (a.name == action)
    end
    b.name == a.name
end

class TreeTest < Test::Unit::TestCase


    def _mk_node_array(names)
        names.map { |n| Cuca::Tree::Node.new(n, value: { :type => :directory } ) }
    end

    def _mk_test_tree
        r = Cuca::Tree::Node.new('root')
        r.add_nodes_r(_mk_node_array(%w{ one two three }))
        r.add_nodes_r([Cuca::Tree::Node.new('test', value: { :type => :file})])
        two = r.children[0].children[0]
        two.add_nodes_r([Cuca::Tree::Node.new('index', value: { :type => :file})])
        two.add_nodes_r(_mk_node_array(%w{ x y z }) + [Cuca::Tree::Node.new('index', value: { :type => :file})])
        r.add_nodes_r(_mk_node_array(%w{ customer __hid circuit __site }) + [Cuca::Tree::Node.new('index', value: { :type => :file})] )
        r.root

        # root 
        #   one {:type=>:directory}
        #     two {:type=>:directory}
        #       three {:type=>:directory}
        #       index {:type=>:file}
        #       x {:type=>:directory}
        #         y {:type=>:directory}
        #           z {:type=>:directory}
        #             index {:type=>:file}
        #   test {:type=>:file}
        #   customer {:type=>:directory}
        #     __hid {:type=>:directory}
        #       circuit {:type=>:directory}
        #         __site {:type=>:directory}
        #           index {:type=>:file}

    end

    def test_children_simple
        r = Cuca::Tree::Node.new('root')
        a = Cuca::Tree::Node.new('a', value: 1)
        b = Cuca::Tree::Node.new('b', value: 2)

        r << a
        r << b

        assert_equal r.children[0].name, 'a'
        assert_equal r.children[1].name, 'b'
    end

    def test_children_simple2
        r = Cuca::Tree::Node.new('root')

        node_array = _mk_node_array(%w{ one two three })

        r.add_nodes_r(node_array)

        assert r.children[0].name = 'one'
        assert r.children[0].children[0].name == 'two'
        assert r.children[0].children[0].children[0].name == 'three'

        # let's add some nodes to second level
        two = r.children[0].children[0]
        two.add_nodes_r(_mk_node_array(%w{ x y z }))
        #  one (Node of one)
        #  two (Node of two)
        #    three (Node of three)
        #    x (Node of x)
        #      y (Node of y)
        #        z (Node of z)
        
        assert r.children[0].children[0].children[1].name == 'x'
        assert r.children[0].children[0].children[1].children[0].name == 'y'
        assert r.children[0].children[0].children[1].children[0].children[0].name == 'z'
    end

    def test_find_compare
        # wildcard match
        tn = Cuca::Tree::Node.new('__test', value: { :type => :directory})
        other = Cuca::Tree::Node.new('something', value: { :type => :directory})
        assert tn.find_match?(other)

        # no match
        tn = Cuca::Tree::Node.new('test', value: { :type => :directory})
        other = Cuca::Tree::Node.new('something', value: { :type => :directory})
        assert !tn.find_match?(other)

        # direct match
        tn = Cuca::Tree::Node.new('same', value: { :type => :directory})
        other = Cuca::Tree::Node.new('same', value: { :type => :directory})
        assert tn.find_match?(other)

        # subcall
        tn = Cuca::Tree::Node.new('theaction', value: { :type => :directory})
        other = Cuca::Tree::Node.new('-theaction-blah', value: { :type => :directory})
        assert tn.find_match?(other)

    end

    def test_update_compare
        # wildcard
        tn = Cuca::Tree::Node.new('__test', value: { :type => :directory})
        other = Cuca::Tree::Node.new('something', value: { :type => :directory})
        assert !tn.update_match?(other)

        # wildcard II 
        tn = Cuca::Tree::Node.new('__test', value: { :type => :directory})
        other = Cuca::Tree::Node.new('__something', value: { :type => :directory})
        assert tn.update_match?(other)

        # file 
        tn = Cuca::Tree::Node.new('one', value: { :type => :file})
        other = Cuca::Tree::Node.new('other', value: { :type => :file})
        assert !tn.update_match?(other)
        # file 
        tn = Cuca::Tree::Node.new('one', value: { :type => :file})
        other = Cuca::Tree::Node.new('one', value: { :type => :file})
        assert tn.update_match?(other)
    end



    def test_find_child_method
        tree = _mk_test_tree

        assert_equal 'test', tree.find_child('test').name
        assert_nil tree.find_child('two')           # only finds one level
    end

    def test_find_path
        tree = _mk_test_tree
        assert '__hid', tree.root.find_path(_mk_node_array(%w{ customer ita })).name
        assert 'circuit', tree.root.find_path(_mk_node_array(%w{ customer ita circuit })).name
        assert '__site', tree.root.find_path(_mk_node_array(%w{ customer ita circuit martin })).name
        assert 'index', tree.root.find_path(_mk_node_array(%w{ customer ita circuit martin index })).name
    end
    def test_scan_path
        tree = _mk_test_tree
        x = tree.root.scan_path(_mk_node_array(%w{ customer ita circuit martin index }))
        assert_equal 'ita', x[:assigns]['hid']
        assert_equal 'martin', x[:assigns]['site']
        assert_equal 'index', x[:node].name
    end

    def test_find_path_to_update
        tree = _mk_test_tree
        
        assert_equal '__site', tree.root.find_path_to_update(_mk_node_array(%w{ customer __site circuit __stuff })).name
        assert_nil tree.root.find_path_to_update(_mk_node_array(%w{ customer __site circuit stuff }))
    end



    # node_tree = %w{ customer __hid }.map do |n|
    #   Tree::Node.new(n, value: "(Some value for #{n})")
    # end
    # node_tree2 = %w{ customer __hid stuff }.map do |n|
    #   Tree::Node.new(n, value: "(Some value for #{n})")
    # end
      
    
    # t = Tree.new 
    # t.root << Tree::Node.new("customer", value:"Some data")
    # t.root << Tree::Node.new("users", value:"Some data")

    # t.root.add_nodes_r(%w{ customer __hid edit something })
    # t.root.add_nodes_r(node_tree)
    # t.root.add_nodes_r(node_tree2)

    # puts t.to_s
    # exit
    # t.root.add_nodes_r(%w{ })


    # t.root.find_path(['users']) << Tree::Node.new('add', value: "Add a user")
    # puts "User add is at level: " + t.root.find_path(['users', 'add']).level.to_s
    # # puts t.to_s
    
    # t.root.add_nodes_r(%w{ my funny path test})
    # t.root.add_nodes_r(%w{ my funny path test})
    
    # t.root.add_nodes_r(%w{ customer __blah edit })
    
    
    # t.root.add_nodes_r(%w{ customer __hid edit })
    # t.root.add_nodes_r(%w{ customer __hid edit })
    
    # t.root.add_nodes_r(%w{ customer __hid circuits __site graph })
    
    # t.root.add_nodes_r(%w{ my funny second test})
    
    
    # puts t.to_s
  
    # puts '-------------------------------'
    
    # puts "Scan Path: customer/ita/edit: " + t.root.scan_path(%w{customer ita edit}).inspect
    # puts "Scan Path: customer/ita/circuits/office/graph: " + t.root.scan_path(%w{customer ita circuits office graph}).inspect
    # puts "Scan Path: customer/ita/circuits/office/-get-graph: " + t.root.scan_path(%w{customer ita circuits office -get-graph}).inspect

    # puts '-------------------------------'   
    
    # puts "Finding my->funny: " + t.root.find_path([Tree::Node.new('my'), 'funny']).inspect
end
