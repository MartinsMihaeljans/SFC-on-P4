from p4utils.mininetlib.network_API import NetworkAPI

net = NetworkAPI()

net.setLogLevel('info')

net.setCompiler(p4rt=True)
net.execScript('python controller.py', reboot=True)

net.addP4RuntimeSwitch('s1')
net.setP4Source('s1', './p4src/s1.p4')
net.setP4CliInput('s1', './s1-commands.txt')

net.addP4RuntimeSwitch('s2')
net.setP4Source('s2', './p4src/s2.p4')
net.setP4CliInput('s2', './s2-commands.txt')

net.addP4RuntimeSwitch('s3')
net.setP4Source('s3', './p4src/s3.p4')
net.setP4CliInput('s3', './s3-commands.txt')

net.addP4RuntimeSwitch('s4')
net.setP4Source('s4', './p4src/s4.p4')
net.setP4CliInput('s4', './s4-commands.txt')

net.addP4RuntimeSwitch('s5')
net.setP4Source('s5', './p4src/s5.p4')
net.setP4CliInput('s5', './s5-commands.txt')

net.addHost('h1')
net.addHost('h2')
net.addHost('h3')
net.addHost('h4')
net.addHost('h5')

net.addLink('s1', 'h1')
net.addLink('s1', 's2')
net.addLink('s2', 'h2')
net.addLink('s2', 's3')
net.addLink('s3', 'h3')
net.addLink('s3', 's4')
net.addLink('s4', 'h4')
net.addLink('s4', 's5')
net.addLink('s5', 'h5')

net.setIntfPort('s1', 'h1', 1)
net.setIntfPort('h1', 's1', 0)
net.setIntfPort('s1', 's2', 2)
net.setIntfPort('s2', 's1', 1)
net.setIntfPort('s2', 'h2', 2)
net.setIntfPort('h2', 's2', 0)
net.setIntfPort('s2', 's3', 3)
net.setIntfPort('s3', 's2', 1)
net.setIntfPort('s3', 'h3', 2)
net.setIntfPort('h3', 's3', 0)
net.setIntfPort('s3', 's4', 3)
net.setIntfPort('s4', 's3', 1)
net.setIntfPort('s4', 'h4', 2)
net.setIntfPort('h4', 's4', 0)
net.setIntfPort('s4', 's5', 3)
net.setIntfPort('s5', 's4', 1)
net.setIntfPort('s5', 'h5', 2)
net.setIntfPort('h5', 's5', 0)

net.setBwAll(10)

net.l2()

net.enablePcapDumpAll()
net.enableLogAll()
net.enableCli()
net.startNetwork()
