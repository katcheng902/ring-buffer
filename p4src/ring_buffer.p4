/*************************************************************************************
**************************** R I N G    B U F F E R *********************************
*************************************************************************************/
#define CAPACITY 8
#define ELT_SIZE 2

/*registers*/
register<bit<32>>(1) head_reg; /*32 bits instead of log(capacity) wastes space*/
register<bit<32>>(1) tail_reg;

register<bit<ELT_SIZE>>(CAPACITY) buffer;


action initialize_buffer() {
    /*intialize values*/
    head_reg.write(0, 0);
    tail_reg.write(0, 0);
}

action enqueue_buffer(in bit<ELT_SIZE> in_value) {
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
    buffer.write((bit<32>)tmp_tail, in_value);

}

action dequeue_buffer(out bit<ELT_SIZE> out_value) {
    bit<32> tmp_head;
    head_reg.read(tmp_head, 0);

    /*dequeue*/
    buffer.read(out_value, (bit<32>)tmp_head);

    /*increment head mod cap*/
    bit<32> tmp_cap;
    capacity_reg.read(tmp_cap, 0);
    if (tmp_head < tmp_cap - 1) {
        head_reg.write(0, tmp_head + 1);
    } else {
        head_reg.write(0, 0);
    }

}

