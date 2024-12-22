package linked_list

Node :: struct($T: typeid) {
    data: T,
    next: ^Node(T)
}

List :: struct($T: typeid) {
    front: ^Node(T),
    back: ^Node(T),
    len: uint,
}

List_Error :: enum {
    Index_Out_Of_Bounds,
}


/*
   Insert data into list at position n from the front.
*/
insert :: proc(list: ^List($T), data: T, n: uint = 0) -> (err: List_Error) {
    data := data
    context.user_ptr = &data

    make_node :: proc(data: $T, next: ^Node(T) = nil) -> (new_node: ^Node(T)) {
        new_node = new(Node(T))
        new_node.data = data
        new_node.next = next
        return
    }

    node_insert :: proc(node: $N/^Node($T), n: uint) -> N {
        if n == 0 {
            data_ptr := cast(^T)context.user_ptr
            data := data_ptr^
            return make_node(data, node)
        }

        node.next = node_insert(node.next, n - 1)
        return node
    }

    switch n {
    case 0, 0..<list.len:
        list.front = node_insert(list.front, n)
    case list.len:
        list.back.next = make_node(data, nil)
        list.back = list.back.next
    case:
        return .Index_Out_Of_Bounds
    }

    list.front = list.back  if list.front == nil else list.front
    list.back  = list.front if list.back  == nil else list.back

    list.len += 1
    return
}

/*
   Insert an element to the front of the list.
*/
push_front :: proc(list: ^List($T), data: T) -> (err: List_Error) {
    return insert(list, data, 0)
}

/*
   Insert an element to the back of the list.
*/
push_back :: proc(list: ^List($T), data: T) -> (err: List_Error) {
    return insert(list, data, list.len)
}


/*
   Access the nth element in the list.
*/
get_nth :: proc(list: $L/List($T), n: uint) -> (data: T, err: List_Error) {
    if list.front == nil {
        err = .Index_Out_Of_Bounds
        return
    }

    switch n {
    case 0..<list.len-1:
        node := get_nth_node(list.front, n)
        data = node.data
    case list.len-1:
        data = list.back.data
    case:
        err = .Index_Out_Of_Bounds
    }

    return
}


@(private)
get_nth_node :: proc(node: $N/^Node($T), n: uint) -> N {
    if n == 0 {
        return node
    }

    return get_nth_node(node.next, n - 1)
}


import "core:testing"

@(test)
test_empty :: proc(t: ^testing.T) {
    empty_list: List(int)

    testing.expect_value(t, empty_list.front, nil)
    testing.expect_value(t, empty_list.back, nil)
    testing.expect_value(t, empty_list.len, 0)

    {
        data, err := get_nth(empty_list, 0)
        assert(err == .Index_Out_Of_Bounds)
    }
    {
        data, err := get_nth(empty_list, 1)
        assert(err == .Index_Out_Of_Bounds)
    }
}

@(test)
test_push_front :: proc(t: ^testing.T) {
    list: List(int)
    push_front(&list, 1)

    assert(list.front != nil)
    assert(list.back != nil)
    assert(list.len == 1)

    testing.expect_value(t, list.front.data, 1)
    testing.expect_value(t, list.back.data, 1)
    {
        data, err := get_nth(list, 0)
        assert(err == nil)
        testing.expect_value(t, data, 1)
    }

    push_front(&list, 2)
    testing.expect_value(t, list.front.data, 2)
    testing.expect_value(t, list.back.data, 1)
    {
        data, err := get_nth(list, 0)
        assert(err == nil)
        testing.expect_value(t, data, 2)
    }
    {
        data, err := get_nth(list, 1)
        assert(err == nil)
        testing.expect_value(t, data, 1)
    }
}

@(test)
test_push_back :: proc(t: ^testing.T) {
    list: List(int)

    // push 1
    push_back(&list, 1)

    assert(list.front != nil)
    assert(list.back != nil)

    testing.expect_value(t, list.front.data, 1)
    testing.expect_value(t, list.back.data, 1)

    {
        data, err := get_nth(list, 0)
        assert(err == nil)
        testing.expect_value(t, data, 1)
    }

    // push 2
    push_back(&list, 2)

    testing.expect_value(t, list.front.data, 1)
    testing.expect_value(t, list.back.data, 2)

    {
        data, err := get_nth(list, 0)
        assert(err == nil)
        testing.expect_value(t, data, 1)
    }
    {
        data, err := get_nth(list, 1)
        assert(err == nil)
        testing.expect_value(t, data, 2)
    }
}

@(test)
test_insert :: proc(t: ^testing.T) {
    list: List(int)
    push_front(&list, 1)
    push_back(&list, 3)
    insert(&list, 2, 1)

    assert(list.front != nil)
    assert(list.back != nil)

    testing.expect_value(t, list.front.data, 1)
    testing.expect_value(t, list.back.data, 3)

    {
        data, err := get_nth(list, 0)
        assert(err == nil)
        testing.expect_value(t, data, 1)
    }
    {
        data, err := get_nth(list, 1)
        assert(err == nil)
        testing.expect_value(t, data, 2)
    }
    {
        data, err := get_nth(list, 2)
        assert(err == nil)
        testing.expect_value(t, data, 3)
    }
}
