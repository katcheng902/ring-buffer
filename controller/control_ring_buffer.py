from p4utils.utils.topology import Topology
from p4utils.utils.sswitch_API import SimpleSwitchAPI
from p4utils.utils.thrift_API import ThriftAPI

import sys

CAPACITY = 8

#need restrictions on type?
def enqueue(thrift_api, in_value):
    first_tail_tmp = thrift_api.register_read("first_tail", 0)
    tail_tmp = thrift_api.register_read("tail_reg", 0)

    if (first_tail_tmp == 0):
        thrift_api.register_write("first_tail", 0, 1)
    else:
        tail_tmp = (tail_tmp+1) % CAPACITY
        thrift_api.register_write("tail_reg", 0, tail_tmp)

    thrift_api.register_write("ring_buffer", tail_tmp, in_value)

    size_tmp = thrift_api.register_read("buffer_size", 0)
    thrift_api.register_write("buffer_size", 0, min(size_tmp+1, CAPACITY))


def dequeue(thrift_api):
    size_tmp = thrift_api.register_read("buffer_size", 0)

    if (size_tmp > 0):
	head_tmp = thrift_api.register_read("head_reg", 0)
	out_value = thrift_api.register_read("ring_buffer", head_tmp)
	
	thrift_api.register_write("head_reg", 0, (head_tmp+1) % CAPACITY)
	thrift_api.register_write("buffer_size", 0, size_tmp-1)

	return out_value

    return None

def read_all_regs(thrift_api):
    head = thrift_api.register_read("head_reg", 0)
    tail = thrift_api.register_read("tail_reg", 0)
    sz = thrift_api.register_read("buffer_size", 0)
    buf_head = thrift_api.register_read("ring_buffer", head)
    buf_tail = thrift_api.register_read("ring_buffer", tail)

    return("head: %d,    tail: %d,    size: %d,    buffer[head]: %d,    buffer[tail]: %d\n" % (head, tail, sz, buf_head, buf_tail))
