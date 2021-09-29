function [cur_speedR,cur_speedL,cur_incl] = readTreadmillPacket(t)
%readTreadmillPacket reads in a packet from the treadmill, 32 bytes long,
%and parses out the belt speeds and incline angle.
%disp(get(t,'BytesAvailable'))

%First: read through the buffer to get freshest data (throw away chunks of 32 bytes)
while~(get(t,'BytesAvailable')>1)
    %nop: wait until data is available
end
while(get(t,'BytesAvailable')>1)
    %disp(get(t,'BytesAvailable')) %This returns 32 or 0
    fread(t,1,'uint8'); %format byte
    speeds=fread(t,4,'int16');
    cur_incl=fread(t,1,'int16');
    fread(t,21,'uint8'); %21 padding bytes (should be all 0)
    pause(.025); %This pause is needed because the treadmill interface 
    %reports no data available for a short time after a read, even if the buffer is not truly empty
    %Since true samples come at a rate of about 15Hz, this eventually
    %depletes the buffer, at the cost of adding 25ms of processing to each
    %read of the buffer.
end
%We exit the loop once there is no data available even after waiting 25ms
%This suggests the last packet read is the last packet available
%We don't wait until a new one comes in, to avoid unnecessary waits

cur_speedR=speeds(1);
cur_speedL=speeds(2);

end

