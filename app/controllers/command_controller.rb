class CommandController < ApplicationController
helper_method :run_remote_command

  layout "origen"
#  before_filter :set_tab

  def set_tab
    @tab = :command
  end

  def show_data
  @application ||= Application.all
     @command = params[:command]
     @app_name = params[:app_name]
     a = @application.where(name: @app_name)
     @vault = a[0].url
     @application_version = params[:application_version]
     @target= params[:target]
     @username = params[:username]
     @password = params[:password]
     @revision_control = params[:revision_control]
  end


  def run_remote_command
   Spawnling.new(:argv => "running remote command") do
     require 'open3'
     spawn_time = Time.now.getutc.to_i
     outfile = "/proj/pet_rgen_web/source_v2/#{@username}_#{@app_name}_#{@revision_control}_#{spawn_time}_logfile.txt"
     logger.info("I feel sleepy...")
# SPLIT THIS SO THAT THE OPTIONS GET PASSED TO ORIGEN?? DISCUSS WITH STEPHEN ON HOW TO IMPLEMENT!!!
     cmd = "ruby #{Rails.root}/app/deployer.rb --coreid #{@username} --target #{@target} --appver #{@application_version} --command #{@command} --designsync #{@vault} --password #{@password} --app_name #{@app_name} --revision_control #{@revision_control}" 
     Open3.popen3(cmd) do |stdin, stdout, stderr, t|
        stdin.close
        err_thr = Thread.new { IO.copy_stream(stderr, outfile) }
        puts "Reading STDOUT"
        IO.copy_stream(stdout, outfile)
        err_thr.join
       end
     end
      logger.info("Time to wake up!")
   end
end
