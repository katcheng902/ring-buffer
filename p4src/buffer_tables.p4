#include "include/define.p4"
#define SIZE_REG 4

/*REGISTERS*/
register<bit<POINTER_SIZE>>(1) head_reg; /*POINTER_SIZE = log(CAPACITY)*/
register<bit<POINTER_SIZE>>(1) tail_reg;
register<bit<SIZE_REG>>(1) buffer_size;

register<bit<ELT_SIZE>>(CAPACITY) buffer;

/*FLAGS*/
register<bit<1>>(1) first_tail; /*b/c can't initialize this type to -1: 0 if first time around, 1 otherwise*/

control Enqueue(inout headers hdr,
                  inout metadata meta,
                  inout standard_metadata_t standard_metadata) {

    bit<1> first_tail_tmp;
    bit<SIZE_REG> buffer_size_tmp;

    /*ACTIONS*/
    action init_enq() {
	first_tail.read(first_tail_tmp, 0);
	buffer_size.read(buffer_size_tmp, 0);
    }

    action set_first_tail_to_one() {
	first_tail.write(0, 1);
    }

    action inc_tail() {
        bit<POINTER_SIZE> tmp_tail;
        tail_reg.read(tmp_tail, 0);
        tail_reg.write(0, tmp_tail + 1);
    }

    action enqueue_action(in bit<ELT_SIZE> in_value) {
	bit<POINTER_SIZE> tmp_tail;
	tail_reg.read(tmp_tail, 0);
	buffer.write((bit<32>) tmp_tail, in_value);
    }

    action inc_size() {
	buffer_size.write(0, buffer_size_tmp + 1);
    }
  
    /*TABLES*/
    table init_enq_table {
	actions = {
	    init_enq;
	}
	
	default_action = init_enq;
    }

    table tail_table {
	key = {
	    first_tail_tmp: exact;
	}

        actions = {
	    set_first_tail_to_one;
	    inc_tail;
	}

	size = 256;
	default_action = set_first_tail_to_one;
    }

    table enqueue_table {
	actions = {
	    enqueue_action(1);
	}
	
	default_action = enqueue_action(1);
    }

    table size_table {
	key = {
	    buffer_size_tmp: exact;
	}	

	actions = {
	    inc_size;
	    NoAction;
	}

	size = 256;
	default_action = inc_size;
    }

    apply {
	init_enq_table.apply();
        tail_table.apply();
	enqueue_table.apply();
	size_table.apply();
    }
        
}

control Dequeue(inout headers hdr,
                  inout metadata meta,
                  inout standard_metadata_t standard_metadata) {

    bit<SIZE_REG> buffer_size_tmp;

    action init_deq() {
	buffer_size.read(buffer_size_tmp, 0);
    }

    action dequeue_action(out bit<ELT_SIZE> out_value) {
	bit<POINTER_SIZE> tmp_head;
        head_reg.read(tmp_head, 0);

        buffer.read(out_value, (bit<32>)tmp_head);
    }

    action inc_head() {
	bit<POINTER_SIZE> tmp_head;
        head_reg.read(tmp_head, 0);
        head_reg.write(0, tmp_head + 1);
    }

    action dec_size() {
	buffer_size.write(0, buffer_size_tmp - 1);
    }

    table init_deq_table {
	actions = {
	    init_deq;
	}

	default_action = init_deq;
    }

    table dequeue_table {
	key = {
	    buffer_size_tmp: exact;
	}

	actions = {
	    dequeue_action(meta.deq_value);
	    NoAction;
	}

	default_action = dequeue_action(meta.deq_value);
    }

    table head_table {
	actions = {
	    inc_head;
	}

	default_action = inc_head;
    }

    table dec_size_table {
	actions = {
	    dec_size;
	}

	default_action = dec_size;
    }

    apply {
	init_deq_table.apply();
	switch (dequeue_table.apply().action_run) {
	    dequeue_action: {
		head_table.apply();
	    	dec_size_table.apply();
	    }
	}
    }

}
