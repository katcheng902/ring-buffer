/*************************************************************************************
**************************** R I N G    B U F F E R *********************************
*************************************************************************************/

/*REGISTERS*/
register<bit<32>>(1) head_reg; /*32 bits instead of log(capacity) wasting space*/
register<bit<32>>(1) tail_reg;
register<bit<32>>(1) capacity_reg;
register<bit<32>>(1) elt_reg;

action RingBuffer(in bit<32> capacity, in bit<32> elt_size) {
    register<bit<elt_size>>(capacity) buffer;
     
    head_reg.write(0, 0);
    tail_reg.write(0, 0);
    capacity_reg.write(0, capacity); 
    elt_reg.write(0, elt_size);
}

action enqueue(in in_value) { /*in_value has type bit<size_reg>*/
    /*increment tail mod cap*/
    bit<32> tmp_tail;
    bit<32> tmp_cap;
    tail_reg.read(tmp_tail, 0);
    capacity_reg.read(tmp_cap, 0);
    if (tmp_tail < tmp_cap - 1) {
        tail_reg.write(0, tmp_tail + 1);
    } else {
        tail_reg.write(0, 0);
    }

    /*enqueue*/
    tail_reg.read(tmp_tail, 0);
    buffer.write(tmp_tail, in_value);

}

action dequeue(out out_value) {
    bit<32> tmp_head;
    head_reg.read(tmp_head, 0);

    /*dequeue*/
    buffer.read(out_value, tmp_head);

    /*increment head mod cap*/
    bit<32> tmp_cap;
    capacity_reg.read(tmp_cap, 0);
    if (tmp_head < tmp_cap - 1) {
        head_reg.write(0, tmp_head + 1);
    } else {
        head_reg.write(0, 0);
    }

}

