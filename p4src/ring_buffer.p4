/* -*- P4_16 -*- */
#include <core.p4>
#include <v1model.p4>

#include "include/headers.p4"
#include "include/parsers.p4"

#REGISTERS (begin with capacity 7, 160 bit entries)
Register <bit<3>> (1) head;
Register <bit<3>> (1) tail;
Register <bit<3>> (1) capacity;
Register <bit<3>> (1) size;
Register <bit<160>> (8) ring_buffer; 

capacity.write(0, 111); #capacity = 7

/*
control CreateRingBuffer(inout headers hdr,
                  inout metadata meta,
                  inout standard_metadata_t standard_metadata) {



}*/

/************************************************************************
*************************    E N Q U E U E   ****************************
*************************************************************************/

control Enqueue() {
    table inc_tail {

    }


    table enq_arr {

    }


    table inc_size {

    }

    apply {
	size.read(size_value, 0);
	capacity.read(capacity_value, 0);
	IF (size_value < capacity_value) {
	    
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