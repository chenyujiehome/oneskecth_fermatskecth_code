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
// Assuming the definitions at the start of your provided P4 code...

// Extend the Metadata Definition for Heavy Part
metadata {
    bit<32> e;        // e is a 32-bit field
    bit<32> CH;      // Counter for heavy part
    bit<32> CL;      // Counter for light part
    bit<32> pos;     // Position in heavy bucket
    bit<32> minPos;  // Position of minimum value in bucket
    bit<32> minVal;  // Minimum value in bucket
    bool found;      // If item found in bucket
}

register<bit<32>>(HEAVY_LENGTH * COUNTER_PER_BUCKET) heavy_ID_register;
register<bit<32>>(HEAVY_LENGTH * COUNTER_PER_BUCKET) heavy_count_register;

// Insert Logic for Heavy Part
action insert_heavy_part() {
    meta.pos = hash(meta.e) % HEAVY_LENGTH;
    meta.minVal = 0xffffffff;
    meta.found = false;

    for (bit<8> i = 0; i < COUNTER_PER_BUCKET; i++) {
        bit<32> current_id;
        bit<32> current_count;
        
        heavy_ID_register.read(current_id, meta.pos + i);
        heavy_count_register.read(current_count, meta.pos + i);

        if (current_id == meta.e) {
            current_count += 1;
            heavy_count_register.write(meta.pos + i, current_count);
            meta.found = true;
            break;
        }

        if (current_count == 0) {
            heavy_ID_register.write(meta.pos + i, meta.e);
            heavy_count_register.write(meta.pos + i, 1);
            meta.found = true;
            break;
        }

        if (current_count < meta.minVal) {
            meta.minPos = i;
            meta.minVal = current_count;
        }
    }

    // Logic for moving to towerCU or updating it.
    // Note: This is a placeholder and would need actual logic for towerCU handling.
    if (!meta.found) {
        // Handle the case where the item was not inserted into the heavy part and needs to be added to towerCU
    }
}

// The rest of your P4 code...



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
