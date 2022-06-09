/* -*- P4_16 -*- */
#include <core.p4>
#include <v1model.p4>

#include "include/headers.p4"
#include "include/parsers.p4"

#define CAPACITY 2
#define ELT_SIZE 73
#define LOG_CAPACITY 1

struct metadata {
    bit<ELT_SIZE>> enq_value;
    bit<ELT_SIZE>> deq_value;
}

/*REGISTERS*/
Register <bit<LOG_CAPACITY>> (1) head;
Register <bit<LOG_CAPACITY>> (1) tail;
Register <bit<LOG_CAPACITY>> (1) capacity;
Register <bit<ELT_SIZE>> (CAPACITY) ring_buffer; 


/*initialize*/
head.write(0, 0);
tail.write(0, -1);
capacity.write(0, CAPACITY);

/*ENQUEUE*/

control Enqueue(inout metadata meta) {
    action inc_tail_action() {
	Register <bit <LOG_CAPACITY>> tmp_tail;
	Register <bit <LOG_CAPACITY>> tmp_cap;
	tail.read(tmp_tail, 0);
	capacity.read(tmp_cap, 0);
	if (tmp_tail < tmp_cap-1) {
	    tail.write(0, tmp_tail + 1);
	} else {
	    tail.write(0, 0); /*ring -> mod*/
	}
    }

    action inc_size_action() {
	Register <bit <LOG_CAPACITY>> tmp_size;
	size.read(tmp_size, 0);
	size.write(0, tmp_size + 1);
    }    

    action enq_action(enq_value) { /*how to get input value???*/
	Register <bit <LOG_CAPACITY>> tmp_tail;
	tail.read(tmp_tail, 0);
	ring_buffer.write(tail, enq_value);
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

	default_action = enq_action
    }

    apply {
	size.read(size_value, 0);
	capacity.read(capacity_value, 0);
	if (size_value <= capacity_value) {
	    inc_tail.apply();
	    enq_arr.apply();
	}
    }
}


/*DEQUEUE*/

control Dequeue(inout metadata meta) {

    action deq_arr_action(out deq_value) {
	Register <bit <LOG_CAPACITY>> tmp_head;
	head.read(tmp_head, 0);
	ring_buffer.read(deq_value, head);
    }

    action inc_head_action() {
	Register <bit <LOG_CAPACITY>> tmp_head;
        Register <bit <LOG_CAPACITY>> tmp_cap;
        head.read(tmp_head, 0);
        capacity.read(tmp_cap, 0);
        if (tmp_head < tmp_cap-1) {
            head.write(0, tmp_head + 1);
        } else {
            head.write(0, 0); /*ring -> mod*/
        }
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

    apply {
	deq_arr.apply();
	inc_head.apply();
    }

}

/*I G N O R E     B E L O W */

/*************************************************************************
************   C H E C K S U M    V E R I F I C A T I O N   *************
*************************************************************************/

control MyVerifyChecksum(inout headers hdr, inout metadata meta) {
    apply {  }
}


 N G R E S S   P R O C E S S I N G   *******************
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
