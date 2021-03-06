version 1.0

task spvcf_encode {
    input {
        File vcf_gz
        Boolean multithread = false
        String release = "v1.1.0"
        Int cpu = if multithread then 8 else 4
    }

    parameter_meta {
        vcf_gz: "stream"
    }

    command <<<
        set -euxo pipefail

        apt-get -qq update && apt-get install -y wget tabix
        wget -nv https://github.com/mlin/spVCF/releases/download/~{release}/spvcf
        chmod +x spvcf

        threads_arg=""
        if [ "~{multithread}" == "true" ]; then
            threads_arg="--threads 4"
        fi

        nm=$(basename "~{vcf_gz}" .vcf.gz)
        nm="${nm}.spvcf.gz"
        mkdir out
        bgzip -dc "~{vcf_gz}" | ./spvcf encode $threads_arg | bgzip -@ 4 > "out/${nm}"
    >>>

    runtime {
        docker: "ubuntu:20.04"
        cpu: cpu
        memory: "~{cpu} GB"
        disks: "local-disk ~{ceil(size(vcf_gz,'GB'))} SSD"
    }

    output {
        File spvcf_gz = glob("out/*.gz")[0]
    }
}

task spvcf_decode {
    input {
        File spvcf_gz
        String release = "v1.1.0"
    }

    parameter_meta {
        spvcf_gz: "stream"
    }

    command <<<
        set -euxo pipefail

        apt-get -qq update && apt-get install -y wget tabix
        wget -nv https://github.com/mlin/spVCF/releases/download/~{release}/spvcf
        chmod +x spvcf

        nm=$(basename "~{spvcf_gz}" .spvcf.gz)
        nm="${nm}.vcf.gz"
        mkdir out
        bgzip -dc "~{spvcf_gz}" | ./spvcf decode | bgzip -@ 4 > "out/${nm}"
    >>>

    runtime {
        docker: "ubuntu:20.04"
        cpu: 4
        memory: "4 GB"
        disks: "local-disk ~{10*ceil(size(spvcf_gz,'GB'))} SSD"
    }

    output {
        File vcf_gz = glob("out/*.gz")[0]
    }
}

task spvcf_squeeze {
    input {
        File vcf_gz
        Boolean multithread = false
        String release = "v1.1.0"
        Int cpu = if multithread then 8 else 4
    }

    parameter_meta {
        vcf_gz: "stream"
    }

    command <<<
        set -euxo pipefail

        apt-get -qq update && apt-get install -y wget tabix
        wget -nv https://github.com/mlin/spVCF/releases/download/~{release}/spvcf
        chmod +x spvcf

        threads_arg=""
        if [ "~{multithread}" == "true" ]; then
            threads_arg="--threads 4"
        fi

        nm=$(basename "~{vcf_gz}" .vcf.gz)
        nm="${nm}.squeeze.vcf.gz"
        mkdir out
        bgzip -dc "~{vcf_gz}" | ./spvcf squeeze $threads_arg | bgzip -@ 4 > "out/${nm}"
    >>>

    runtime {
        docker: "ubuntu:20.04"
        cpu: cpu
        memory: "~{cpu} GB"
        disks: "local-disk ~{ceil(size(vcf_gz,'GB'))} SSD"
    }

    output {
        File squeeze_vcf_gz = glob("out/*.gz")[0]
    }
}
