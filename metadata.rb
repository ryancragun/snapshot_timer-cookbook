name             'snapshot_timer'
maintainer       'Ryan Cragun'
maintainer_email 'ryan@rightscale.com'
license          'Apache 2.0'
description      'Installs/Configures snapshot_timer'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.1.0'

supports "ubuntu"
supports "centos"
supports "redhat"

depends "rightscale"

recipe "snapshot_timer::default", "default"
recipe "snapshot_timer::install_plugin", "Installs snapshot-timer collectd plugin"

attribute "snapshot_timer/lineage",
  :display_name => "snapshot_timer lineage",
  :description => "A RightScale block storage lineage name to time",
  :required => "required",
  :default => "",
  :recipes => [
    "snapshot_timer::install_plugin"
  ]

attribute "snapshot_timer/interval",
  :display_name => "snapshot_timer interval",
  :description => "Interval in which the plugin should query for the snapshot",
  :required => "optional",
  :default => "1800",
  :recipes => [
    "snapshot_timer::install_plugin"
  ]