require 'sinatra/base'
require 'sinatra/config_file'
require 'grit'
require 'stringex'
require 'json'

class HubDraft < Sinatra::Base

  register Sinatra::ConfigFile
  config_file 'config/config.yml'

  post "/:id" do
    if params[:id] == settings.secret
      publish JSON.parse(params[:payload])
    end
  end

  private

  def publish(payload)
    setup_dirs

    grit = Grit::Git.new("#{settings.base_dir}/grit")

    repo_dir = "#{settings.base_dir}/repo"
    Dir.chdir(repo_dir) do

      grit.clone({:quiet => false, :verbose => true, :progress => true, :timeout => false}, settings.repo_address, ".")

      repo = Grit::Repo.new(".")

      file_path = "./_posts/#{Time.now.strftime('%Y-%m-%d')}-#{payload["name"].to_url}.md"

      File.open(file_path, "w") do |f|
        f.write payload["content"]
      end

      repo.add file_path

      repo.commit_index("test commit!")
    end
  end

  def setup_dirs
    Dir.mkdir("#{settings.base_dir}") unless Dir.exists? "#{settings.base_dir}"
    Dir.mkdir("#{settings.base_dir}/grit") unless Dir.exists? "#{settings.base_dir}/grit"
    Dir.mkdir("#{settings.base_dir}/repo") unless Dir.exists? "#{settings.base_dir}/repo"
  end
end