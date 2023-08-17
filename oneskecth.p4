// 定义数据结构
header_type onesketch_meta_t {
    fields {
        e : 32;  // 假设 e 是一个 32 位的字段
        CH : 32; // Counter for heavy part
        CL : 32; // Counter for light part
        ...
    }
}

// 定义哈希函数 h()
action compute_hash() {
    modify_field(onesketch_meta.e, hash2(onesketch_meta.e));
}

// 插入逻辑
action insert_onesketch() {
    if (onesketch_table.exists(onesketch_meta.e)) {
        onesketch_meta.CH++;
    } else {
        onesketch_table.add(onesketch_meta.e, 1);
    }
    // 更多逻辑...
}

// 主要控制流
control ingress {
    apply {
        compute_hash();
        insert_onesketch();
        // 更多逻辑...
    }
}

// 定义表格结构等
table onesketch_table {
    actions {
        insert_onesketch;
        ...
    }
    size: 1024; // 假设的表格大小
    default_action: insert_onesketch;
}
