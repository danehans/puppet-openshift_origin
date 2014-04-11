# Copyright 2014 Red Hat, Inc., All rights reserved.
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
#
class openshift_origin::update_conf_files {
  file { 'network-scripts':
    ensure  => present,
    path    => "/etc/sysconfig/network-scripts/ifcfg-${::openshift_origin::conf_node_external_eth_dev}",
    content => template('openshift_origin/sysconfig_conf.erb'),
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
  }

  file { 'dhcpclient':
    ensure  => present,
    path    => "/etc/dhcp/dhclient-${::openshift_origin::conf_node_external_eth_dev}.conf",
    content => template('openshift_origin/dhclient_conf.erb'),
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
  }

  file { '/etc/resolv.conf':
    ensure  => present,
    path    => '/etc/resolv.conf',
    content => template('openshift_origin/resolv_conf.erb'),
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
  }
}
