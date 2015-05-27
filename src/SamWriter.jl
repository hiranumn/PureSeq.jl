export SamWriter, writeHeader, writeRead

#=
USAGE:
sw = SamWriter(STDOUT, ReferenceContigs_hg38)
writeRead(sw, 100, 16)
writeRead(sw, 500000000, 16)
=#

type Sam_Writer
    #a output stream object to write to
    Outstream
    contigs::ReferenceContigs
    cur_ref::Int64
end

#constructor for sam_Writer. 
#Automatically writes the header as it is instantiated
function SamWriter(output_stream, contigs)
    sw = Sam_Writer(output_stream, contigs, 1)
    writeHeader(sw)
    sw
end

function writeHeader(sw::Sam_Writer)
    write(sw.Outstream, "@HD\tVN:1.0\tSO:coordinate\n")
    for j in 1:sw.contigs.count
        name = sw.contigs.names[j]
        size = sw.contigs.sizes[j]
        write(sw.Outstream, "@SQ\tSN:$(name)\tLN:$(size)\n")
    end
    write(sw.Outstream, "@PG\tID:PureSeq\tPN:PureSeq\n")
end

function writeRead(sw::Sam_Writer, POS::Int64, FLAG::Int64; MAPQ::Int64=15, LENGTH::Int64=0)

    #Figure out the ref_name
    while POS > sw.contigs.offsets[sw.cur_ref]+sw.contigs.sizes[sw.cur_ref]
        sw.cur_ref += 1
    end
    
    #What we are writing out
    QNAME = "PureSeq"
    FLAG = FLAG
    RNAME = sw.contigs.names[sw.cur_ref]
    POS = POS-sw.contigs.offsets[sw.cur_ref]
    if POS < 0
        write(STDERR, "ERROR: reads need to be fed in order")
        return -1 
    end
    
    MAPQ = MAPQ
    if LENGTH == 0
        CIGAR = "*"
    else
        CIGAR = "$(LENGTH)M"
    end
    RNEXT = "*"
    PNEXT = 0
    TLEN = 0
    SEQ = "*"
    QUAL = "*"
    
    output = "$(QNAME)\t$(FLAG)\t$(RNAME)\t$(POS)\t$(MAPQ)\t$(CIGAR)\t$(RNEXT)\t$(PNEXT)\t$(TLEN)\t$(SEQ)\t$(QUAL)\n"
    write(sw.Outstream, output)
end
