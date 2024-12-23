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

Error :: enum {
    Index_Out_Of_Bounds,
}


make_from_slice_with_type :: proc($T: typeid, slice: $S/[]T) -> (list: List(T)) {
    for el in slice {
        append(&list, el)
    }
    return
}

make_from_slice :: proc(slice: $S/[]$T) -> List(T) {
    return make_from_slice_with_type(T, slice)
}

make :: proc{
    make_from_slice_with_type,
    make_from_slice,
}


/*
   Remove all items from the list.
   O(n).
 */
delete :: proc(list: $L/^List($T), allocator := context.allocator) {
    for list.len > 0 {
        pop_front(list, allocator)
    }
}


/*
   Make a node with data and next.
 */
make_node :: proc(data: $T, next: ^Node(T) = nil, allocator := context.allocator) -> (new_node: ^Node(T)) {
    new_node = new(Node(T), allocator)
    new_node.data = data
    new_node.next = next
    return
}


/*
   Insert data into list at position n from the front.
   O(1) in the front and back, O(n) elsewhere.
*/
insert :: proc(list: ^List($T), data: T, n: uint = 0, allocator := context.allocator) -> (err: Error) {
    data := data
    context.user_ptr = &data

    node_insert :: proc(node: $N/^Node($T), n: uint, allocator := context.allocator) -> N {
        if n == 0 {
            data_ptr := cast(^T)context.user_ptr
            data := data_ptr^
            return make_node(data, node, allocator)
        }

        node.next = node_insert(node.next, n - 1, allocator)
        return node
    }

    switch n {
    case 0, 0..<list.len:
        list.front = node_insert(list.front, n, allocator)
    case list.len:
        list.back.next = make_node(data, nil, allocator)
        list.back = list.back.next
    case:
        return .Index_Out_Of_Bounds
    }

    list.front = list.back  if list.front == nil else list.front
    list.back  = list.front if list.back  == nil else list.back

    if err == nil { list.len += 1 }
    return
}

/*
   Insert an element to the front of the list.
   O(1).
*/
prepend :: proc(list: ^List($T), data: T, allocator := context.allocator) -> (err: Error) {
    return insert(list, data, 0, allocator)
}

/*
   Insert an element to the back of the list.
   O(1).
*/
append :: proc(list: ^List($T), data: T, allocator := context.allocator) -> (err: Error) {
    return insert(list, data, list.len, allocator)
}


/*
   Remove the nth element from the list.
   O(1) at the front, O(n) elsewhere.
 */
remove :: proc(list: $L/^List($T), n: uint, allocator := context.allocator) -> (data: T, err: Error) {
    if list.len == 0 {
        err = .Index_Out_Of_Bounds
        return
    }

    remove_node :: proc(node: $N/^Node($T), n: uint, allocator := context.allocator) -> (prev_node: N, next_data: T) {
        if n == 1 {
            next := node.next

            prev_node = node
            next_data = next.data

            node.next = node.next.next
            free(next, allocator)
            return
        }

        return remove_node(node.next, n - 1, allocator)
    }

    switch n {
    case 0:
        data = list.front.data
        next := list.front.next
        free(list.front, allocator)
        list.front = next
    case 1..<list.len-1:
        _, next_data := remove_node(list.front, n, allocator)
        data = next_data
    case list.len-1:
        data = list.back.data
        node, _ := remove_node(list.front, n, allocator)
        list.back = node
    case:
        err = .Index_Out_Of_Bounds
    }

    list.front = nil if list.back  == nil else list.front
    list.back  = nil if list.front == nil else list.back

    if err == nil { list.len -= 1 }
    return
}

/*
   Remove the first element from the list.
   O(1).
 */
pop_front :: proc(list: $L/^List($T), allocator := context.allocator) -> (data: T, err: Error) {
    return remove(list, 0, allocator)
}

/*
   Remove the last element from the list.
   O(n).
 */
pop_back :: proc(list: $L/^List($T), allocator := context.allocator) -> (data: T, err: Error) {
    return remove(list, list.len - 1, allocator)
}


/*
   Access the nth element in the list.
   O(1) at the front and back, O(n) elsewhere.
*/
get_nth :: proc(list: $L/List($T), n: uint) -> (data: T, err: Error) {
    if list.len == 0 {
        err = .Index_Out_Of_Bounds
        return
    }

    get_nth_node :: proc(node: $N/^Node($T), n: uint) -> N {
        if n == 0 {
            return node
        }

        return get_nth_node(node.next, n - 1)
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

/*
   Access the first element in the list.
   O(1).
 */
get_front :: proc(list: $L/List($T)) -> (data: T, err: Error) {
    return get_nth(list, 0)
}

/*
   Access the last element in the list.
   O(1).
 */
get_back :: proc(list: $L/List($T)) -> (data: T, err: Error) {
    return get_nth(list, list.len - 1)
}


import "core:testing"

@(test)
test_make_from_slice :: proc(t: ^testing.T) {
    {
        list := make_from_slice([]int{})
        testing.expect_value(t, to_string(list), "[]")
    }
    {
        list := make_from_slice([]int{ 1, 2, 3 })
        testing.expect_value(t, to_string(list), "[1, 2, 3]")
    }
}

@(test)
test_empty :: proc(t: ^testing.T) {
    empty_list: List(int)
    defer delete(&empty_list)

    testing.expect_value(t, empty_list.front, nil)
    testing.expect_value(t, empty_list.back, nil)
    testing.expect_value(t, empty_list.len, 0)

    {
        _, err := get_nth(empty_list, 0)
        assert(err == .Index_Out_Of_Bounds)
    }
    {
        _, err := get_nth(empty_list, 1)
        assert(err == .Index_Out_Of_Bounds)
    }
}

@(test)
test_push_front :: proc(t: ^testing.T) {
    list: List(int)

    prepend(&list, 1)

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

    prepend(&list, 2)
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

    delete(&list)
    testing.expect_value(t, list.front, nil)
    testing.expect_value(t, list.back, nil)
    testing.expect_value(t, list.len, 0)
}

@(test)
test_push_back :: proc(t: ^testing.T) {
    list: List(int)
    defer delete(&list)

    // push 1
    append(&list, 1)

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
    append(&list, 2)

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
    defer delete(&list)

    prepend(&list, 1)
    append(&list, 3)
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

@(test)
test_remove :: proc(t: ^testing.T) {
    list := make([]int{ 1, 2, 3, 4, 5, 6, 7, 8, 9, 0 })
    testing.expect_value(t, to_string(list), "[1, 2, 3, 4, 5, 6, 7, 8, 9, 0]")

    {
        data, err := pop_back(&list)
        assert(err == nil)
        testing.expect_value(t, data, 0)
        testing.expect_value(t, to_string(list), "[1, 2, 3, 4, 5, 6, 7, 8, 9]")
    }

    {
        data, err := pop_front(&list)
        assert(err == nil)
        testing.expect_value(t, data, 1)
        testing.expect_value(t, to_string(list), "[2, 3, 4, 5, 6, 7, 8, 9]")
    }

    {
        data, err := remove(&list, 5)
        assert(err == nil)
        testing.expect_value(t, data, 7)
        testing.expect_value(t, to_string(list), "[2, 3, 4, 5, 6, 8, 9]")
    }

    {
        data, err := remove(&list, 3)
        assert(err == nil)
        testing.expect_value(t, data, 5)
        testing.expect_value(t, to_string(list), "[2, 3, 4, 6, 8, 9]")
    }

    {
        data, err := get_front(list)
        assert(err == nil)
        testing.expect_value(t, data, 2)
    }
    {
        data, err := get_back(list)
        assert(err == nil)
        testing.expect_value(t, data, 9)
    }

    pop_front(&list)
    pop_front(&list)
    pop_front(&list)
    pop_front(&list)
    pop_front(&list)
    testing.expect_value(t, list.front, list.back)

    pop_front(&list)
    testing.expect_value(t, list.front, nil)
    testing.expect_value(t, list.back, nil)
    testing.expect_value(t, list.len, 0)
}
