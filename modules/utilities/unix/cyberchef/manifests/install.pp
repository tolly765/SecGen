class cyberchef::install {
  file {
   '/opt/cyberchef':
    ensure => 'directory',
    source => 'puppet:///modules/cyberchef/cyberchef_www',
    recurse => 'remote',
    mode  => '0744', # Use 0700 if it is sensitive
  }

}
