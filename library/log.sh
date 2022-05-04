#!/bin/bash
#
# ArchW build script
# by tarkh (c) 2021

touch ARCHW_INSTALL.log
sudo chmod 777 ARCHW_INSTALL.log
exec 2> >(tee -ia ARCHW_INSTALL.log)
