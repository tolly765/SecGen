class phish_victim_bot::install {
  require java

  $secgen_parameters = secgen_functions::get_parameters($::base64_inputs_file)
  $port = $secgen_parameters['port'][0]

  $strings_to_leak = $secgen_parameters['strings_to_leak']
  $leaked_filenames = $secgen_parameters['leaked_filenames']
  $usernames = $secgen_parameters['usernames']
  $phish_victim_bot_configs = $secgen_parameters['phish_victim_bot_configs']

  if $usernames {
    $usernames.each |$index, $username| {
      # Create user
      user { $username:
        ensure     => present,
        home       => "/home/$username",
        managehome => true,
      } ->
      file { "/home/$username/.user.properties":
        ensure   => present,
        owner    => 'root',
        group    => 'root',
        mode     => '0600',
        content => $phish_victim_bot_config[index],
      }
      # run on each boot via cron
      cron { "$username-mail":
        command     => "sleep 60 && cd /home/$username && java -cp mail.jar:. MailReader  &",
        special     => 'reboot',
        user        => $username,
      }

      ::secgen_functions::leak_files { "$username-mail-file-leak":
        storage_directory => "/home/$username",
        leaked_filenames  => $leaked_filenames,
        strings_to_leak   => $strings_to_leak[$index],
        owner             => $username,
        mode              => '0600',
        leaked_from       => "phish_victim_bot",
      }

    }
  }


  file { '/opt/mailreader/':
    ensure   => directory,
    owner    => 'root',
    group    => 'root',
    mode     => '0755',
  }->
  file { '/opt/mailreader/MailReader.class':
    ensure   => present,
    owner    => 'root',
    group    => 'root',
    mode     => '0755',
    source => 'puppet:///modules/phish_victim_bot/MailReader.class',
  }->
  file { '/opt/mailreader/mail.jar':
    ensure   => present,
    owner    => 'root',
    group    => 'root',
    mode     => '0755',
    source => 'puppet:///modules/phish_victim_bot/mail.jar',
  }


}
