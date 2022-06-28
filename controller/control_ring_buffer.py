#from p4utils.utils.topology import Topology
#from p4utils.utils.sswitch_API import SimpleSwitchAPI
import p4utils
import sys

CAPACITY = 8

def enqueue(in_value):
    tail_tmp = register_read(tail_reg, 0)
    register_write(tail_reg, 0, (tail_tmp+1) % CAPACITY)

    register_write(ring_buffer, (tail_tmp+1) % CAPACITY, in_value)

    size_tmp = register_read(buffer_size, 0)
    register_write(buffer_size, 0, min(size_tmp+1, CAPACITY))


def dequeue():
    size_tmp = register_read(buffer_size, 0)

    if (size_tmp > 0):
	head_tmp = register_read(head_reg, 0)
	out_value = register_read(ring_buffer, head_tmp)
	
	register_write(head_reg, 0, (head+1) % CAPACITY)
	register_write(buffer_size, 0, size_tmp-1)

	return out_value

    return None

