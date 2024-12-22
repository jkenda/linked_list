package linked_list

Node :: struct($T: typeid) {
    data: T,
    next: ^Node(T)
}

List :: struct($T: typeid) {
    front: ^Node(T),
    back: ^Node(T),
    size: int,
}

// insert data into list at position n
insert :: proc(list: ^List($T), n: int, data: T) -> (ok: bool = false) {
    data := data
    context.user_ptr = &data
    n := list.size + 1 + n if n < 0 else n

    make_node :: proc(data: $T, next: ^Node(T) = nil) -> (new_node: ^Node(T)) {
        new_node = new(Node(T))
        new_node.data = data
        new_node.next = next
        return
    }

    node_insert :: proc(node: $N/^Node($T), n: int) -> N {
        if n == 0 {
            data_ptr := cast(^T)context.user_ptr
            data := data_ptr^
            return make_node(data, node)
        }

        return node_insert(node.next, n - 1)
    }

    switch n {
    case 0, 0..<list.size:
        list.front = node_insert(list.front, n)
    case list.size:
        list.back.next = make_node(data, nil)
        list.back = list.back.next
    }

    list.front = list.back  if list.front == nil else list.front
    list.back  = list.front if list.back  == nil else list.back

    list.size += 1
    return true
}


// access the nth element in the list
get_nth :: proc(list: $L/List($T), n: int) -> Maybe(T) {
    n := list.size + 1 + n if n < 0 else n

    node_get_nth :: proc(node: $N/^Node($T), n: int) -> Maybe(T) {
        if node == nil {
            return nil
        }

        if n == 0 {
            return node.data
        }

        return node_get_nth(node.next, n - 1)
    }

    if list.front == nil {
        return nil
    }

    switch n {
    case 0..<list.size-1:
        return node_get_nth(list.front, n)
    case list.size-1:
        return list.back.data
    case:
        return nil
    }
}


import "core:testing"

@(test)
test_empty :: proc(t: ^testing.T) {
    empty_list: List(int)

    testing.expect_value(t, empty_list.front, nil)
    testing.expect_value(t, empty_list.back, nil)
    testing.expect_value(t, empty_list.size, 0)

    testing.expect_value(t, get_nth(empty_list, 0), nil)
    testing.expect_value(t, get_nth(empty_list, 1), nil)
}

@(test)
test_push_front :: proc(t: ^testing.T) {
    list: List(int)
    insert(&list, 0, 1)

    assert(list.front != nil)
    assert(list.back != nil)

    testing.expect_value(t, list.front.data, 1)
    testing.expect_value(t, list.back.data, 1)
    testing.expect_value(t, get_nth(list, 0), 1)

    insert(&list, 0, 2)
    testing.expect_value(t, list.front.data, 2)
    testing.expect_value(t, list.back.data, 1)
    testing.expect_value(t, get_nth(list, 0), 2)
    testing.expect_value(t, get_nth(list, 1), 1)
}

@(test)
test_push_back :: proc(t: ^testing.T) {
    list: List(int)
    insert(&list, -1, 1)

    assert(list.front != nil)
    assert(list.back != nil)

    testing.expect_value(t, list.front.data, 1)
    testing.expect_value(t, list.back.data, 1)
    testing.expect_value(t, get_nth(list, 0), 1)

    insert(&list, -1, 2)
    testing.expect_value(t, list.front.data, 1)
    testing.expect_value(t, list.back.data, 2)
    testing.expect_value(t, get_nth(list, 0), 1)
    testing.expect_value(t, get_nth(list, 1), 2)
}
