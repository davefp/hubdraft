require 'sinatra/base'
require 'sinatra/config_file'
require 'grit'
require 'stringex'
require 'json'
require 'tmpdir'

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
    Grit.debug = true

    Dir.mktmpdir 'hubdraft' do |root_dir|
      setup_dirs root_dir

      grit = Grit::Git.new("#{root_dir}/grit")

      repo_dir = "#{root_dir}/repo"
      Dir.chdir(repo_dir) do

        grit.clone({:quiet => false, :verbose => true, :progress => true, :timeout => false}, settings.repo_address, ".")

        repo = Grit::Repo.new(".")

        file_path = "./_posts/#{Time.now.strftime('%Y-%m-%d')}-#{payload["name"].to_url}.md"

        File.open(file_path, "w") do |f|
          f.write payload["content"]
        end

        repo.add file_path

        repo.commit_index("test commit!")
        repo.git.push({}, 'origin', 'master')
      end
    end
  end

  def setup_dirs(root_dir)
    Dir.mkdir("#{root_dir}/grit")
    Dir.mkdir("#{root_dir}/repo")
  end
end