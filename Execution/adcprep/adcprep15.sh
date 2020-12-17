#!/bin/bash
# run adcprep
nc=XXX
./adcprep << EOF
$nc
4
fort.14
fort.15
EOF
