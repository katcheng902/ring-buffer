/* -*- P4_16 -*- */
#include <core.p4>
#include <v1model.p4>

#include "include/headers.p4"
#include "include/parsers.p4"
#include "include/define.p4"

/*REGISTERS -- store as metadata/somehow inside the buffer??*/
register<bit<32>>(1) head;
register<bit<32>>(1) tail;
register<bit<32>>(1) capacity;
register<bit<32>>(1) buffer_size;
register<bit<ELT_SIZE>>(CAPACITY) ring_buffer;

/*initialize
head.write((bit<32> 0), (bit<ELT_SIZE> 0));
tail.write(0, -1);
capacity.write(0, CAPACITY);
buffer_size.write(0, 0);
*/

control Initialize() {
    action init_head_action() {
	head.write(0, 0);
    }

    action init_tail_action() {
        tail.write(0, -1);
    }

    action init_capacity_action() {
        capacity.write(0, CAPACITY);
    }

    action init_size_action() {
        buffer_size.write(0, 0);
    }

    table init_head {
	actions = {
	    init_head_action;
	}

	default_action = init_head_action;
    }

    table init_tail {
        actions = {
            init_tail_action;
        }

        default_action = init_tail_action;
    }

    table init_capacity {
        actions = {
            init_capacity_action;
        }

        default_action = init_capacity_action;
    }

    table init_size {
        actions = {
            init_size_action;
        }

        default_action = init_size_action;
    }

    apply {
	init_head.apply();
	init_tail.apply();
	init_capacity.apply();
	init_size.apply();
    }
}


/*ENQUEUE*/

control Enqueue(inout metadata meta) {
    action inc_tail_action() {
	bit<LOG_CAPACITY> tmp_tail;
	bit<LOG_CAPACITY> tmp_cap;
	tail.read(tmp_tail, 0);
	capacity.read(tmp_cap, 0);
	if (tmp_tail < tmp_cap-1) {
	    tail.write(0, tmp_tail + 1);
	} else {
	    tail.write(0, 0); /*ring -> mod*/
	}
    }

    action inc_size_action() {
	bit<LOG_CAPACITY> tmp_size;
	buffer_size.read(tmp_size, 0);
	buffer_size.write(0, tmp_size + 1);
    }    

    action enq_action() {
	bit<LOG_CAPACITY> tmp_tail;
	tail.read(tmp_tail, 0);
	ring_buffer.write(tail, meta.enq_value);
    }

    table inc_tail {
	actions = {
	    inc_tail_action;
	}

	default_action = inc_tail_action;
    }


    table enq_arr {
	actions = {
	    enq_action;
	}

	default_action = enq_action;
    }

    apply {
	bit<LOG_CAPACITY> tmp_size;
	bit<LOG_CAPACITY> tmp_capacity;
	buffer_size.read(tmp_size, 0);
	capacity.read(tmp_capacity, 0);
	if (tmp_size <= tmp_capacity) {
	    inc_tail.apply();
	    enq_arr.apply();
	}
    }
}


/*DEQUEUE*/

control Dequeue(inout metadata meta) {

    action deq_arr_action() {
	bit<LOG_CAPACITY> tmp_head;
	head.read(tmp_head, 0);
	ring_buffer.read(meta.deq_value, head);
    }

    action inc_head_action() {
	bit<LOG_CAPACITY> tmp_head;
        bit<LOG_CAPACITY> tmp_cap;
        head.read(tmp_head, 0);
        capacity.read(tmp_cap, 0);
        if (tmp_head < tmp_cap-1) {
            head.write(0, tmp_head + 1);
        } else {
            head.write(0, 0); /*ring -> mod*/
        }
    }

    action dec_size_action() {
         bit<LOG_CAPACITY> tmp_size;
         buffer_size.read(tmp_size, 0);
         buffer_size.write(0, tmp_size - 1);
    }

	
    table deq_arr {
	actions = {
	    deq_arr_action;
	}
	
	default_action = deq_arr_action;
    }

    table inc_head {
	actions = {
	    inc_head_action;
	}

	default_action = inc_head_action;
    }

    table dec_size {
	actions = {
	    dec_size_action;
	}

	default_action = dec_size_action;
    }

    apply {
	 bit<LOG_CAPACITY> tmp_size;
	 buffer_size.read(tmp_size, 0);
         if (tmp_size > 0) {
	     deq_arr.apply();
	     inc_head.apply();
	     dec_size.apply();
	 }
    }

}

/*I G N O R E     B E L O W */

/*************************************************************************
************   C H E C K S U M    V E R I F I C A T I O N   *************
*************************************************************************/

control MyVerifyChecksum(inout headers hdr, inout metadata meta) {
    apply {  }
}

/************************************************************************
**************   I N G R E S S   P R O C E S S I N G   *******************
*************************************************************************/

control MyIngress(inout headers hdr,
                  inout metadata meta,
                  inout standard_metadata_t standard_metadata) {

    /* define two actions, drop and forward */
    action drop() {

        mark_to_drop(standard_metadata);
    }

    /* forward action takes as input the egress_port */
    /* set the output port to that argument */
    action forward(bit<9> egress_port) {
        standard_metadata.egress_spec = egress_port;
    }

    /* define the dmac table, serving as the forwarding table */
    table dmac {
        /* match the ethernet destination address */
        key = {
            hdr.ethernet.dstAddr: exact;
        }

        /* define the list of actions */
        actions = {
            forward;
            drop;
            NoAction;
        }
        size = 256;
        default_action = NoAction;
    }

    apply {

        dmac.apply();

    }
}

/*************************************************************************
****************  E G R E S S   P R O C E S S I N G   *******************
*************************************************************************/

control MyEgress(inout headers hdr,
                 inout metadata meta,
                 inout standard_metadata_t standard_metadata) {


    apply {  }
}

/*************************************************************************
*************   C H E C K S U M    C O M P U T A T I O N   **************
*************************************************************************/

control MyComputeChecksum(inout headers hdr, inout metadata meta) {
     apply {

    }
}


/*************************************************************************
***********************  S W I T C H  *******************************
*************************************************************************/

//switch architecture
V1Switch(
MyParser(),
MyVerifyChecksum(),
MyIngress(),
MyEgress(),
MyComputeChecksum(),
MyDeparser()
) main;
