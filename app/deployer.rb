require 'script_executor'
require 'highline/import'
require 'optparse'
require 'fileutils'
require 'net/smtp'

options = {:target => nil}

executor = ScriptExecutor.new

##password = ask("Enter your password:  ") do |ch| ch.readline=true & ch.echo = "*" end

OptionParser.new do |opts|
  opts.banner = "Usage: #{__FILE__} [command] [options]"

  opts.on("-c", "--coreid NAME", String, "Enter the Core ID") { |t| options[:coreid] = t }
  opts.on("-t", "--target NAME", String, "Override the default target, NAME can be a full path or a fragment of a target file name") { |t| options[:target] = t }
  opts.on("-an", "--app_name NAME", String, "Enter the application name") { |a| options[:app_name] = a }
  opts.on("-a", "--appver NAME", String, "Enter the App version you want to populate") { |t| options[:appVer] = t }
  opts.on("-C","--command x,y,z", Array, "Enter the command you wish to run. Options to the command need to be entered like this 'gen_mod,a,l,w'") do |command|
  opts.on("-rc", "--revision_control NAME", String, "Enter the revision control system") { |r| options[:revision_control] = r }
    options[:command] = command
  end
  opts.on("-D", "--designsync NAME", String, "Enter the DesignSync Vault location") { |t| options[:designsync] = t }
  opts.on("-p", "--password NAME", String, "") { |t| options[:password] = t }
  opts.on("-h", "--help", "Show this message") { puts opts; exit }

end.parse!

coreid = options[:coreid]
target1 = options[:target]
app_name = options[:app_name]
appVer = options[:appVer]
command = options[:command]
command = command.to_s.gsub(/\"/, ' ').gsub(/[\[\]]/, ' ').gsub(/,/, ' ')
designsync = options[:designsync]
password = options[:password]
rc = options[:revision_control]

puts "Revision control selected is #{rc}"

time = Time.now.getutc.to_i

coreid = coreid.downcase

server_array = ['acv0169.nxdi.us-cdc01.nxp.com']


server = server_array.sample

if "#{app_name}" == "c55fx_nvm_tester" && "#{rc}" == "DesignSync"
  path = "tool_data/rgen_work_v3"
elsif "#{app_name}" == "c55fx_nvm_tester" && "#{rc}" == "Git"
 path = "c55fx_nvm_tester"
elsif "#{app_name}"  == "c90tfs_nvm_tester"
 path = "c90tfs_nvm_tester"
elsif "#{app_name}" == "ISC" && "#{rc}" == "DesignSync"
 path = ""
elsif "#{app_name}" == "c55fx_nvm_tester" && "#{rc}" == "Git" 
path = "c55fx_nvm_tester"
end

if "#{rc}" == "DesignSync" && "#{app_name}" != "ISC"
    fetch_command = "rgen fetch #{app_name} -v #{appVer} -o ."
    elsif "#{rc}" == "Git"
    fetch_command = "git clone --branch #{appVer} #{designsync}"
    elsif "#{app_name}" == "ISC"
    fetch_command = "dssc setvault sync://sync-15088:15088/Projects/common_tester_blocks/blocks/isc/tool_data/rgen . & dssc pop -rec -uni -get -force -ver #{appVer} ." 
end

gemfile =  "/proj/pet_rgen_web/source_v2/#{appVer}_dir_#{time}/#{path}/Gemfile"
binstubs = "/proj/pet_rgen_web/source_v2/#{appVer}_dir_#{time}/#{path}/lbin"
gempath = "/home/#{coreid}/.origen/gems"

server_info = {
  :remote => true,
  :domain => "#{server}",
  :user => coreid,
  :password => password
}
   
result = executor.execute server_info.merge(:capture_output => false, :supress_output => true) do
  %Q(
    echo ####################################################################################################################################################
    echo Configuration Setup Begin
    echo ####################################################################################################################################################"
    echo Current Shell:  $SHELL
    echo Current Path:  $PATH
    echo Checking BSUB version...
    bsub -V
    echo Executing command on server: hostname
    echo ####################################################################################################################################################
    echo Configuration Setup end 
    echo ####################################################################################################################################################
    echo 
    echo ###### These are the commands that will be run --in order ######    

    cd /proj/pet_rgen_web/source_v2/

    mkdir #{appVer}_dir_#{time}

    cd #{appVer}_dir_#{time}

    #{fetch_command}
    
    cd "#{path}"
    
    bundle install --gemfile #{gemfile} --binstubs #{binstubs} --path #{gempath}

    origen -v 
   
    origen -t #{target1}

    origen #{command}
     
    trans -P /proj/pet_rgen_web/source_v2/#{appVer}_dir_#{time}/#{path}/output/

    chown #{coreid}:nvmpet  /proj/pet_rgen_web/source_v2/#{appVer}_dir_#{time} -R
    
    chmod 775 /proj/pet_rgen_web/source_v2/#{appVer}_dir_#{time} -R
    
    echo "###################################################################"
  )
end

## BACKUP Code ##
#
#    cp ../pk_sinatra/.bundle tool_data/rgen_work_v3/.bundle -R
#    sed -i 's/b00000/#{coreid}/g' .bundle/config
#    sed -i 's/v2.3.0_rc.0/#{appVer}_dir/g' .bundle/config
#    coreid = ask("Enter your Core-ID:  ") do |ch| ch.readline=true & ch.echo=true end
#    password = ask("Enter your password:  ") do |ch| ch.readline=true & ch.echo = "*" end
#    target1=   ask("Enter RGen Target: ") do |ch| ch.readline=true & ch.echo = true end
#    appVer =  ask("Enter 1T App Version: ") do |ch| ch.readline=true & ch.echo = true end
#    dssc setvault sync://sync-15088:15088/Projects/common_tester_blocks/blocks/C55Fx_NVM_tester .

	G = File.open("/proj/pet_rgen_web/source_v2/#{appVer}_dir_#{time}/#{path}/trans.log", "r")
    contents = G.read
    puts contents[0..9]
    str = contents[0..9]
    
    string = %Q(NVM 1T Module #{appVer} Successfully Generated \n TransWeb Keyword: #{str})
    string2 = %Q(#{str})

      # Generic method to send an email, alternatively use one of the
      # pre-defined mail types using the other methods.
      def send_email(options = {})
        options = { server:     'remotesmtp.freescale.net',
                    port:       25,
                    from:       '',
                    from_alias: '',
                    subject:    '',
                    body:       '',
                    to:         ''
                  }.merge(options)

        # Force to an array
        to = options[:to].respond_to?('each') ? options[:to] : [options[:to]]

        # Convert any user objects to an email
        to = to.map { |obj| obj.respond_to?('email') ? obj.email : obj }

        to.uniq.each do |addr|
          msg = <<END_OF_MESSAGE
From: #{options[:from_alias]} <#{options[:from]}>
To: #{addr}
Subject: #{options[:subject]}

#{options[:body]}

END_OF_MESSAGE

          begin
            # Exceptions raised here will be caught by rescue clause
            Net::SMTP.start(options[:server], options[:port]) do |smtp|
              smtp.send_message msg, options[:from], addr
            end
          rescue
            warn "Email not able to be sent to address '#{addr}'"
          end
        end
      end

body2 = <<END2

Hello #{coreid},

The Module #{appVer} you requested has been successfully generated.

The generated output has been compressed and transcended to you for your convenience. Please use the TransWeb URL below to download the generated output.

TransWeb URL:  http://transweb.freescale.net/index.cgi?go=KEYWORD&KEYWORD=#{string2}

Thanks,
RGen Core Team.

END2

puts "Sending Email..."
send_email(:from => "#{coreid}@freescale.com", :from_alias => "#{coreid}@freescale.com", :to => "#{coreid}@freescale.com", :subject => "Module #{appVer} Successfully Generated", :body => "#{body2}")
