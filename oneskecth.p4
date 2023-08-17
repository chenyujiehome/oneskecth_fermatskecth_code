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
#define LENGTH_2bit 4096
#define LENGTH_4bit 2048

register<bit<8>>(LENGTH_2bit) counters_2bit;
register<bit<8>>(LENGTH_4bit) counters_4bit;

action compute_light_hashes() {
    // These hash functions would need to be defined/available in P4.
    // Typically, you would use the available hash functions and then reduce them modulo LENGTH_2bit or LENGTH_4bit.
    bit<32> hash0 = hash1(hdr.ipv4.srcAddr);
    bit<32> hash1 = hash2(hdr.ipv4.srcAddr);

    meta.hash0_2bit = hash0 % LENGTH_2bit;
    meta.hash1_4bit = hash1 % LENGTH_4bit;
}

action insert_light() {
    bit<8> value_2bit;
    bit<8> value_4bit;

    // Read counters based on hash values
    counters_2bit.read(value_2bit, meta.hash0_2bit);
    counters_4bit.read(value_4bit, meta.hash1_4bit);

    // The actual insertion logic will involve bit manipulation
    // similar to your C++ code. Here, the bit operations have to
    // be done in a more explicit manner, e.g., using bit-slicing.

    // Here's a small example for the 2bit counter:
    if (meta.hash0_2bit % 4 == 0) {
        // Do operations for case 0
        // Example: (value_2bit & 0x3f) + (3 << 6);
    }
    // Similarly for other cases...

    // And for the 4bit counter:
    if (meta.hash1_4bit % 2 == 0) {
        // Do operations for case 0
    }
    // Similarly for other cases...

    // Finally, write back the values to the registers
    counters_2bit.write(meta.hash0_2bit, value_2bit);
    counters_4bit.write(meta.hash1_4bit, value_4bit);
}

// In the main ingress control block:
apply {
    compute_light_hashes();
    insert_light();
    // ... rest of your logic
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
