#!/bin/bash
set -o pipefail

HERE="$(dirname $0)"
BASH_TAP_ROOT="$HERE"
source "$HERE/bash-tap-bootstrap"

EXE=$HERE/../spvcf
D=/tmp/spVCFTests
rm -rf $D
mkdir -p $D

plan tests 20

pigz -dc "$HERE/data/small.vcf.gz" > $D/small.vcf
"$EXE" encode -o $D/small.spvcf $D/small.vcf
is "$?" "0" "filename I/O"
is "$(cat $D/small.spvcf | wc -c)" "36986142" "filename I/O output size"

pigz -dc "$HERE/data/small.vcf.gz" | "$EXE" encode -q > $D/small.spvcf
is "$?" "0" "piped I/O"
is "$(cat $D/small.spvcf | wc -c)" "36986142" "piped I/O output size"

"$EXE" decode -o $D/small.roundtrip.vcf $D/small.spvcf
is "$?" "0" "decode"
is "$(cat $D/small.roundtrip.vcf | wc -c)" "54007969" "roundtrip decode"

is "$(cat $D/small.vcf | grep -v ^# | sha256sum)" \
   "$(cat $D/small.roundtrip.vcf | grep -v ^# | sha256sum)" \
   "roundtrip fidelity"

is "$(egrep -o "spVCF_checkpointPOS=[0-9]+" $D/small.spvcf | uniq | cut -f2 -d = | tr '\n' ' ')" \
   "5030088 5085728 5142746 5225415 5232998 5243839 5252753 5264502 5274001 " \
   "checkpoint positions"

"$EXE" encode -S -p 500 -o $D/small.squeezed.spvcf $D/small.vcf
is "$?" "0" "squeeze"
is "$(cat $D/small.squeezed.spvcf | wc -c)" "17453976" "squeezed output size"

"$EXE" decode -q -o $D/small.squeezed.roundtrip.vcf $D/small.squeezed.spvcf
is "$?" "0" "squeezed roundtrip decode"
is "$(cat $D/small.vcf | grep -v ^# | sed -r 's/(\t[^:]+):[^\t]+/\1/g' | sha256sum)" \
   "$(cat $D/small.squeezed.roundtrip.vcf | grep -v ^# | sed -r 's/(\t[^:]+):[^\t]+/\1/g' | sha256sum)" \
   "squeezed roundtrip GT fidelity"

"$EXE" squeeze -q -o $D/small.squeezed_only.vcf $D/small.vcf
is "$?" "0" "squeeze (only)"
is "$(cat $D/small.squeezed_only.vcf | grep -v ^# | sha256sum)" \
   "$(cat $D/small.squeezed.roundtrip.vcf | grep -v ^# | sha256sum)" \
   "squeeze (only) fidelity"

is "$(egrep -o "spVCF_checkpointPOS=[0-9]+" $D/small.squeezed.spvcf | uniq | cut -f2 -d = | tr '\n' ' ')" \
   "5030088 5053371 5085752 5111059 5142907 5219436 5225476 5229291 5233041 5238611 5244009 5248275 5252854 5257548 5265256 5271818 " \
   "squeezed checkpoint positions"

bgzip -c $D/small.squeezed.spvcf > $D/small.squeezed.spvcf.gz
tabix $D/small.squeezed.spvcf.gz
"$EXE" tabix -o $D/small.squeezed.slice.spvcf $D/small.squeezed.spvcf.gz chr21:5143000-5219900
is "$?" "0" "tabix slice"

is "$(egrep -o "spVCF_checkpointPOS=[0-9]+" $D/small.squeezed.slice.spvcf | uniq -c | tr -d ' ' | tr '\n' ' ')" \
   "249spVCF_checkpointPOS=5143363 20spVCF_checkpointPOS=5219436 " \
   "slice checkpoints"

"$EXE" decode $D/small.squeezed.slice.spvcf > $D/small.squeezed.slice.vcf
is "$?" "0" "decode tabix slice"

bgzip -c $D/small.squeezed.roundtrip.vcf > $D/small.squeezed.roundtrip.vcf.gz
tabix $D/small.squeezed.roundtrip.vcf.gz
tabix $D/small.squeezed.roundtrip.vcf.gz chr21:5143000-5219900 > $D/small.squeezed.roundtrip.slice.vcf
is "$(cat $D/small.squeezed.slice.vcf | grep -v ^# | sha256sum)" \
   "$(cat $D/small.squeezed.roundtrip.slice.vcf | grep -v ^# | sha256sum)" \
   "slice fidelity"

"$EXE" tabix -o $D/small.squeezed.slice_chr21.spvcf $D/small.squeezed.spvcf.gz chr21
is "$(cat $D/small.squeezed.slice_chr21.spvcf | sha256sum)" \
   "$(cat $D/small.squeezed.spvcf | sha256sum)" \
   "chromosome slice"

rm -rf $D
