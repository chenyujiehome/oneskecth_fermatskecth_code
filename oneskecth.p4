action compute_light_hashes() {
    // Assuming hdr.ipv4.srcAddr is the item in C++ code. 
    bit<32> hash0 = hash1(hdr.ipv4.srcAddr);
    bit<32> hash1 = hash2(hdr.ipv4.srcAddr);

    meta.hash0_2bit = hash0 % LENGTH_2bit;
    meta.hash1_4bit = hash1 % LENGTH_4bit;
}

action insert_light() {
    bit<8> value_2bit;
    bit<8> value_4bit;
    bit<2> minVal_2bit = 3;
    bit<4> minVal_4bit = 15;

    // Read counters based on hash values
    counters_2bit.read(value_2bit, meta.hash0_2bit / 4);
    counters_4bit.read(value_4bit, meta.hash1_4bit / 2);

    // Get the index in counter
    bit<2> index_2bit = meta.hash0_2bit % 4;
    bit<1> index_4bit = meta.hash1_4bit % 2;

    // 2bit counter value extraction logic
    switch (index_2bit) {
        case 0: minVal_2bit = value_2bit >> 6; break;
        case 1: minVal_2bit = (value_2bit >> 4) & 0x03; break;
        case 2: minVal_2bit = (value_2bit >> 2) & 0x03; break;
        case 3: minVal_2bit = value_2bit & 0x03; break;
    }

    // 4bit counter value extraction logic
    switch (index_4bit) {
        case 0: minVal_4bit = value_4bit >> 4; break;
        case 1: minVal_4bit = value_4bit & 0x0f; break;
    }

    bit<4> minVal = (minVal_2bit < minVal_4bit) ? minVal_2bit : minVal_4bit;

    // 2bit counter update logic
    switch (index_2bit) {
        case 0:
            value_2bit = (minVal >= 3) ? (value_2bit & 0x3f) | (3 << 6) : (value_2bit & 0x3f) | (minVal << 6);
            break;
        case 1:
            value_2bit = (minVal >= 3) ? (value_2bit & 0xcf) | (3 << 4) : (value_2bit & 0xcf) | (minVal << 4);
            break;
        case 2:
            value_2bit = (minVal >= 3) ? (value_2bit & 0xf3) | (3 << 2) : (value_2bit & 0xf3) | (minVal << 2);
            break;
        case 3:
            value_2bit = (minVal >= 3) ? (value_2bit & 0xfc) | 3 : (value_2bit & 0xfc) | minVal;
            break;
    }

    // 4bit counter update logic
    switch (index_4bit) {
        case 0:
            value_4bit = (minVal >= 15) ? (value_4bit & 0x0f) | (15 << 4) : (value_4bit & 0x0f) | (minVal << 4);
            break;
        case 1:
            value_4bit = (minVal >= 15) ? (value_4bit & 0xf0) | 15 : (value_4bit & 0xf0) | minVal;
            break;
    }

    // Write back to the registers
    counters_2bit.write(meta.hash0_2bit / 4, value_2bit);
    counters_4bit.write(meta.hash1_4bit / 2, value_4bit);
}

apply {
    compute_light_hashes();
    insert_light();
}


// light part of the code in cpp is as follows:
//    void Insert(const data_type item, count_type val ) {
//         count_type minVal = 15, value, set_value;
// 		uint32_t counter_pos, index_in_counter;

//         for (int i = 0; i < 2; i++) {
//             if (i == 0) {
//                 counter_pos = hash(item, i) % LENGTH_2bit / 4;
//                 index_in_counter = hash(item, i) % LENGTH_2bit % 4;
//                 value = GetTwoBit(counters_2bit[counter_pos], index_in_counter);
//                 if (value < 3 && value < minVal) {
//                     minVal = value;
//                 }

//             }
//             else {
//                 counter_pos = hash(item, i) % LENGTH_4bit / 2;
//                 index_in_counter = hash(item, i) % LENGTH_4bit % 2;
//                 value = GetFourBit(counters_4bit[counter_pos], index_in_counter);
//                 if (value < 15 && value < minVal) {
//                     minVal = value;
//                 }

//             }
//         }

//         if (minVal == 15) return;

//         for (int i = 0; i < 2; i++) {
//             if (i == 0) {
//                 counter_pos = hash(item, 0) % LENGTH_2bit / 4;
//                 index_in_counter = hash(item, 0) % LENGTH_2bit % 4;
//                 value = GetTwoBit(counters_2bit[counter_pos], index_in_counter);
//                 set_value = (count_type)max((uint32_t)value, (uint32_t)(max(minVal, val)));
//                 switch (index_in_counter) {
//                 case 0:
//                     if (set_value >= 3) {
//                         counters_2bit[counter_pos] = (counters_2bit[counter_pos] & 0x3f) + (3 << 6);
//                     }
//                     else {
//                         counters_2bit[counter_pos] = (counters_2bit[counter_pos] & 0x3f) + (set_value << 6);
//                     }
//                     break;
//                 case 1:
//                     if (set_value >= 3) {
//                         counters_2bit[counter_pos] = (counters_2bit[counter_pos] & 0xcf) + (3 << 4);
//                     }
//                     else {
//                         counters_2bit[counter_pos] = (counters_2bit[counter_pos] & 0xcf) + (set_value << 4);
//                     }
//                     break;
//                 case 2:
//                     if (set_value >= 3) {
//                         counters_2bit[counter_pos] = (counters_2bit[counter_pos] & 0xf3) + (3 << 2);
//                     }
//                     else {
//                         counters_2bit[counter_pos] = (counters_2bit[counter_pos] & 0xf3) + (set_value << 2);
//                     }
//                     break;
//                 case 3:
//                     if (set_value >= 3) {
//                         counters_2bit[counter_pos] = (counters_2bit[counter_pos] & 0xfc) + 3;
//                     }
//                     else {
//                         counters_2bit[counter_pos] = (counters_2bit[counter_pos] & 0xfc) + set_value;
//                     }
//                     break;
//                 }
//             }
//             else {
//                 counter_pos = hash(item, 1) % LENGTH_4bit / 2;
//                 index_in_counter = hash(item, 1) % LENGTH_4bit % 2;
//                 value = GetFourBit(counters_4bit[counter_pos], index_in_counter);
//                 set_value = (count_type)max((uint32_t)value, (uint32_t)(max(minVal, val)));
//                 switch (index_in_counter) {
//                 case 0:
//                     if (set_value >= 15) {
//                         counters_4bit[counter_pos] = (counters_4bit[counter_pos] & 0xf) + (15 << 4);
//                     }
//                     else {
//                         counters_4bit[counter_pos] = (counters_4bit[counter_pos] & 0xf) + (set_value << 4);
//                     }
//                     break;
//                 case 1:
//                     if (set_value >= 15) {
//                         counters_4bit[counter_pos] = (counters_4bit[counter_pos] & 0xf0) + 15;
//                     }
//                     else {
//                         counters_4bit[counter_pos] = (counters_4bit[counter_pos] & 0xf0) + set_value;
//                     }
//                     break;
//                 }

//             }
//         }

//     }