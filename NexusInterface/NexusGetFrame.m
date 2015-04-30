function [FrameNo,TimeStamp,SubjectCount,LabeledMarkerCount,UnlabeledMarkerCount,DeviceCount,DeviceOutputCount] = NexusGetFrame(MyClient)
    a=0;
   while MyClient.GetFrame().Result.Value ~= Result.Success
        a=a+1;
        if a>100000
            disp('NExus took too long to respond, aborting')
            return
        end
   end
Output = MyClient.GetFrameNumber(); %Of last retrieved frame
FrameNo = Output.FrameNumber;
TimeStamp = MyClient.GetTimecode();
SubjectCount = MyClient.GetSubjectCount().SubjectCount;
LabeledMarkerCount=zeros(SubjectCount,1);
for SubjectIndex = 1:SubjectCount
    % Count the number of markers
    LabeledMarkerCount(SubjectIndex) = MyClient.GetMarkerCount( MyClient.GetSubjectName( SubjectIndex ).SubjectName).MarkerCount; %This should be a fixed value
end
UnlabeledMarkerCount = MyClient.GetUnlabeledMarkerCount().MarkerCount;
DeviceCount = MyClient.GetDeviceCount().DeviceCount;
DeviceOutputCount = zeros(DeviceCount,1);
for DeviceIndex = 1:DeviceCount %Get data from each device
    % Count the number of device outputs
    DeviceOutputCount(DeviceIndex) = MyClient.GetDeviceOutputCount( MyClient.GetDeviceName( DeviceIndex ).DeviceName ).DeviceOutputCount;
end
end

