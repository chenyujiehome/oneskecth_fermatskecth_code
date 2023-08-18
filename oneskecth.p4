#define HEAVY_LENGTH 1024  // 假设 HEAVY_LENGTH 是 1024
#define COUNTER_PER_BUCKET 4  // 假设每个存储桶有 4 个计数器

register<bit<32>>(HEAVY_LENGTH * COUNTER_PER_BUCKET) heavy_ID_register;
register<bit<32>>(HEAVY_LENGTH * COUNTER_PER_BUCKET) heavy_count_register;

action insert_heavy_part() {
    meta.pos = hash(meta.e) % HEAVY_LENGTH;
    meta.minVal = 0xffffffff;
    meta.found = false;

    for (bit<8> i = 0; i < COUNTER_PER_BUCKET; i++) {
        bit<32> current_id;
        bit<32> current_count;
        
        heavy_ID_register.read(current_id, meta.pos * COUNTER_PER_BUCKET + i);
        heavy_count_register.read(current_count, meta.pos * COUNTER_PER_BUCKET + i);

        if (current_id == meta.e) {
            current_count += 1;
            heavy_count_register.write(meta.pos * COUNTER_PER_BUCKET + i, current_count);
            meta.found = true;
            break;
        }

        if (current_count == 0) {
            heavy_ID_register.write(meta.pos * COUNTER_PER_BUCKET + i, meta.e);
            heavy_count_register.write(meta.pos * COUNTER_PER_BUCKET + i, 1);
            meta.found = true;
            break;
        }

        if (current_count < meta.minVal) {
            meta.minPos = i;
            meta.minVal = current_count;
        }
    }

    // 逻辑用于更新 towerCU，但这里是简化表示
    // 假设 towerCU_query() 和 towerCU_insert() 是在 P4 中定义的动作
    if (!meta.found) {
        if (random() % (meta.minVal + 1) == 0) {
            bit<32> light_query = towerCU_query(meta.e);
            towerCU_insert(heavy_ID_register.read(meta.pos * COUNTER_PER_BUCKET + meta.minPos),
                           heavy_count_register.read(meta.pos * COUNTER_PER_BUCKET + meta.minPos));
            heavy_ID_register.write(meta.pos * COUNTER_PER_BUCKET + meta.minPos, meta.e);
            heavy_count_register.write(meta.pos * COUNTER_PER_BUCKET + meta.minPos, light_query + 1);
        } else {
            towerCU_insert(meta.e);
        }
    }
}

control ingress {
    apply {
        compute_hash();
        insert_heavy_part();
        // 更多逻辑...
    }
}

// heavy part inert in cpp:
//   void Insert(const data_type item) {
//         uint32_t pos = hash(item) % HEAVY_LENGTH, minPos = 0;
//         count_type minVal = 0xffffffff;

//         for (uint32_t i = 0; i < COUNTER_PER_BUCKET; i++){
//             if(buckets[pos].ID[i] == item){
//                 buckets[pos].count[i] += 1;
//                 return;
//             }

//             if(buckets[pos].count[i] == 0){
//                 buckets[pos].ID[i] = item;
//                 buckets[pos].count[i] = 1;
//                 return;
//             }

//             if(buckets[pos].count[i] < minVal){
//                 minPos = i;
//                 minVal = buckets[pos].count[i];
//             }
//         }

//         if(!(rand()%(minVal+1))){
//             count_type light_query = towerCU->Query(item);
//             towerCU->Insert(buckets[pos].ID[minPos], buckets[pos].count[minPos]);
//             buckets[pos].ID[minPos] = item;
//             buckets[pos].count[minPos] = light_query + 1;
//         }
//         else {
//             towerCU->Insert(item);
//         }
// 	}