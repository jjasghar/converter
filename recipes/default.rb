include_recipe 'apt'
include_recipe 'nfs'


package 'vim'

directory "/home/ubuntu/share" do
  owner "ubuntu"
  group "ubuntu"
  mode "0755"
  action :create
end

downloader = search(:node, "recipe:downloader")
downloader.each do |node|
  mount "/home/ubuntu/share" do
    device "#{node["ipaddress"]}:/home/ubuntu/share/"
    fstype "nfs"
    options "rw"
  end
  Chef::Log.info("#{node["name"]} has IP address #{node["ipaddress"]}")
end

apt_repository 'ffmpeg' do
  uri          'ppa:kirillshkrogalev/ffmpeg-next'
  distribution node['lsb']['codename']
end

%w{ffmpeg}.each do |pkg|
  package pkg do
    action [:install]
  end
end

directory "/home/ubuntu/tmp" do
  owner "ubuntu"
  group "ubuntu"
  mode "0755"
  action :create
end

execute "copy the mp4 out" do
  cwd "/home/ubuntu/share"
  command "cp toycomercial001.mp4 ../tmp/"
  action :run
end

execute "cut out a clip to a pngs" do
  cwd "/home/ubuntu/tmp"
  command "ffmpeg -ss 00:00:00.000 -i toycomercial001.mp4 -pix_fmt rgb24 -r 10 -s 320x240 -t 00:00:10.000 output.gif"
  action :run
end

package 'lighttpd'

execute "copy the output.gif to the web directory" do
  cwd "/home/ubuntu/tmp"
  command "cp output.gif /var/www/"
  action :run
end

execute "delete index.html" do
  cwd "/var/www/"
  command "rm index.lighttpd.html"
  action :run
end

template "/var/www/index.html" do
  source "index.html.erb"
  owner "root"
  group "root"
  mode "0644"
end
