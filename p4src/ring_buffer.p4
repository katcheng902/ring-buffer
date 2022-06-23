/*************************************************************************************
**************************** R I N G    B U F F E R *********************************
*************************************************************************************/
#include "include/define.p4"

/*registers -- apparently later versions of v1model allow for initialized registers*/
register<bit<POINTER_SIZE>>(1) head_reg; /*32 bits instead of log(capacity) wastes space*/
register<bit<POINTER_SIZE>>(1) tail_reg;
register<bit<1>>(1) first_tail; /*because can't initialize to -1, must have tail not increment on the first use*/

register<bit<ELT_SIZE>>(CAPACITY) buffer;

action prox_mod(in bit<POINTER_SIZE> num, in bit<POINTER_SIZE> modulus, out bit<POINTER_SIZE> output) {
    if (num < modulus) {
	output = num;
    } else {
	output = 0;
    }
}

/*these actions are so that users can change pointers in the control plane*/
action inc_tail(bit<POINTER_SIZE> step) { /*could overflow -- so make 31 bits*/
   bit<POINTER_SIZE> tmp_tail;
   tail_reg.read(tmp_tail, 0);
   tail_reg.write(0, tmp_tail+step);
}

action dec_tail(bit<POINTER_SIZE> step) {
   bit<POINTER_SIZE> tmp_tail;
   tail_reg.read(tmp_tail, 0);
   tail_reg.write(0, tmp_tail-step);
}

action inc_head(bit<POINTER_SIZE> step) {
   bit<POINTER_SIZE> tmp_head;
   head_reg.read(tmp_head, 0);
   head_reg.write(0, tmp_head+step);
}

action dec_head(bit<POINTER_SIZE> step) { 
   bit<POINTER_SIZE> tmp_head;
   head_reg.read(tmp_head, 0);
   head_reg.write(0, tmp_head-step);
}

action enqueue_buffer(bit<ELT_SIZE> in_value) {
    /*increment tail mod cap*/
    bit<POINTER_SIZE> tmp_tail;
    tail_reg.read(tmp_tail, 0);
    bit<POINTER_SIZE> new_tail;

    bit<1> first_tail_tmp;
    first_tail.read(first_tail_tmp, 0);
    if (first_tail_tmp != (bit<1>)0) {
        prox_mod(tmp_tail+1, CAPACITY, new_tail);
    }
    first_tail.write(0, 1);
    
    tail_reg.write(0, new_tail);

    /*enqueue*/
    buffer.write((bit<32>) new_tail, in_value);
}

action dequeue_buffer(out bit<ELT_SIZE> out_value) {
    bit<POINTER_SIZE> tmp_head;
    head_reg.read(tmp_head, 0);

    /*dequeue*/
    buffer.read(out_value, (bit<32>)tmp_head);

    /*increment head mod cap*/
    bit<POINTER_SIZE> new_head;
    prox_mod(tmp_head+1, CAPACITY, new_head);
    head_reg.write(0, new_head);
}

