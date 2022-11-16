% Pad a 3D array with zeros
% array: array to be padded
% xDimOut, yDimOut, zDimOut: dimensions of padded array

function [arrayOut, aSize, padDim] = pad3(arrayIn, xDimOut, yDimOut, zDimOut)
    aSize = size(arrayIn);
    xPad = xDimOut - aSize(1);
    yPad = yDimOut - aSize(2);
    zPad = zDimOut - aSize(3);
    
    if mod(xPad,2) == 0
        xPad1 = xPad/2;
        xPad2 = xPad/2;
    else
        xPad1 = (xPad-1)/2+1;
        xPad2 = (xPad-1)/2;
    end
    
    if mod(yPad,2) == 0
        yPad1 = yPad/2;
        yPad2 = yPad/2;
    else
        yPad1 = (yPad-1)/2+1;
        yPad2 = (yPad-1)/2;
    end
    
    if mod(zPad,2) == 0
        zPad1 = zPad/2;
        zPad2 = zPad/2;
    else
        zPad1 = (zPad-1)/2+1;
        zPad2 = (zPad-1)/2;
    end
    
    arrayOut_tmp = padarray(arrayIn, [xPad1 yPad1 zPad1], -1000, 'pre');
    arrayOut = padarray(arrayOut_tmp, [xPad2 yPad2 zPad2], -1000, 'post');
    padDim = [xPad1 yPad1 zPad1; xPad2 yPad2 zPad2];
end

    

%% Example
%a = reshape(1:24,3,2,4);
%size(a)
%aPadded = pad3(a,10,10,10);
%size(aPadded)