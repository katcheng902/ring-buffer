from p4utils.utils.topology import Topology
from p4utils.utils.sswitch_API import SimpleSwitchAPI
import sys

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

    # Create forwarding rules for the dmac table
    def route(self):
        for sw_name, controller in self.controllers.items():
            if sw_name == "s1":
                # table_add function: create a rule in "dmac" table, the key is the dmac address
                # the action is "forward", and the parameter is the output port id
                # E.g., when receiving a packet to "00:00:0a:00:00:01", "forward" the packet to "1" port.
                controller.table_add("dmac", "enqueue_buffer", ["00:00:0a:00:00:01"], ["01"])
                controller.table_add("dmac", "forward", ["00:00:0a:00:00:02"], ["2"])

    def main(self):
        self.route()


if __name__ == "__main__":
    controller = RoutingController().main()

