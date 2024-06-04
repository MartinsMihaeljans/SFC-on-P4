from p4utils.utils.helper import load_topo
from p4utils.utils.sswitch_p4runtime_API import SimpleSwitchP4RuntimeAPI


topo = load_topo('topology.json')
controllers = {}

for switch, data in topo.get_p4switches().items():
    controllers[switch] = SimpleSwitchP4RuntimeAPI(data['device_id'], data['grpc_port'],
                                                   p4rt_path=data['p4rt_path'], json_path=data['json_path'])

controller1 = controllers['s1']

controller1.table_add('sfc', 'classify', ['5566'], ['2'])
controller1.table_add('sfc', 'classify', ['5567'], ['3'])
controller1.table_add('sfc', 'classify', ['5568'], ['4'])

controller1.table_add('sfp', 'encapsulate2', ['2'], ['103', '105', '00:00:0a:00:00:03'])
controller1.table_add('sfp', 'encapsulate3', ['3'], ['102', '104', '105', '00:00:0a:00:00:02'])
controller1.table_add('sfp', 'encapsulate4', ['4'], ['102', '103', '104', '105', '00:00:0a:00:00:02'])

controller1.table_add('dmac', 'forward', ['00:00:0a:00:00:01'], ['1'])
controller1.table_add('dmac', 'forward', ['00:00:0a:00:00:02'], ['2'])
controller1.table_add('dmac', 'forward', ['00:00:0a:00:00:03'], ['2'])
controller1.table_add('dmac', 'forward', ['00:00:0a:00:00:04'], ['2'])
controller1.table_add('dmac', 'forward', ['00:00:0a:00:00:05'], ['2'])

controller2 = controllers['s2']

controller2.table_add('sfp', 'forward2', ['102'], ['2'])
controller2.table_add('sfp', 'forward2', ['103'], ['3'])
controller2.table_add('sfp', 'forward2', ['104'], ['3'])

controller2.table_add('dmac', 'forward', ['00:00:0a:00:00:01'], ['1'])
controller2.table_add('dmac', 'forward', ['00:00:0a:00:00:02'], ['2'])
controller2.table_add('dmac', 'forward', ['00:00:0a:00:00:03'], ['3'])
controller2.table_add('dmac', 'forward', ['00:00:0a:00:00:04'], ['3'])
controller2.table_add('dmac', 'forward', ['00:00:0a:00:00:05'], ['3'])

controller3 = controllers['s3']

controller3.table_add('sfp', 'forward2', ['103'], ['2'])
controller3.table_add('sfp', 'forward2', ['104'], ['3'])
controller3.table_add('sfp', 'forward2', ['105'], ['3'])

controller3.table_add('dmac', 'forward', ['00:00:0a:00:00:01'], ['1'])
controller3.table_add('dmac', 'forward', ['00:00:0a:00:00:02'], ['1'])
controller3.table_add('dmac', 'forward', ['00:00:0a:00:00:03'], ['2'])
controller3.table_add('dmac', 'forward', ['00:00:0a:00:00:04'], ['3'])
controller3.table_add('dmac', 'forward', ['00:00:0a:00:00:05'], ['3'])

controller4 = controllers['s4']

controller4.table_add('sfp', 'forward2', ['104'], ['2'])
controller4.table_add('sfp', 'forward2', ['105'], ['3'])

controller4.table_add('dmac', 'forward', ['00:00:0a:00:00:01'], ['1'])
controller4.table_add('dmac', 'forward', ['00:00:0a:00:00:02'], ['1'])
controller4.table_add('dmac', 'forward', ['00:00:0a:00:00:03'], ['1'])
controller4.table_add('dmac', 'forward', ['00:00:0a:00:00:04'], ['2'])
controller4.table_add('dmac', 'forward', ['00:00:0a:00:00:05'], ['3'])

controller5 = controllers['s5']

controller5.table_add('sfp', 'forward2', ['105'], ['2'])

controller5.table_add('dmac', 'forward', ['00:00:0a:00:00:01'], ['1'])
controller5.table_add('dmac', 'forward', ['00:00:0a:00:00:02'], ['1'])
controller5.table_add('dmac', 'forward', ['00:00:0a:00:00:03'], ['1'])
controller5.table_add('dmac', 'forward', ['00:00:0a:00:00:04'], ['1'])
controller5.table_add('dmac', 'forward', ['00:00:0a:00:00:05'], ['2'])
