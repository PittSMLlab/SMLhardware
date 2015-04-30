function [velLspanned,velRspanned] = spanSpeedReq(velL,velR,steps)

%Check that velL, velR, step are all of the same size
if ~((length(velL)==length(velR)) && (length(steps)==length(velL)))
    disp('Error: vectors are not all of the same length')
    return
end

%Check that steps is monotonically strictly increasing
if any(diff(steps)<=0)
    disp('Error: variable ''steps'' is not monotonically increasing')
    return
end

for i=1:length(steps)-1
    velLspanned(steps(i)+1:steps(i+1))=round(linspace(velL(i),velL(i+1),steps(i+1)-steps(i)));
    velRspanned(steps(i)+1:steps(i+1))=round(linspace(velR(i),velR(i+1),steps(i+1)-steps(i)));
end



end

