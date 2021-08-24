% Computes motion vectors using Three Step Search method
%
% Input
%   imgP : The image for which we want to find motion vectors
%   imgI : The reference image
%   mbSize : Size of the macroblock
%   p : Search parameter  (read literature to find what this means)
%
% Ouput
%   motionVect : the motion vectors for each integral macroblock in imgP
%   TSScomputations: The average number of points searched for a macroblock
%
% Written by Aroh Barjatya
%
% License
% 
% Copyright (c) 2005, Aroh Barjatya
% All rights reserved.
% 
% Redistribution and use in source and binary forms, with or without
% modification, are permitted provided that the following conditions are
% met:
% 
%     * Redistributions of source code must retain the above copyright
%       notice, this list of conditions and the following disclaimer.
%     * Redistributions in binary form must reproduce the above copyright
%       notice, this list of conditions and the following disclaimer in
%       the documentation and/or other materials provided with the distribution
% 
% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
% AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
% IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
% ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
% LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
% CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
% SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
% INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
% CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
% ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
% POSSIBILITY OF SUCH DAMAGE.


function [motionVect, TSScomputations] = motionEstTSS(imgP, imgI, mbSize, p)

[row col] = size(imgI);

vectors = zeros(2,row*col/mbSize^2);
costs = ones(3, 3) * 10000000000000000000000000000000;

computations = 0;

% we now take effectively log to the base 2 of p
% this will give us the number of steps required

L = floor(log10(p+1)/log10(2));   
stepMax = 2^(L-1);

% we start off from the top left of the image
% we will walk in steps of mbSize
% for every marcoblock that we look at we will look for
% a close match p pixels on the left, right, top and bottom of it

mbCount = 1;
for i = 1 : mbSize : row-mbSize+1
    for j = 1 : mbSize : col-mbSize+1
        
        % the three step search starts
        % we will evaluate 9 elements at every step
        % read the literature to find out what the pattern is
        % my variables have been named aptly to reflect their significance

        x = j;
        y = i;
        
        % In order to avoid calculating the center point of the search
        % again and again we always store the value for it from teh
        % previous run. For the first iteration we store this value outside
        % the for loop, but for subsequent iterations we store the cost at
        % the point where we are going to shift our root.
        
        costs(2,2) = costFuncMSE(imgP(i:i+mbSize-1,j:j+mbSize-1), ...
                                    imgI(i:i+mbSize-1,j:j+mbSize-1),mbSize);
        
        computations = computations + 1;
        stepSize = stepMax;               

        while(stepSize >= 1)  

            % m is row(vertical) index
            % n is col(horizontal) index
            % this means we are scanning in raster order
            for m = -stepSize : stepSize : stepSize        
                for n = -stepSize : stepSize : stepSize
                    refBlkVer = y + m;   % row/Vert co-ordinate for ref block
                    refBlkHor = x + n;   % col/Horizontal co-ordinate
                    if ( refBlkVer < 1 || refBlkVer+mbSize-1 > row ...
                        || refBlkHor < 1 || refBlkHor+mbSize-1 > col)
                        continue;
                    end


                    costRow = m/stepSize + 2;
                    costCol = n/stepSize + 2;
                    if (costRow == 2 && costCol == 2)
                        continue
                    end
                    costs(costRow, costCol ) = costFuncMSE(imgP(i:i+mbSize-1,j:j+mbSize-1), ...
                        imgI(refBlkVer:refBlkVer+mbSize-1, refBlkHor:refBlkHor+mbSize-1), mbSize);
                    
                    computations = computations + 1;
                end
            end
        
            % Now we find the vector where the cost is minimum
            % and store it ... this is what will be passed back.
        
            [dx, dy, min] = minCost(costs);      % finds which macroblock in imgI gave us min Cost
            
            
            % shift the root for search window to new minima point

            x = x + (dx-2)*stepSize;
            y = y + (dy-2)*stepSize;
            
            % Arohs thought: At this point we can check and see if the
            % shifted co-ordinates are exactly the same as the root
            % co-ordinates of the last step, then we check them against a
            % preset threshold, and ifthe cost is less then that, than we
            % can exit from teh loop right here. This way we can save more
            % computations. However, as this is not implemented in the
            % paper I am modeling, I am not incorporating this test. 
            % May be later...as my own addition to the algorithm
            
            stepSize = stepSize / 2;
            costs(2,2) = costs(dy,dx);
            
        end
        vectors(1,mbCount) = y - i;    % row co-ordinate for the vector
        vectors(2,mbCount) = x - j;    % col co-ordinate for the vector
        mbCount = mbCount + 1;
        costs = ones(3,3) * 10000000000000000000000000000000;
    end
end

motionVect = vectors;
TSScomputations = computations/(mbCount - 1);                    