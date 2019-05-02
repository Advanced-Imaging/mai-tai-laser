clear 
close all
%% MAI TAI CONTROL WITH MATLAB
%******************* WARNING****************
%Should before verify the following:
% 1)thought the GUI  explore the parameters before changing them
%   directly so you will know what are the maximum and minimum values of
%   each of the following parameters
% 2)using a powermeter relating the slit width ('SWID' command) and pump power
%   ('PLASer:POWer' )to the output power
% 3)using a spectrometer make a data of your own between the slit position
%   ('SLIT' command)
% 4) Mai Tai has several ways of lasering. between 720-920 it can pulse and
%   reach high power where 690(lowest possible wavelength)-720 or 920-1040
%   (longest possible wavelength) the output power is very low and
%   therefore you be treated differtly in case of scanning wavelength and
%   changing the slit positions
%******************* BUT READ THE ABOVE****************
laser=serial('COM4','BaudRate', 115200,'DataBits', 8,...
'Parity', 'none',...
'StopBits', 1.0,...
'FlowControl', 'software',...
'Terminator', {'LF','LF'}); % creating a serial connection with port COM4
% you may change the port number according to what the laser is connected
% to computer.
%the values of ''BaudRate'' should be either 115200 OR 9600 depending on
%what the MaiTai is able to connect.
%YOU MAY FIND THE VALUES IN THE GUI CONNECTION TIME

            Fs=44100; % frames of song per second
            [HOME,Fs] = audioread('C:\Users\Owner\Desktop\Memory Effect in mouse brain\VoiceText.mp3');
% Parameters of Sample and Acquisition 

%This look up table is based by pre-measurements ,
%it is always recommended to do so before starting your Mai Tai scan
ScanParameters.wavelengths=[690,800,900,1040];
ScanParameters.slit_width=[440,200,315,765];

% Narrow the slit width for CW, < 200 no output, > 200 falls back to mode lock
ScanParameters.pump_power=[12.6,10.3,11.0,13];


staying_all_nigth = input(prompt_saftey);
if staying_all_nigth==0
staying_all_nigth=false
else 
staying_all_nigth=true
end
clear prompt_decorr prompt_sample_size prompt_saftey

disp('The laser will be  open now')
fopen(laser) % opening the conection to the mai tai DO NOT FORGET TO PUT fclose(laser)
pause(1)
% Start laser from the standby (this does NOT start lasing) 
fprintf(laser, 'ON');
 
% Wait until the laser is warmed up. 
while 1
    pause(2);
    fprintf(laser, 'read:pctwarmedup?'); 
    answer = fscanf(laser, '%s')
    
    if isequal(answer, num2str(100, '%.2f%%'))
        break;
    end
end
%Now the laser is warm and you can start the laser itself. 
fprintf(laser, 'ON'); 
 
while 1 
    pause(2);
    fprintf(laser, 'read:plaser:pcurrent?');
    answer = fscanf(laser, '%s')
    %% Here you just wait for the pump lasers to produce working output so you get pulses
    if str2double(answer(1:(end-1))) > 97
        break;
    end
end
% Wait until the lasing is stable for sure
pause(10);
disp('Laser is ready')
%% Saving current values of the MAI TAI laser
% Memorise width of the slit at the current wavelength
fprintf(laser, 'CONT:SWID?');
initial_use_slit_width = str2double(fscanf(laser, '%s'));
% Memorise position of the slit at the current wavelength
fprintf(laser, 'CONT:SLIT?');
slit_start = str2double(fscanf(laser, '%s'));
% Memorise the current wavelength itself
fprintf(laser, 'WAV?');
WAV_pre_scan = fscanf(laser, '%s');
% disp('WAITING FOR PRESSING ENTER TO TURN IT ON')
% pause 
% OPTIONAL IF NOT THE LASER IS TURNING OFF AFTER 5 sec
%YOU MAY NEED TO SET WATCHDOG to 0 which is the way of saftey that
%mai tai has to turn off itself after NN second in fprintf(laser,'TIMEr:WATChdog NN')
%setting it back to 0 as below disable this it enable you to work with the
%laser

if staying_all_nigth
    fprintf(laser,'TIMEr:WATChdog 3600') % 1 hour saftey
else
    fprintf(laser,'TIMEr:WATChdog 0') % no saftey stop
    disp('no saftey stop')
end
fprintf(laser, 'ON'); 
% Taking pre measurments picure with 690 nm

fprintf(laser,'WAV 690');
fprintf(laser,['PLASer:POWer ',num2str(ScanParameters.pump_power(1))]); %changing pump power
fprintf(laser,['CONT:SWID ',num2str(ScanParameters.slit_width(1))]);
fprintf(laser, 'WAV?');
WAV_start = fscanf(laser, '%s');
pause(5)
% Turn off mode-locking
fprintf(laser, 'CONT:MLEN 0');
%%
fprintf(laser, 'CONT:MLEN 0');
fprintf(laser,'READ:PLASer:POWer?'); %checking it reached its destination
PUMPpower=fscanf(laser);
PUMPpower=str2double(PUMPpower(1:end-2)); % in Wat
fprintf(laser,'READ:POWer?'); %checking the output power to see we're not over
output_power=fscanf(laser); % in Watt
output_power=str2double(output_power(1:end-2));

%% Open the shutter
fprintf(laser, 'SHUT 1');
pause(1)
fprintf(laser,'SHUTTER?');
if str2double(fscanf(laser, '%s'))==1
    disp('Shutter is open')
end


%% Run the experiment!
%This look up table is based by pre-measurements ,
%it is always recommended to do so before starting your Mai Tai scan
% ScanParameters.wavelengths=[690,720,777,803,832,864,900,940,980,1040];
% ScanParameters.slit_width=[500,260,200,200,200,832,300,500,700,775];
% ScanParameters.slit_position=[948,1700,2834,3246,3658,4030,4482,4758,5228,5745];
% ScanParameters.pump_power=[13,13,10.9,10.9,12.2,12.4,13,13,13,13];


%run expirament, for each point, for each lambda take three measurments
number_of_lambdas=length(ScanParameters.wavelengths);
    %%Loop over the wav's
    while wav_counter<number_of_lambdas+1
        lambda = ScanParameters.wavelengths(wav_counter);
        slit_width=ScanParameters.slit_width(wav_counter);
        pump_power=ScanParameters.pump_power(wav_counter);
         [WAV_now,SWID,PUMPpower,output_power,MODELOCK]=MaiTai_Scan_Fcn(laser,lambda,slit_width,pump_power);
        TXT2DISP=['Now with slit width: ',num2str(SWID),' , Lambda: ',num2str(WAV_now),' nm',newline...
            ,'pump power: ',num2str(PUMPpower),'Watts ',newline,' and the output power is: ',num2str(output_power*1e3),'mW',newline];
        disp(TXT2DISP)
            fprintf(laser, 'SHUT 1');
            pause(1)
            fprintf(laser,'SHUTTER?');
            if str2double(fscanf(laser, '%s'))==1
                disp('Shutter is open')
            end
            pause(1)

        disp('Next one is comming');pause(1);
         wav_counter=wav_counter+1

        fprintf(laser,'SHUTTER 0');
    end
        pause(3)


%%
 disp('shut down the laser')
pause(2)
fprintf(laser,'SHUTTER 0');
pause(10)
fprintf(laser,'OFF');
fclose(laser)
laser
pause(10)
delete(laser)
clear laser
disp('delete and clear the laser obj')
