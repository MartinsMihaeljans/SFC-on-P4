#include <core.p4>
#include <v1model.p4>
const bit<16> TYPE_IPV4 = 0x0800;
const bit<16> TYPE_MPLS = 0x8847;
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

struct my_metadata_t {
    int<8> mplsHeaderCount;
    label_t outermost_label;
}

struct headers_t {
    ethernet_t ethernet;
    mpls_t1 mpls1;
    mpls_t2 mpls2;
    mpls_t3 mpls3;
    mpls_t4 mpls4;
    ipv4_t ipv4;
}

parser parser_impl (packet_in packet,
                    out headers_t hdr,
                    inout my_metadata_t my_metadata,
                    inout standard_metadata_t standard_metadata) {
    state start {
        my_metadata.mplsHeaderCount = 0;
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
        my_metadata.outermost_label = hdr.mpls1.label;
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

    action forward2(bit<9> egress_port) {
        standard_metadata.egress_spec = egress_port;
        hdr.mpls1.ttl = hdr.ipv4.ttl - 1;
        hdr.mpls2.ttl = hdr.ipv4.ttl - 1;
        hdr.mpls3.ttl = hdr.ipv4.ttl - 1;
        hdr.mpls4.ttl = hdr.ipv4.ttl - 1;
        hdr.ipv4.ttl = hdr.ipv4.ttl - 1;
    }

    table sfp {
        key = {
            my_metadata.outermost_label: exact;
        }
        actions = {
            forward2;
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
        if (my_metadata.mplsHeaderCount != 0){
            sfp.apply();
        }
        else {
            dmac.apply();
        }
    }
}

control egress_control(inout headers_t hdr,
                        inout my_metadata_t my_metadata,
                        inout standard_metadata_t standard_metadata) {
    action rm(){
        hdr.mpls1.setInvalid();
    }
    apply {
        if (standard_metadata.egress_port == 2) {
            if (my_metadata.mplsHeaderCount != 0) {
                rm();
            }
        } else {

        }
    }
}

V1Switch(parser_impl(),
         verify_checksum_control(),
         ingress_control(),
         egress_control(),
         compute_checksum_control(),
         deparser()) main;
