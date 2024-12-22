package linked_list

import "core:fmt"
import "core:strings"

iterate_ref :: proc(list: $L/^List($T), p: $P/proc(data: T, next: $N/^Node(T))) {
    iterate_node :: proc(node: N, p: P) {
        if node == nil { return }

        p(node.data, node.next)
        iterate_node(node.next, p)
    }

    iterate_node(list.front, p)
    return
}

iterate_val :: proc(list: $L/List($T), p: $P/proc(data: T, has_next: bool)) {
    iterate_node :: proc(node: $N/^Node(T), p: P) {
        if node == nil { return }

        p(node.data, node.next != nil)
        iterate_node(node.next, p)
    }

    iterate_node(list.front, p)
    return
}

iterate :: proc{
    iterate_ref,
    iterate_val,
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
test_to_string :: proc(t: ^testing.T) {
    list: List(int)
    append(&list, 1)
    append(&list, 2)
    append(&list, 3)

    {
        str := to_string(list)
        defer delete_string(str)
        testing.expect_value(t, str, "[1, 2, 3]")
    }
}
