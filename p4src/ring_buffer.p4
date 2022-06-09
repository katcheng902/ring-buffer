/* -*- P4_16 -*- */
#include <core.p4>
#include <v1model.p4>

#include "include/headers.p4"
#include "include/parsers.p4"

#define CAPACITY 8
#define ELT_SIZE 1
#define LOG_CAPACITY 3

/*REGISTERS*/
Register <bit<LOG_CAPACITY>> (1) head;
Register <bit<LOG_CAPACITY>> (1) tail;
Register <bit<LOG_CAPACITY>> (1) capacity;
Register <bit<LOG_CAPACITY>> (1) size;
Register <bit<ELT_SIZE>> (CAPACITY) ring_buffer; 


/*initialize*/
head.write(0, 0);
tail.write(0, -1);
capacity.write(0, CAPACITY);
size.write(0, 0);


/*ENQUEUE*/

control Enqueue() {
    action inc_tail_action() {
	Register <bit <LOG_CAPACITY>> tmp_tail;
	tail.read(tmp_tail, 0);
	tail.write(0, tmp_tail + 1);
    }

    action inc_size_action() {
	Register <bit <LOG_CAPACITY>> tmp_size;
	size.read(tmp_size, 0);
	size.write(0, tmp_size + 1);
    }    

    action enq_action(value) { /*HOW TO CAPTURE THIS VALUE?? METADATA?*/
	Register <bit <LOG_CAPACITY>> tmp_tail;
	tail.read(tmp_tail, 0);
	ring_buffer.write(tail, value);
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


    table inc_size {
	actions = {
	    inc_size_action;
	}

	default_action = inc_size_action;
    }

    apply {
	size.read(size_value, 0);
	capacity.read(capacity_value, 0);
	IF (size_value < capacity_value) {
	    inc_tail.apply();
	    enq_arr.apply();
	    inc_size.apply();
	} ELSE {
	     
	}
    }
}


/************************************************************************
*************************    D E Q U E U E   ****************************
*************************************************************************/

control Dequeue() {
	
    table update

}



/*************************************************************************
************   C H E C K S U M    V E R I F I C A T I O N   *************
*************************************************************************/

control MyVerifyChecksum(inout headers hdr, inout metadata meta) {
    apply {  }
}


/*************************************************************************
**************  I N G R E S S   P R O C E S S I N G   *******************
*************************************************************************/

control MyIngress(inout headers hdr,
                  inout metadata meta,
                  inout standard_metadata_t standard_metadata) {

    action drop() {

        mark_to_drop(standard_metadata);
    }

    // TODO: define ingress processing logic
    action forward(egressSpec_t port) {
        // set the egress port
        standard_metadata.egress_spec = port;
        //hdr.ethernet.srcAddr = hdr.ethernet.dstAddr;
        //hdr.ethernet.dstAddr = dstAddr;
        //hdr.ipv4.ttl = hdr.ipv4.ttl - 1;
    }
    
    table ipv4_lpm {
        key = {
            hdr.ipv4.dstAddr: exact;
        }
        actions = {
          forward;
          drop;
        }
        default_action = drop();
    }
    
    apply {

        // TODO: call the table
        ipv4_lpm.apply();

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
    update_checksum(
	    hdr.ipv4.isValid(),
            { hdr.ipv4.version,
	          hdr.ipv4.ihl,
              hdr.ipv4.dscp,
              hdr.ipv4.ecn,
              hdr.ipv4.totalLen,
              hdr.ipv4.identification,
              hdr.ipv4.flags,
              hdr.ipv4.fragOffset,
              hdr.ipv4.ttl,
              hdr.ipv4.protocol,
              hdr.ipv4.srcAddr,
              hdr.ipv4.dstAddr },
              hdr.ipv4.hdrChecksum,
              HashAlgorithm.csum16);    
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
