#!/bin/bash

declare SHELDON_SELF='./src';
declare SHELDON_ROOT='.';
. 'src/bootstrap.sh';

shd_log_error error
shd_log_warning warning
shd_log_info info
shd_log_verbose verbose
shd_log_debug debug
