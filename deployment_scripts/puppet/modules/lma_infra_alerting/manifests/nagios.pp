#    Copyright 2015 Mirantis, Inc.
#
#    Licensed under the Apache License, Version 2.0 (the "License"); you may
#    not use this file except in compliance with the License. You may obtain
#    a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#    WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#    License for the specific language governing permissions and limitations
#    under the License.
#
# == Class: lma_infra_alerting::nagios
#
# Configure Nagios server with LMA requirements
#

class lma_infra_alerting::nagios (
  $http_user = $lma_infra_alerting::params::nagios_http_user,
  $http_password = $lma_infra_alerting::params::nagios_http_password,
  $http_port = $lma_infra_alerting::params::nagios_http_port,
) inherits lma_infra_alerting::params {

  include nagios::params

  class { '::nagios':
    # Mandatory parameters for LMA requirements
    accept_passive_service_checks => $lma_infra_alerting::params::nagios_accept_passive_service_checks,
    enable_notifications          => $lma_infra_alerting::params::nagios_enable_notifications,
    check_service_freshness       => $lma_infra_alerting::params::nagios_check_service_freshness,
    check_external_commands       => $lma_infra_alerting::params::nagios_check_external_commands,
    command_check_interval        => $lma_infra_alerting::params::nagios_command_check_interval,
    interval_length               => $lma_infra_alerting::params::nagios_interval_length,

    # Not required to set these parameters but either usefull or better for LMA
    accept_passive_host_checks    => $lma_infra_alerting::params::nagios_accept_passive_host_checks,
    use_syslog                    => $lma_infra_alerting::params::nagios_use_syslog,
    enable_flap_detection         => $lma_infra_alerting::params::nagios_enable_flap_detection,
    debug_level                   => $lma_infra_alerting::params::nagios_debug_level,
    process_performance_data      => $lma_infra_alerting::params::nagios_process_performance_data,
  }

  class { '::nagios::cgi':
    user      => $http_user,
    password  => $http_password,
    http_port => $http_port,
    require   => Class[nagios],
  }

  $cron_bin = $lma_infra_alerting::params::update_configuration_script
  file { $cron_bin:
    ensure => file,
    source => 'puppet:///modules/lma_infra_alerting/update-lma-configuration',
    mode   => '0750',
  }

  $nagios_config_dir = $nagios::params::config_dir
  $prefix = $lma_infra_alerting::params::nagios_config_filename_prefix
  cron { 'update lma infra alerting':
    ensure   => present,
    command  => "/usr/bin/flock -n /tmp/lma.lock -c \"${cron_bin} lma_infrastructure_alerting\"",
    minute   => '*',
    hour     => '*',
    month    => '*',
    monthday => '*',
    require  => File[$cron_bin],
  }
}