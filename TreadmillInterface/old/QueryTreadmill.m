function [vR,vL,incline] = QueryTreadmill(t)
%function to ask the treadmill for current belt speeds
%   Input: tcp port the treadmill is connected to
%   Outputs: right, left belt speeds mm/s, and incline angle

%read through the buffer to get the most recent data (throw away chunks of 32 bytes)
while(get(t,'BytesAvailable')>1)
    fread(t,32);
end

%now parse the most recent set of 32 bytes
read_format=fread(t,1,'uint8');
speeds=fread(t,4,'int16');
vR=speeds(1);
vL=speeds(2);
incline=fread(t,1,'int16');
padding=fread(t,21,'uint8');

end

