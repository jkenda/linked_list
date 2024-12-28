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
make_node :: proc(data: $T, next: ^Node(T), allocator := context.allocator) -> (new_node: ^Node(T)) {
    new_node = new(Node(T), allocator)
    new_node.data = data
    new_node.next = next
    return
}


@(private)
node_reverse :: proc(node: $N/^Node($T)) -> N {
    aux :: proc(node: $N/^Node($T), acc: N) -> N {
        if node == nil {
            return acc
        }

        next := node.next
        node.next = acc

        return aux(next, node)
    }

    return aux(node, nil)
}

/*
   Reverse the list.
   O(n).
 */
reverse :: proc(list: $L/^List($T)) {
    new_back := list.front
    list.front = node_reverse(list.front)
    list.back = new_back
}

/*
   Insert data into list at position n from the front.
   O(1) in the front and back, O(n) elsewhere.
*/
insert :: proc(list: ^List($T), idx: uint, data: T, allocator := context.allocator) -> (err: Error) {
    data := data
    context.user_ptr = &data

    node_insert :: proc(node, acc: $N/^Node($T), n: uint, allocator := context.allocator) -> N {
        if n == 0 {
            data_ptr := cast(^T)context.user_ptr
            new_node := make_node(data_ptr^, acc, allocator)
            reversed := node_reverse(new_node)

            new_node.next = node
            return reversed
        }

        assert(node != nil)
        node_insert(node.next, node, n - 1, allocator)
        return node
    }

    switch idx {
    case 0, 0..<list.len:
        list.front = node_insert(list.front, nil, idx, allocator)
    case list.len:
        list.back.next = make_node(data, nil, allocator)
        list.back = list.back.next
    case:
        return .Index_Out_Of_Bounds
    }

    list.front = (list.front == nil) ? list.back  : list.front
    list.back  = (list.back  == nil) ? list.front : list.back

    if err == nil { list.len += 1 }
    return
}

/*
   Insert an element to the front of the list.
   O(1).
*/
prepend :: proc(list: ^List($T), data: T, allocator := context.allocator) -> (err: Error) {
    return insert(list, 0, data, allocator)
}

/*
   Insert an element to the back of the list.
   O(1).
*/
append :: proc(list: ^List($T), data: T, allocator := context.allocator) -> (err: Error) {
    return insert(list, list.len, data, allocator)
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
   Get nth node.
   O(n).
 */
get_nth_node :: proc(node: $N/^Node($T), n: uint) -> (result: N, ok := true) {
    if node == nil {
        ok = false
        return
    }

    if n == 0 {
        result = node
        return
    }

    return get_nth_node(node.next, n - 1)
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

    switch n {
    case 0..<list.len-1:
        node, ok := get_nth_node(list.front, n)
        assert(ok)
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
test_node_reverse :: proc(t: ^testing.T) {
    defer free_all()
    node := make_node(1, make_node(2, make_node(3, nil)))

    node = node_reverse(node)
    testing.expect_value(t, node.data, 3)
    testing.expect_value(t, node.next.data, 2)
    testing.expect_value(t, node.next.next.data, 1)
}


@(test)
test_reverse :: proc(t: ^testing.T) {
    defer free_all()
    list := make([]int{ 1, 2, 3, 4, 5, 6, 7, 8, 9 })
    testing.expect_value(t, to_string(list), "[1, 2, 3, 4, 5, 6, 7, 8, 9]")

    reverse(&list)
    testing.expect_value(t, to_string(list), "[9, 8, 7, 6, 5, 4, 3, 2, 1]")
}

@(test)
test_make_from_slice :: proc(t: ^testing.T) {
    defer free_all()
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
    defer free_all()
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
    defer free_all()
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
    defer free_all()
    list: List(int)

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
    defer free_all()
    list: List(int)

    prepend(&list, 1)
    append(&list, 3)
    insert(&list, 1, 2)

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
    defer free_all()
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

import "core:log"
import "core:time"
import vmem "core:mem/virtual"

@(test)
test_perf :: proc(t: ^testing.T) {
    N :: 500_000
    T :: i64

    @(thread_local) seed: T
    seed = T(t.seed)

    options: time.Benchmark_Options
    options.setup = proc(options: ^time.Benchmark_Options, allocator := context.allocator) -> (err: time.Benchmark_Error) {
        options.processed = 0
        return
    }

    { // dyn array: inserting N elements from the back
        options.bench = proc(options: ^time.Benchmark_Options, allocator := context.allocator) -> (err: time.Benchmark_Error) {
            arr: [dynamic]T
            reserve(&arr, N)

            for n in 1..=N {
                append_elem(&arr, seed)
                options.processed += size_of(T)
            }

            return
        }

        time.benchmark(&options)
        log.info("vec insert back:", options.megabytes_per_second, "MB/s")
    }

    { // dyn array: inserting N elements from the front
        options.bench = proc(options: ^time.Benchmark_Options, allocator := context.allocator) -> (err: time.Benchmark_Error) {
            arr: [dynamic]T
            reserve(&arr, N)

            for n in 1..=N {
                inject_at(&arr, 0, seed)
                options.processed += size_of(T)
            }

            return
        }

        time.benchmark(&options)
        log.info("vec insert front:", options.megabytes_per_second, "MB/s")
    }

    { // dyn array: inserting and deleting elements in the middle
        options.bench = proc(options: ^time.Benchmark_Options, allocator := context.allocator) -> (err: time.Benchmark_Error) {
            arr := make_dynamic_array_len([dynamic]T, N)

            for n in 1..=N/1000 {
                unordered_remove(&arr, N/2)
                inject_at(&arr, N/2, seed)
                options.processed += size_of(T)
            }

            return
        }

        time.benchmark(&options)
        log.info("vec insert/delete:", options.megabytes_per_second, "MB/s")
    }

    free_all()

    arena: vmem.Arena
    context.allocator = vmem.arena_allocator(&arena)
    defer vmem.arena_destroy(&arena)

    { // inserting N elements from the back
        options.bench = proc(options: ^time.Benchmark_Options, allocator := context.allocator) -> (err: time.Benchmark_Error) {
            list: List(T)

            for n in 1..=N {
                append(&list, seed)
                options.processed += size_of(T)
            }

            return
        }

        time.benchmark(&options)
        log.info("list insert back:", options.megabytes_per_second, "MB/s")
    }

    { // inserting N elements from the front
        options.bench = proc(options: ^time.Benchmark_Options, allocator := context.allocator) -> (err: time.Benchmark_Error) {
            list: List(T)

            for n in 1..=N {
                prepend(&list, seed)
                options.processed += size_of(T)
            }

            return
        }

        time.benchmark(&options)
        log.info("list insert front:", options.megabytes_per_second, "MB/s")
    }

    { // inserting and deleting elements in the middle
        options.bench = proc(options: ^time.Benchmark_Options, allocator := context.allocator) -> (err: time.Benchmark_Error) {
            list: List(T)

            for n in 1..=N {
                append(&list, seed)
            }

            for n in 1..=N/1000 {
                remove(&list, N)
                insert(&list, N, seed)
                options.processed += size_of(T)
            }

            return
        }

        time.benchmark(&options)
        log.info("list insert/delete:", options.megabytes_per_second, "MB/s")
    }

    { // inserting and deleting elements in the middle -- alternative
        options.bench = proc(options: ^time.Benchmark_Options, allocator := context.allocator) -> (err: time.Benchmark_Error) {
            list: List(T)

            for n in 1..=N {
                append(&list, seed)
            }

            // get node before the middle
            prev_node, ok := get_nth_node(list.front, N/2 - 1)
            assert(ok)

            // now insertion and deletion can be O(1)
            for n in 1..=N {
                // delete element
                node := prev_node.next
                prev_node.next = prev_node.next.next
                free(node)
                // insert it again
                prev_node.next = make_node(seed, prev_node.next)

                options.processed += size_of(T)
            }

            return
        }

        time.benchmark(&options)
        log.info("list insert/delete (alternative):", options.megabytes_per_second, "MB/s")
    }
}
