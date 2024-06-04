from scapy.all import *
from scapy.contrib.mpls import MPLS
from scapy.layers.inet import IP, fragment
from scapy.layers.l2 import Ether


def sf():
    a = get_if_list()
    # print(a)
    b = get_if_hwaddr(a[1])
    # print(b)
    c = a[1]
    # print(c)

    def pkt_in_mem(p):
        # ethernet_encapsulation = p[Ether]
        if p.sprintf("%Ether.dst%") == "%s" % (b,) and MPLS in p:
            # print("match")
            mpls1 = MPLS()
            mpls2 = MPLS()
            mpls3 = MPLS()
            encap_count = 0
            try:
                mpls1 = p.getlayer(1)
                print(mpls1.label)
                mpls1.ttl -= 1
                encap_count = 1
            except:
                print("Not mpls header")
            try:
                mpls2 = p.getlayer(2)
                print(mpls2.label)
                mpls2.ttl -= 1
                encap_count = 2
            except:
                print("Not mpls header")
            try:
                mpls3 = p.getlayer(3)
                print(mpls3.label)
                mpls3.ttl -= 1
                encap_count = 3
            except:
                print("Not mpls header")

            pkt = p[IP]
            pkt.ttl -= 1
            pkt.flags = "DF"
            if mpls1.label == 103:
                ethernet_encapsulation = Ether(src="00:00:0a:00:00:01", dst="00:00:0a:00:00:03", type=0x8847)
            elif mpls1.label == 104:
                ethernet_encapsulation = Ether(src="00:00:0a:00:00:01", dst="00:00:0a:00:00:04", type=0x8847)
            elif mpls1.label == 105:
                ethernet_encapsulation = Ether(src="00:00:0a:00:00:01", dst="00:00:0a:00:00:05", type=0x8847)
            if encap_count == 1:
                forged_pkt = ethernet_encapsulation / mpls1
            elif encap_count == 2:
                forged_pkt = ethernet_encapsulation / MPLS(label=mpls1.label, cos=mpls1.cos, s=mpls1.s, ttl=mpls1.ttl) / mpls2
                # forged_pkt.show()
            elif encap_count == 3:
                forged_pkt = ethernet_encapsulation / MPLS(label=mpls1.label, cos=mpls1.cos, s=mpls1.s, ttl=mpls1.ttl) / MPLS(label=mpls2.label, cos=mpls2.cos, s=mpls2.s, ttl=mpls2.ttl) / mpls3
            try:
                # forged_pkt.show()
                sendp(forged_pkt, iface="%s" % (c,))
                # del p
                # del forged_pkt
            except:
                print("Too big")
                # del p
                # del forged_pkt
        # else:
            # print("Something else captured!")

    sniff(filter="mpls", prn=pkt_in_mem, iface="%s" % (c,))


def main():
    print("Starting SF")
    sf()


if __name__ == "__main__":
    main()
