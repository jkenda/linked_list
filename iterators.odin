package linked_list

import "core:fmt"
import "core:strings"

/*
   Iterate over the list by value.
 */
iterate_val :: proc(list: $L/List($T), p: $P/proc(data: T, has_next: bool)) {
    iterate :: proc(node: $N/^Node(T), p: P) {
        if node == nil { return }

        p(node.data, node.next != nil)
        iterate(node.next, p)
    }

    iterate(list.front, p)
}

/*
   Iterate over the list by reference/pointer.
 */
iterate_ref :: proc(list: $L/^List($T), p: $P/proc(data: ^T, has_next: bool)) {
    iterate :: proc(node: $N/^Node(T), p: P) {
        if node == nil { return }

        p(&node.data, node.next != nil)
        iterate(node.next, p)
    }

    iterate(list.front, p)
}

/*
   Iterate over the list by node.
 */
iterate_node :: proc(list: $L/^List($T), p: $P/proc(node: $N/^Node(T))) {
    context.user_ptr = list

    iterate :: proc(node: N, p: P) {
        if node == nil { return }

        next := node.next
        p(node)

        list := cast(L)context.user_ptr
        if node == list.back {
            for list.back.next != nil {
                list.back = list.back.next
            }
        }

        iterate(next, p)
    }

    iterate(list.front, p)
}

/*
   Iterate procedure group.
 */
iterate :: proc{
    iterate_val,
    iterate_ref,
    iterate_node,
}

/*
   Create a string representation of the list.
 */
to_string :: proc(list: $L/List($T), allocator := context.allocator) -> string {
    @(thread_local)
    builder: strings.Builder
    strings.builder_init(&builder, allocator)

    strings.write_rune(&builder, '[')

    iterate(list, proc(data: T, has_next: bool) {
        fmt.sbprint(&builder, data)
        if has_next {
            fmt.sbprint(&builder, ", ")
        }
    })

    strings.write_rune(&builder, ']')
    return strings.to_string(builder)
}

@(private)
node_to_string :: proc(node: $N/^Node($T), allocator := context.allocator) -> string {
    @(thread_local)
    sb: strings.Builder
    sb = strings.builder_make(allocator)

    aux :: proc(node: $N/^Node($T)) {
        if node == nil { return }

        fmt.sbprintf(&sb, "{} ", node.data)
        aux(node.next)
    }

    fmt.sbprint(&sb, "[")
    aux(node)
    fmt.sbprint(&sb, "]")
    return strings.to_string(sb)
}


import "core:testing"

@(test)
test_iterate_ref :: proc(t: ^testing.T) {
    defer free_all()
    list := make([]int{ 1, 2, 3 })

    iterate_ref(&list, proc(data: ^int, _: bool) {
        data^ = 0
    })
    testing.expect_value(t, to_string(list), "[0, 0, 0]")

    iterate_ref(&list, proc(data: ^int, has_next: bool) {
        data^ = has_next ? 1 : 2
    })
    testing.expect_value(t, to_string(list), "[1, 1, 2]")
}

@(test)
test_iterate_node :: proc(t: ^testing.T) {
    defer free_all()
    list := make([]int{ 1, 2, 3 })

    // insert zeros in between nodes
    iterate_node(&list, proc(node: ^Node(int)) {
        node.next = make_node(0, node.next)
    })

    testing.expect_value(t, to_string(list), "[1, 0, 2, 0, 3, 0]")
    testing.expect_value(t, list.back.data, 0)
}

@(test)
test_to_string :: proc(t: ^testing.T) {
    defer free_all()
    list := make([]int{ 1, 2, 3 })

    {
        str := to_string(list)
        defer delete_string(str)
        testing.expect_value(t, str, "[1, 2, 3]")
    }
}
