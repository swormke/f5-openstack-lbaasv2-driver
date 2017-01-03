#! /usr/bin/env bash

# Copyright 2017 F5 Networks Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

set -ex

# Update the system and install required debian packages
ln -s /bin/bash /usr/local/bin/bash
apt-get update
apt-get -y install \
    vim \
    git \
    python-pip \
    python-pexpect \
    python-paramiko \
    nfs-common \
    ipmitool \
    python-protobuf \
    protobuf-compiler \
    gosu
apt-get clean
rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Pip install TLC requirements
pip install --upgrade pip
pip install argcomplete blessings configargparse prettytable

# Clone the toolsbase directory and setup the file system structure
git clone ${TOOLSBASE_REPO} ${TOOLSBASE_DIR}
mkdir ${TOOLSBASE_DIR}/independent/share
mkdir ${TOOLSBASE_DIR}/Ubuntu-10-x86_64/share
rm -rf ${TOOLSBASE_DIR}/independent/bin/*.pyc
rm -rf ${TOOLSBASE_DIR}/independent/bin/tlc_pb2.py
ln -s ${TOOLSBASE_DIR}/Ubuntu-10-x86_64 /tools

# Install TLC packages and binaries
git clone \
  -b ${TLC_BRANCH} \
  --single-branch \
  ${TLC_REPO} \
  ${TLC_DIR}

# Apply patches found for local changes to TLC on build server
# Should these patches be applied in the repo for real?
cp patches/* /tmp/
patch ${TLC_DIR}/tlc/install.sh /tmp/tlc_install.sh.patch
patch ${TOOLSBASE_DIR}/independent/create_softlinks /tmp/create_softlinks.patch
patch ${TLC_DIR}/vmware/install.sh /tmp/vmware_install.patch

# Install all of the TLC sub-components
cd ${TLC_DIR}
cd tlc && ./install.sh
cd ../tl3 && ./install.sh
cd ../vmware && ./install.sh
cd ../tlc_client && python setup.py install
cd ../bash_completion_feature && ./install_bash_completions.sh