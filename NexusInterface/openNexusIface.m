function [MyClient] = openNexusIface(labeled, unlabeled, devices)
%Loading of libraries
Client.LoadViconDataStreamSDK();

%Start client
MyClient = Client();
HostName = 'localhost:801';

%open connection
while ~MyClient.IsConnected().Connected
  % Direct connection
  out=MyClient.Connect( HostName );
end

if nargin<1
    labeled=1;
    unlabeled=1;
    devices=1;
end

%Enable relevant types of data
if labeled==1
Output_EnableMarkerData = MyClient.EnableMarkerData(); %Labeled
end
if unlabeled==1
Output_EnableUnlabeledMarkerData = MyClient.EnableUnlabeledMarkerData(); %Unlabeled
end
if devices==1
Output_EnableDeviceData = MyClient.EnableDeviceData(); %Force plates, EMG & such
end

%Transmission mode set: default= ClientPull
MyClient.SetStreamMode( StreamMode.ClientPull );

end

