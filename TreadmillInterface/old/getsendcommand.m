function [packet] = getsendcommand(vR,vL,acR,acL,incline)
%function to take belt commands and create TCP packet to treadmill
%   Inputs must be integers, units are mm/s mm/s^2 degrees
%
%WDA 12/16/2015


maxAcc=3000;%maximum writable acceleration
maxVel=6500;%maximum writable belt speed
minVel=-6500;%min belt speed
maxInc=1500;%maximum inclincation angle

% Range checks:
if acR>maxAcc
    warning(['Requested right-belt acceleration >' num2str(maxAcc) 'mm/s^2. Using' num2str(maxAcc) 'mm/s^2'])
    acR=maxAcc;
end
if acL>maxAcc
    warning(['Requested left-belt acceleration >' num2str(maxAcc) 'mm/s^2. Using' num2str(maxAcc) 'mm/s^2'])
    acL=maxAcc;
end
if incline<0
    incline=0;
end
if incline>maxInc
    incline=maxInc;
end
if vR<minVel
    vR=minVel;
end
if vR>maxVel
    vR=maxVel;
end
if vL<minVel
    vL=minVel;
end
if vL>maxVel
    vL=maxVel;
end

% Formating packet payload to treadmill specification
format=0;
speedRR=0;
speedLL=0;

accRR=0;
accLL=0;

aux=int16toBytes(round([vR vL speedRR speedLL acR acL accRR accLL incline]));
actualData=reshape(aux',size(aux,1)*2,1);
secCheck=255-actualData; %Redundant data to avoid errors in comm
padding=zeros(1,27);

packet=[format actualData' secCheck' padding];


end

