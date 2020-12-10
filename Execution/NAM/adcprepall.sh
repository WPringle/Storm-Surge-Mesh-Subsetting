#!/bin/bash
# run adcprep
nc=XXX
./adcprep << EOF
$nc
1
fort.14
EOF
./adcprep << EOF
$nc
2
EOF
