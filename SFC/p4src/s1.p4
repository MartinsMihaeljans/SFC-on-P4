#include <core.p4>
#include <v1model.p4>
const bit<16> TYPE_IPV4 = 0x0800;
const bit<16> TYPE_MPLS = 0x8847;
const bit<8> TYPE_TCP = 0d06;
typedef bit<20> label_t;


header ethernet_t {
    bit<48> dstAddr;
    bit<48> srcAddr;
    bit<16> etherType;
}

header mpls_t1 {
    bit<20> label;
    bit<3> exp;
    bit<1> bos;
    bit<8> ttl;
}

header mpls_t2 {
    bit<20> label;
    bit<3> exp;
    bit<1> bos;
    bit<8> ttl;
}

header mpls_t3 {
    bit<20> label;
    bit<3> exp;
    bit<1> bos;
    bit<8> ttl;
}

header mpls_t4 {
    bit<20> label;
    bit<3> exp;
    bit<1> bos;
    bit<8> ttl;
}

header ipv4_t {
    bit<4>  version;
    bit<4>  ihl;
    bit<8>  diffserv;
    bit<16> totalLen;
    bit<16> identification;
    bit<3>  flags;
    bit<13> fragOffset;
    bit<8>  ttl;
    bit<8>  protocol;
    bit<16> hdrChecksum;
    bit<32> dstAddr;
    bit<32> srcAddr;
}

header tcp_t{
    bit<16> srcPort;
    bit<16> dstPort;
    bit<32> seqNo;
    bit<32> ackNo;
    bit<4>  dataOffset;
    bit<4>  res;
    bit<1>  cwr;
    bit<1>  ece;
    bit<1>  urg;
    bit<1>  ack;
    bit<1>  psh;
    bit<1>  rst;
    bit<1>  syn;
    bit<1>  fin;
    bit<16> window;
    bit<16> checksum;
    bit<16> urgentPtr;
}


struct my_metadata_t {
    int<8> mplsHeaderCount;
    int<8> path_t;
    int<8> tcpTrue;
}

struct headers_t {
    ethernet_t ethernet;
    mpls_t1 mpls1;
    mpls_t2 mpls2;
    mpls_t3 mpls3;
    mpls_t4 mpls4;
    ipv4_t ipv4;
    tcp_t tcp;
}

parser parser_impl (packet_in packet,
                    out headers_t hdr,
                    inout my_metadata_t my_metadata,
                    inout standard_metadata_t standard_metadata) {
    state start {
        my_metadata.mplsHeaderCount = 0;
        my_metadata.tcpTrue = 0;
        my_metadata.path_t = 1;
        transition parse_ethernet;
    }
    state parse_ethernet {
        packet.extract(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
            TYPE_MPLS: parse_mpls1;
            TYPE_IPV4: parse_ipv4;
            default: accept;
        }
    }
    state parse_mpls1 {
        packet.extract(hdr.mpls1);
        my_metadata.mplsHeaderCount = 1;
        transition select(hdr.mpls1.bos) {
            0: parse_mpls2;
            default: parse_ipv4;
        }
    }
    state parse_mpls2 {
        packet.extract(hdr.mpls2);
        my_metadata.mplsHeaderCount = 2;
        transition select(hdr.mpls2.bos) {
            0: parse_mpls3;
            default: parse_ipv4;
        }
    }
    state parse_mpls3 {
        packet.extract(hdr.mpls3);
        my_metadata.mplsHeaderCount = 3;
        transition select(hdr.mpls3.bos) {
            0: parse_mpls4;
            default: parse_ipv4;
        }
    }
    state parse_mpls4 {
        packet.extract(hdr.mpls4);
        my_metadata.mplsHeaderCount = 4;
        transition parse_ipv4;
    }
    state parse_ipv4 {
        packet.extract(hdr.ipv4);
        transition select(hdr.ipv4.protocol) {
            TYPE_TCP: parse_tcp;
            default: accept;
        }
    }
    state parse_tcp {
        packet.extract(hdr.tcp);
        my_metadata.tcpTrue = 1;
        transition accept;
    }
}

control deparser(packet_out packet, in headers_t hdr) {
    apply {
        packet.emit(hdr.ethernet);
        packet.emit(hdr.mpls1);
        packet.emit(hdr.mpls2);
        packet.emit(hdr.mpls3);
        packet.emit(hdr.mpls4);
        packet.emit(hdr.ipv4);
        packet.emit(hdr.tcp);
    }
}

control verify_checksum_control(inout headers_t hdr,
                                inout my_metadata_t my_metadata) {
    apply {
    }
}

control compute_checksum_control(inout headers_t hdr,
                                 inout my_metadata_t my_metadata) {
    apply {
        update_checksum(
                        hdr.ipv4.isValid(),
                        { hdr.ipv4.version,
                        hdr.ipv4.ihl,
                        hdr.ipv4.diffserv,
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

control ingress_control(inout headers_t hdr,
                        inout my_metadata_t my_metadata,
                        inout standard_metadata_t standard_metadata) {
    action drop() {
        mark_to_drop(standard_metadata);
    }

    action forward(bit<9> egress_port) {
        standard_metadata.egress_spec = egress_port;
    }
    action classify(int<8> path){
        my_metadata.path_t = path;
    }
    action encapsulate2(label_t label1, label_t label2, bit<48> dstAddrN){
        hdr.ethernet.etherType = TYPE_MPLS;

        hdr.mpls1.setValid();
        hdr.mpls1.label = label1;
        hdr.mpls1.ttl = hdr.ipv4.ttl - 1;
        hdr.mpls1.bos = 0;

        hdr.mpls2.setValid();
        hdr.mpls2.label = label2;
        hdr.mpls2.ttl = hdr.ipv4.ttl - 1;
        hdr.mpls2.bos = 1;

        hdr.ethernet.dstAddr = dstAddrN;
        hdr.ipv4.ttl = hdr.ipv4.ttl - 1;
        standard_metadata.egress_spec = 2;
    }
    action encapsulate3(label_t label1, label_t label2, label_t label3, bit<48> dstAddrN){
        hdr.ethernet.etherType = TYPE_MPLS;

        hdr.mpls1.setValid();
        hdr.mpls1.label = label1;
        hdr.mpls1.ttl = hdr.ipv4.ttl - 1;
        hdr.mpls1.bos = 0;

        hdr.mpls2.setValid();
        hdr.mpls2.label = label2;
        hdr.mpls2.ttl = hdr.ipv4.ttl - 1;
        hdr.mpls2.bos = 0;

        hdr.mpls3.setValid();
        hdr.mpls3.label = label3;
        hdr.mpls3.ttl = hdr.ipv4.ttl - 1;
        hdr.mpls3.bos = 1;

        hdr.ethernet.dstAddr = dstAddrN;
        hdr.ipv4.ttl = hdr.ipv4.ttl - 1;
        standard_metadata.egress_spec = 2;
    }
    action encapsulate4(label_t label1, label_t label2, label_t label3, label_t label4,  bit<48> dstAddrN){
        hdr.ethernet.etherType = TYPE_MPLS;

        hdr.mpls1.setValid();
        hdr.mpls1.label = label1;
        hdr.mpls1.ttl = hdr.ipv4.ttl - 1;
        hdr.mpls1.bos = 0;

        hdr.mpls2.setValid();
        hdr.mpls2.label = label2;
        hdr.mpls2.ttl = hdr.ipv4.ttl - 1;
        hdr.mpls2.bos = 0;

        hdr.mpls3.setValid();
        hdr.mpls3.label = label3;
        hdr.mpls3.ttl = hdr.ipv4.ttl - 1;
        hdr.mpls3.bos = 0;

        hdr.mpls4.setValid();
        hdr.mpls4.label = label4;
        hdr.mpls4.ttl = hdr.ipv4.ttl - 1;
        hdr.mpls4.bos = 1;

        hdr.ethernet.dstAddr = dstAddrN;
        hdr.ipv4.ttl = hdr.ipv4.ttl - 1;
        standard_metadata.egress_spec = 2;
    }

    table sfc {
        key = {
            hdr.tcp.dstPort: exact;
        }
        actions = {
            classify;
            NoAction;
        }
    }

    table sfp {
        key = {
            my_metadata.path_t: exact;
        }
        actions = {
            encapsulate2;
            encapsulate3;
            encapsulate4;
            NoAction;
        }
    }

    table dmac {
        key = {
            hdr.ethernet.dstAddr: exact;
        }

        actions = {
            forward;
            NoAction;
        }
        size = 320;
        default_action = NoAction;
    }

    apply {
        if (my_metadata.tcpTrue == 1){
            sfc.apply();
            sfp.apply();
            if (my_metadata.path_t == 1){
                dmac.apply();
            }
        }
        else {
            dmac.apply();
        }
    }
}

control egress_control(inout headers_t hdr,
                        inout my_metadata_t my_metadata,
                        inout standard_metadata_t standard_metadata) {
    apply {
    }
}

V1Switch(parser_impl(),
         verify_checksum_control(),
         ingress_control(),
         egress_control(),
         compute_checksum_control(),
         deparser()) main;
