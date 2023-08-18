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
