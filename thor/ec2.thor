require 'yaml'
require 'open-uri'

#
# Utility methods for accessing and manipulating 
# Amazon ec2
#
class Ec2 < Thor

  desc("get_ip", "Get the current IP (dynamic) of this computer, as seen from the internet")
  def get_ip
    ip = 'oops'
    open('http://ip.gilmation.com:80', :http_basic_authentication=>['admin', '2jozf8xDsYpa']) do |f|
      ip = f.gets
    end
    return ip || 'hmm, not everything went to plan'
  end

  desc("open_ip_port_group", "Open an specific port / ip / group combination on EC2")
  def open_ip_port_group(ip, port, group)
    group ||= 'default'
    exec_ec2_command('ec2auth', ip, port, group)
  end
  
  desc("open_ip_port", "Open an specific port / ip combination on EC2")
  def open_ip_port(ip, port)
    open_ip_port_group(ip, port, nil)
  end

  desc("open_port", "Open a specific port in the default group with this machine's ip")
  def open_port(port)
    open_ip_port_group(get_ip, port, nil)
  end

  desc("open_port_group", "Open a specific port in the given group")
  def open_port_group(port, group)
    open_ip_port_group(get_ip, port, group)
  end
  
  desc("close_ip_port_group", "Close an specific port / ip / group combination on EC2")
  def close_ip_port_group(ip, port, group)
    group ||= 'default'
    exec_ec2_command('ec2revoke', ip, port, group)
  end

  desc("close_ip_port", "Close an specific port / ip combination on EC2")
  def close_ip_port(ip, port)
    close_ip_port_group(ip, port, nil)
  end

  desc("close_port", "Close a specific port in the default group with this machine's ip")
  def close_port(port)
    close_ip_port(get_ip, port)
  end

  desc("close_port_group", "Close a specific port in the given group")
  def close_port_group(port, group)
    close_ip_port(get_ip, port, group)
  end

  private 
    def exec_ec2_command(command, ip, port, group)
      system("#{command} #{group} -p #{port} -s #{ip}/32")
      system("ec2-describe-group")
    end
end
