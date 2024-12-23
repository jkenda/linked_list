package linked_list

import "core:fmt"
import "core:strings"

iterate_val :: proc(list: $L/List($T), p: $P/proc(data: T, has_next: bool)) {
    iterate :: proc(node: $N/^Node(T), p: P) {
        if node == nil { return }

        p(node.data, node.next != nil)
        iterate(node.next, p)
    }

    iterate(list.front, p)
}

iterate_ref :: proc(list: $L/^List($T), p: $P/proc(data: ^T, has_next: bool)) {
    iterate :: proc(node: $N/^Node(T), p: P) {
        if node == nil { return }

        p(&node.data, node.next != nil)
        iterate(node.next, p)
    }

    iterate(list.front, p)
}

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

iterate :: proc{
    iterate_val,
    iterate_ref,
    iterate_node,
}

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


import "core:testing"

@(test)
test_iterate_ref :: proc(t: ^testing.T) {
    list := make([]int{ 1, 2, 3 })

    iterate_ref(&list, proc(data: ^int, _: bool) {
        data^ = 0
    })

    testing.expect_value(t, to_string(list), "[0, 0, 0]")
}

@(test)
test_iterate_node :: proc(t: ^testing.T) {
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
    list := make([]int{ 1, 2, 3 })

    {
        str := to_string(list)
        defer delete_string(str)
        testing.expect_value(t, str, "[1, 2, 3]")
    }
}
