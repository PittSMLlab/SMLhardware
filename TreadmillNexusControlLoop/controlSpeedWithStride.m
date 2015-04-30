
function [RstepTime, LstepTime, commSendTime] = controlSpeedWithStride(velL,velR,masterLeg,FzThreshold)

%Defaukt threshold
if nargin<4
    FzThreshold=30; %Newtons (30 is minimum for noise not to be an issue)
elseif FzThreshold<30
    disp('Warning: Fz threshold too low to be robust to noise, using 30N instead')
end
%Check that velL and velR are of equal length
if length(velL)~=length(velR)
    disp('Velocity vectors of different length')
    return
end
   

%Initialize nexus & treadmill comm
[MyClient] = openNexusIface();
[FrameNo,TimeStamp,SubjectCount,LabeledMarkerCount,UnlabeledMarkerCount,DeviceCount,DeviceOutputCount] = NexusGetFrame(MyClient);
t = openTreadmillComm();



%Intiate timing
baseTime=clock;
curTime=baseTime;
lastCommandTime=baseTime;

%Initiate variables
new_stanceL=false;
new_stanceR=false;
phase=0; %0= Double Support, 1 = single L support, 2= single R support
strideCount=0;
stepCount=0;
RstepTime(length(velL))=TimeStamp;
LstepTime(length(velL))=TimeStamp;
lastStride=0;
commSendTime=zeros(length(velL),6);

%Initiate GUI with stop button
MessageBox = msgbox( ['Stop Treadmill Loop ']);

%Main loop
while ishandle( MessageBox )
  %newSpeed
  drawnow;
  lastFrameTime=curTime;
  curTime=clock;
  elapsedFrameTime=etime(curTime,lastFrameTime);
  old_stanceL=new_stanceL;
  old_stanceR=new_stanceR;

%Read frame, update necessary structures
[FrameNo,TimeStamp,SubjectCount,LabeledMarkerCount,UnlabeledMarkerCount,DeviceCount,DeviceOutputCount] = NexusGetFrame(MyClient);

%Assuming there is only 1 subject, and that I care about a marker called MarkerA (e.g. Subject=Wand)
Fz_R = MyClient.GetDeviceOutputValue( 'Treadmill Right', 'Fz' );
Fz_L = MyClient.GetDeviceOutputValue( 'Treadmill Left', 'Fz' );


new_stanceL=Fz_L.Value<-FzThreshold; %20N Threshold
new_stanceR=Fz_R.Value<-FzThreshold;

LHS=new_stanceL && ~old_stanceL;
RHS=new_stanceR && ~old_stanceR;
LTO=~new_stanceL && old_stanceL;
RTO=~new_stanceR && old_stanceR;

switch phase
    case 0 %DS
        if RTO
            phase=1;
        elseif LTO
            phase=2;
        end
    case 1 %single L
        if RHS
            phase=0;
            stepCount=stepCount+1;
            if masterLeg==1
                strideCount=strideCount+1;
            end
            RstepTime(stepCount) = TimeStamp;
        end
    case 2%single R
        if LHS
            phase=0;
            stepCount=stepCount+1;
            if masterLeg==2
                strideCount=strideCount+1;
            end
            LstepTime(stepCount) = TimeStamp;
        end
end


%Every now & then, send an action
auxTime=clock;
elapsedCommTime=etime(auxTime,lastCommandTime);
if (elapsedCommTime>0.2)&&(strideCount<=length(velL))&&(lastStride~=strideCount) %Orders are at least 200ms apart, only sent if new stride detected and total amount of strides does not exceed max.
    [payload] = getPayload(velR(strideCount),velL(strideCount),1000,1000,0);
    sendTreadmillPacket(payload,t);
    lastCommandTime=clock;
    commSendTime(strideCount,:)=clock;
    lastStride=strideCount;
    disp(['Packet sent, speed = ' num2str(velL(strideCount))])
end

if strideCount>=length(velL)
    disp('Reached the end of programmed speed profile, no further commands will be sent')
    if exist('MessageBox','var')
        delete(MessageBox)
    end
    break; %While loop
end
end %While, when STOP button is pressed
%End communications
closeNexusIface(MyClient);
closeTreadmillComm(t);