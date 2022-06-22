/*************************************************************************************
**************************** R I N G    B U F F E R *********************************
*************************************************************************************/
#include "include/define.p4"

/*registers*/
register<bit<32>>(1) head_reg; /*32 bits instead of log(capacity) wastes space*/
register<bit<32>>(1) tail_reg;
register<bit<1>>(1) first_tail;

register<bit<ELT_SIZE>>(CAPACITY) buffer;

action prox_mod(in bit<32>num, in bit<32>modulus, out bit<32>output) {
    if (num < modulus) {
	output = num;
    } else {
	output = 0;
    }
}

action enqueue_buffer(bit<ELT_SIZE> in_value) {
    /*increment tail mod cap*/
    bit<32> tmp_tail;
    tail_reg.read(tmp_tail, 0);
    bit<32> new_tail;

    bit<1> first_tail_tmp;
    first_tail.read(first_tail_tmp, 0);
    if (first_tail_tmp != (bit<1>)0) {
        prox_mod(tmp_tail+1, CAPACITY, new_tail);
    }
    first_tail.write(0, 1);
    
    tail_reg.write(0, new_tail);

    /*enqueue*/
    buffer.write(new_tail, in_value);
}

action dequeue_buffer(out bit<ELT_SIZE> out_value) {
    bit<32> tmp_head;
    head_reg.read(tmp_head, 0);

    /*dequeue*/
    buffer.read(out_value, (bit<32>)tmp_head);

    /*increment head mod cap*/
    bit<32> new_head;
    prox_mod(tmp_head+1, CAPACITY, new_head);
    head_reg.write(0, new_head);
}

