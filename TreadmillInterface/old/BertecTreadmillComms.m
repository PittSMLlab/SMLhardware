%Example script for how to send and receive belt speeds with a Bertec
%Treadmill
%
%This script will create a tcp link with the treadmill, send a belt speed
%command of 1 m/s @ 2 m/s^2, wait, ask the treadmill for data, then stop
%the belts.
%
%Prerequisites:
%
%-Treadmill control panel is open, functioning
%-Treadmill control panel has "remote tcp control" enabled
%-Ensure no one is on the treadmill, don't want anyone to get hurt
%
%
%WDA 12/16/2015

clear
clc

%open a tcp connection on port 4000
HOST = 'localhost';
PORT = 4000;

t = tcpip(HOST,PORT);
set(t,'InputBufferSize',32,'OutputBufferSize',64);
fopen(t);%now we can communicate with the treadmill

%send a speed command
%first get the packet, the treadmill understands integers only
%units must be mm/s mm/s^2 degrees
[speedcommand]=getsendcommand(1000,1000,1000,1000,0);

fwrite(t,speedcommand,'uint8');%send the command

%wait a little bit
pause(4);

%ask what the belt speeds are
[vr,vl,incline] = QueryTreadmill(t)
%you'll notice the output of the query is innacurate, there are 2 buffers
%in the tcp receive stream, one is the tcp itself, the other is inside the
%treadmill PLCs. Matlab empties the tcp buffer every time a query is made,
%but in order to get the
%most recent data from the treadmill you'd have to continuosly read for
%about 4-5 seconds for the data to catch up to real time.

pause(1)

%stop the treadmill
[speedcommand]=getsendcommand(0,0,1000,1000,0);
fwrite(t,speedcommand,'uint8');%send the command

%close the communication
fclose(t);
delete(t);

%The End...