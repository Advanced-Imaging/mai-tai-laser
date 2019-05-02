function [WAV_now,SWID,PUMPpower,output_power,MODELOCK]=MaiTai_Scan_Fcn(port_name,lambda,slit_width,pump_power)

%Limit the upper and lower output lasering power to be used in section %%Run the experiment:
limit_heat= 3; %upper bound  in Watt
limit_not_lasering= 0.05; %lower bound in Watt
limit_burn_camera= 0.65; %that won't burn the camera this is dependent on the user ND filter and NOT THE LASER!!~!!~
trying_counter=0; % this is the number of tries to get output from the laser
 fprintf(port_name,'SHUTTER 0');
output_power=0; % initilzing it the 0 in order to do at least one scan in the while look below
no_saftey = @(output_power) output_power < limit_not_lasering || output_power> limit_burn_camera;           
         while no_saftey(output_power)
                 fprintf(port_name,'SHUTTER?');
                if str2double(fscanf(port_name, '%s'))==0
                    disp('Shutter is close')
                end
            fprintf(port_name,['WAV ',num2str(lambda)]); %changing slit position
            message=['changing the wavelegth for the: ',num2str(trying_counter+1),'# time and now 1 minute waiting till it moves',newline];
            disp(message)
            pause(30);
            for verify=1:3
              fprintf(port_name,['CONT:SWID ',num2str(slit_width)]); %changing slit width
            % Narrow the slit width for CW, < 200 no output, > 200 falls back to mode lock
            pause(5)
            fprintf(port_name,['PLASer:POWer ',num2str(pump_power)]); %changing pump power
            pause(5)
            end
            for verify=1:2
            fprintf(port_name, 'WAV?'); %checking it reached its destination
            WAV_now=fscanf(port_name);
            WAV_now=str2double(WAV_now(1:end-3));
            fprintf(port_name,'CONT:SWID?'); %checking it reached its destination
            SWID=str2double(fscanf(port_name));
            fprintf(port_name,'READ:PLASer:POWer?'); %checking it reached its destination
            PUMPpower=fscanf(port_name);
            PUMPpower=str2double(PUMPpower(1:end-2)); % in Watt
            fprintf(port_name,'READ:POWer?'); %checking the output power to see we're not over
            output_power=fscanf(port_name); % in Watt
            output_power=str2double(output_power(1:end-2));
            message=[newline,'For try:',num2str(trying_counter+1),newline,'The pump power: ',num2str(PUMPpower),newline,'The SWID: ',num2str(SWID),newline,'output_power: ',num2str(output_power),'************************',newline];
            disp(message)
            pause(5)
            end
            pause(1)
            %cases where you not lasering so the methods is slowly open the
            %width
            if trying_counter>=1 && trying_counter<4 && output_power < limit_not_lasering
                pump_power=pump_power+0.1;
                fprintf(port_name,['PLASer:POWer ',num2str(pump_power)]); %changing pump power
            end
            if trying_counter>3 && output_power < limit_not_lasering
                slit_width=slit_width+15;
                fprintf(port_name,['CONT:SWID ',num2str(slit_width)])
            end
            %cases where you might burn the camera
            %so the methods is slowly lower the PUMP POWER
            if trying_counter>3 && output_power > limit_burn_camera
                fprintf(port_name,['CONT:SWID ',num2str(slit_width)])
            end
            if trying_counter>4 && output_power > limit_burn_camera
                pump_power=pump_power-0.2;
               fprintf(port_name,['PLASer:POWer ',num2str(pump_power)]); %changing pump power
            end
            %Sometimes we need to change the WAV to make the defualt
            %paprametrers again of the MAITAI and then change it back
                if trying_counter==2
                fprintf(port_name,['WAV ',num2str(850)]); %changing slit position
                disp('wainting 10')
                pause(10)
                fprintf(port_name,['WAV ',num2str(lambda)]); %changing slit position
                disp('wainting 20')
                pause(20)
                end
                
            trying_counter=trying_counter+1;
                        if output_power > limit_heat || trying_counter>5
                            %Sometimes the MAI TAI is piece of SH**T
                         disp('shut down the laser due to high output power')
                        fprintf(port_name,'SHUTTER 0');
                        pause(2);
                        message=[newline,'output_power > limit_heat',num2str(output_power > limit_heat),newline,'trying_counter>4:',num2str(trying_counter>4)];
                        sendMailFunc('imaging@mail.huji.ac.il', 'lab123456', 'imaging@mail.huji.ac.il', 'MaiTai', ['Mai Tai was closed',message])
                        fprintf(port_name,'OFF');
                        fclose(port_name)
                        end    
         end
        
                    
     fprintf(port_name, 'CONT:MLEN?');
    MODELOCK=str2double(fscanf(port_name));
    if MODELOCK==1
        fprintf(port_name, 'CONT:MLEN 0');
    end

end
