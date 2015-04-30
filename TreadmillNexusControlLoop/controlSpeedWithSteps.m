
function [RTOTime, LTOTime, RHSTime, LHSTime, commSendTime, commSendFrame] = controlSpeedWithSteps(velL,velR,FzThreshold)
%This function takes two vectors of speeds (one for each treadmill belt)
%and succesively updates the belt speed upon ipsilateral Toe-Off
%The function only updates the belts alternatively, i.e., a single belt
%speed cannot be updated twice without the other being updated
%The first value for velL and velR is the initial desired speed, and new
%speeds will be sent for the following N-1 steps, where N is the length of
%velL

%Default threshold
if nargin<3
    FzThreshold=30; %Newtons (30 is minimum for noise not to be an issue)
elseif FzThreshold<30
    disp('Warning: Fz threshold too low to be robust to noise, using 30N instead')
end

%Check that velL and velR are of equal length
N=length(velL);
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
LstepCount=0;
RstepCount=0;
RTOTime(N)=TimeStamp;
LTOTime(N)=TimeStamp;
RHSTime(N)=TimeStamp;
LHSTime(N)=TimeStamp;
commSendTime=zeros(2*N-1,6);
commSendFrame=zeros(2*N-1,1);
stepFlag=0;

%Send first speed command
[payload] = getPayload(velL(1),velR(1),1000,1000,0);
sendTreadmillPacket(payload,t);
commSendTime(1,:)=clock;
disp(['Packet sent, Lspeed = ' num2str(velL(LstepCount+1)) ', Rspeed = ' num2str(velR(RstepCount+1))])


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
Fz_R = MyClient.GetDeviceOutputValue( 'Right Treadmill', 'Fz' );
Fz_L = MyClient.GetDeviceOutputValue( 'Left Treadmill', 'Fz' );


new_stanceL=Fz_L.Value<-FzThreshold; %20N Threshold
new_stanceR=Fz_R.Value<-FzThreshold;

LHS=new_stanceL && ~old_stanceL;
RHS=new_stanceR && ~old_stanceR;
LTO=~new_stanceL && old_stanceL;
RTO=~new_stanceR && old_stanceR;

%Maquina de estados: 0 = initial, 1 = single L, 2= single R, 3 = DS from
%single L, 4= DS from single R
switch phase
    case 0 %DS, only initial phase
        if RTO
            phase=1; %Go to single L
            RstepCount=RstepCount+1;
            RTOTime(RstepCount) = TimeStamp;
            stepFlag=1; %R step
        elseif LTO %Go to single R
            phase=2;
            LstepCount=LstepCount+1;
            LTOTime(LstepCount) = TimeStamp;
            stepFlag=2; %L step
        end
    case 1 %single L
        if RHS
            phase=3;
            disp(['Right step #' num2str(LstepCount)])
            RHSTime(RstepCount) = TimeStamp;
        end
    case 2 %single R
        if LHS
            phase=4;
            disp(['Left step #' num2str(LstepCount)])
            LHSTime(LstepCount) = TimeStamp;
        end
    case 3 %DS, coming from single L
        if LTO
            phase = 2; %To single R
            LstepCount=LstepCount+1;
            LTOTime(LstepCount) = TimeStamp;
            stepFlag=2; %Left step
        end
    case 4 %DS, coming from single R
        if RTO
            phase =1; %To single L
            RstepCount=RstepCount+1;
            RTOTime(RstepCount) = TimeStamp;
            stepFlag=1; %R step
        end
end


%Every now & then, send an action
auxTime=clock;
elapsedCommTime=etime(auxTime,lastCommandTime);
if (elapsedCommTime>0.2)&&(LstepCount<N)&&(RstepCount<N)&&(stepFlag>0) %Orders are at least 200ms apart, only sent if a new step was detected, and max steps has not been exceeded.
    [payload] = getPayload(velR(RstepCount+1),velL(LstepCount+1),1000,1000,0);
    sendTreadmillPacket(payload,t);
    lastCommandTime=clock;
    commSendTime(LstepCount+RstepCount+1,:)=clock;
    commSendFrame(LstepCount+RstepCount+1)=FrameNo;
    stepFlag=0;
    disp(['Packet sent, Lspeed = ' num2str(velL(LstepCount+1)) ', Rspeed = ' num2str(velR(RstepCount+1))])
end

if (LstepCount>=N) || (RstepCount>=N)
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