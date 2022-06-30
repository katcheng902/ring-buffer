import sys

from p4utils.utils.topology import Topology
from p4utils.utils.sswitch_API import SimpleSwitchAPI
from p4utils.utils.thrift_API import ThriftAPI

import control_ring_buffer
import random

class RoutingController(object):

    def __init__(self):
        self.topo = Topology(db="topology.db")
        self.controllers = {}
        self.init()

    def init(self):
        self.connect_to_switches()
        self.reset_states()
        self.set_table_defaults()

    # Establishes a connection with the simple switch `thrift` server 
    # using the `SimpleSwitchAPI` object 
    # and saves those objects in the `self.controllers` dictionary. 
    # This dictionary has the form of: `{'sw_name' : SimpleSwitchAPI()}`.
    def connect_to_switches(self):
        for p4switch in self.topo.get_p4switches():
            thrift_port = self.topo.get_thrift_port(p4switch)
            self.controllers[p4switch] = SimpleSwitchAPI(thrift_port)

    # Iterates over the `self.controllers` object 
    # and runs the `reset_state` function which empties the state 
    # (registers, tables, etc) for every switch.
    def reset_states(self):
        [controller.reset_state() for controller in self.controllers.values()]

    # For each P4 switch, it sets the default action for `dmac` table
    def set_table_defaults(self):
        for controller in self.controllers.values():
            controller.table_set_default("dmac", "drop", [])

    def route(self):
        for sw_name, controller in self.controllers.items():
            if sw_name == "s1":
                controller.table_add("dmac", "forward", ["00:00:0a:00:00:01"], ["1"])
                controller.table_add("dmac", "drop", ["00:00:0a:00:00:02"], [])

                controller.table_add("tail_table", "set_first_tail_to_one", ["0x0"], [])
                controller.table_add("tail_table", "inc_tail", ["0x1"], [])

                controller.table_add("size_table", "NoAction", ["0x8"], [])

                controller.table_add("dequeue_table", "NoAction", ["0x0"], [])
    
    def main(self):
	self.route()

	#using the control plane API example
        for p4switch in self.topo.get_p4switches():
            thrift_port = self.topo.get_thrift_port(p4switch)
            thrift_ip = "0.0.0.0"
	    thrift = ThriftAPI(thrift_port, thrift_ip, "none")
            print("INITIAL: " +  control_ring_buffer.read_all_regs(thrift))

            for _ in range(5):
                mode = str(random.randint(0, 1))
                op = str(random.randint(0, 1))
                rand_client = random.randint(1,9)
                client_ip = "00000000" + "00000000" + "00001010" + "00000000" + "00000000" + "0000" + str(format(rand_client, 'b'))

                enq_value = int(mode+op+client_ip, 2)

                control_ring_buffer.enqueue(thrift, enq_value)
		print("ENQUEUE: " + control_ring_buffer.read_all_regs(thrift))
               
                if (rand_client % 3 == 0):
                    out_value = control_ring_buffer.dequeue(thrift)
                    print("DEQUEUE: " + str(out_value))
                    print("\t " + control_ring_buffer.read_all_regs(thrift))

            out_value = control_ring_buffer.dequeue(thrift)
            print("DEQUEUE: " + str(out_value))
            print("\t " + control_ring_buffer.read_all_regs(thrift))

if __name__ == "__main__":
    controller = RoutingController().main()

