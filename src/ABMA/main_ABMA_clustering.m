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
%
% Copyright (c) 2021 UCLouvain, ICTEAM
% Licensed under GPL-3.0 [see LICENSE for details]
% Modifed by Karim El Khoury (2021) to fit adaptive block matching requirements

clear;
start_frame_number = 1;
end_frame_number = 1000;
num_frames = end_frame_number - start_frame_number + 1;
fps_latency_fromoriginal=1; %recommended to keep at 1

imageName = 'imagename';
imagePath = './imagePath';
image_row_org =1152; %always a multiple of 128 (do the next multiple above)
image_col_org = 1920; %always a multiple of 128 (do the next multiple above)

mbSize128 = 128;
mbSize64 = 64;
mbSize32 = 32;
mbSize16 = 16;
mbSize8 = 8;
mbSize4 = 4;

p127 = 127;
p63 = 63;
p31 = 31;
p15 = 15;
p7 = 7;
p3 = 3;

sensitivity_limit_128=3;
sensitivity_limit_64=10;
sensitivity_limit_32=20;
sensitivity_limit_16=50;
sensitivity_limit_8=70;
sensitivity_limit_4=100;

interpolation_factor=1; %(1 for no interpolation)  

MotionVectorArray_TSS = cell(num_frames+1,1);

tic

for i = (start_frame_number):(end_frame_number-fps_latency_fromoriginal)

 
%%%%%%%%%%%%%%%%%%% RESET VARIABLES EVERY 20 FRAMES %%%%%%%%%%%%%%%%%%%
    
if mod(i,20)==0
    
start_frame_number = i;
clearvars -except start_frame_number i end_frame_number fps_latency_fromoriginal imageName image_row_org image_col_org mbSize128 mbSize64 mbSize32 mbSize16 mbSize8 mbSize4 p127 p63 p31 p15 p7 p3 sensitivity_limit_128 sensitivity_limit_64 sensitivity_limit_32 sensitivity_limit_16 sensitivity_limit_8 sensitivity_limit_4 interpolation_factor;
num_frames = end_frame_number - start_frame_number + 1;
MotionVectorArray_TSS = cell(num_frames+1,1);
 
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    imgINumber = i; 
    imgPNumber = i+fps_latency_fromoriginal;

    imgIFile = sprintf('%s/%s%d.bmp',imagePath, imageName, imgINumber);
    imgPFile = sprintf('%s/%s%d.bmp',imagePath, imageName, imgPNumber);
   
    imgI_colored = double(imread(imgIFile));
    imgP_colored = double(imread(imgPFile));

    original_size = size(imgI_colored);    
    
    
    %add black lines 
    imgI_colored(end:image_row_org,end:image_col_org,:)=0;
    imgP_colored(end:image_row_org,end:image_col_org,:)=0;
    
    %convert to gray
    imgI = round(0.2126*imgI_colored(:,:,1) + 0.7152*imgI_colored(:,:,2) + 0.0722*imgI_colored(:,:,3));
    imgP = round(0.2126*imgP_colored(:,:,1) + 0.7152*imgP_colored(:,:,2) + 0.0722*imgP_colored(:,:,3));
    
    
     %%%Linear Sub-pixel interpolation grayscale 
     I = imgI;
     class_of_I = class(I);
     [x,y] = meshgrid(1:image_col_org,1:image_row_org);
     [xi,yi] = meshgrid(1:interpolation_factor:image_col_org,1:interpolation_factor:image_row_org);
     New_Image = cast(interp2(x,y,double(I),xi,yi,'linear'),class_of_I);
     for i = 1:(1/interpolation_factor - 1) 
     New_Image(:,end+1)=New_Image(:,end);
     New_Image(end+1,:)=New_Image(end,:);     
     end  
     imgI = floor(New_Image);
     
     I = imgP;
     class_of_I = class(I);
     [x,y] = meshgrid(1:image_col_org,1:image_row_org);
     [xi,yi] = meshgrid(1:interpolation_factor:image_col_org,1:interpolation_factor:image_row_org);
     New_Image = cast(interp2(x,y,double(I),xi,yi,'linear'),class_of_I);
     for i = 1:(1/interpolation_factor - 1) 
     New_Image(:,end+1)=New_Image(:,end);
     New_Image(end+1,:)=New_Image(end,:);     
     end  
     imgP = floor(New_Image);

    %%%
    
    
     
     %%%Linear Sub-pixel interpolation color 
    
     I = imgI_colored(1:image_row_org,1:image_col_org,1);
     class_of_I = class(I);
     [x,y] = meshgrid(1:image_col_org,1:image_row_org);
     [xi,yi] = meshgrid(1:interpolation_factor:image_col_org,1:interpolation_factor:image_row_org);
     New_Image = cast(interp2(x,y,double(I),xi,yi,'linear'),class_of_I);
     for i = 1:(1/interpolation_factor - 1) 
     New_Image(:,end+1)=New_Image(:,end);
     New_Image(end+1,:)=New_Image(end,:);     
     end  
     imgI_color(:,:,1) = floor(New_Image);    
    
     I = imgI_colored(1:image_row_org,1:image_col_org,2);
     class_of_I = class(I);
     [x,y] = meshgrid(1:image_col_org,1:image_row_org);
     [xi,yi] = meshgrid(1:interpolation_factor:image_col_org,1:interpolation_factor:image_row_org);
     New_Image = cast(interp2(x,y,double(I),xi,yi,'linear'),class_of_I);
     for i = 1:(1/interpolation_factor - 1) 
     New_Image(:,end+1)=New_Image(:,end);
     New_Image(end+1,:)=New_Image(end,:);     
     end  
     imgI_color(:,:,2) = floor(New_Image);    

     I = imgI_colored(1:image_row_org,1:image_col_org,3);
     class_of_I = class(I);
     [x,y] = meshgrid(1:image_col_org,1:image_row_org);
     [xi,yi] = meshgrid(1:interpolation_factor:image_col_org,1:interpolation_factor:image_row_org);
     New_Image = cast(interp2(x,y,double(I),xi,yi,'linear'),class_of_I);
     for i = 1:(1/interpolation_factor - 1) 
     New_Image(:,end+1)=New_Image(:,end);
     New_Image(end+1,:)=New_Image(end,:);     
     end  
     imgI_color(:,:,3) = floor(New_Image);        

     I = imgP_colored(1:image_row_org,1:image_col_org,1);
     class_of_I = class(I);
     [x,y] = meshgrid(1:image_col_org,1:image_row_org);
     [xi,yi] = meshgrid(1:interpolation_factor:image_col_org,1:interpolation_factor:image_row_org);
     New_Image = cast(interp2(x,y,double(I),xi,yi,'linear'),class_of_I);
     for i = 1:(1/interpolation_factor - 1) 
     New_Image(:,end+1)=New_Image(:,end);
     New_Image(end+1,:)=New_Image(end,:);     
     end  
     imgP_color(:,:,1) = floor(New_Image);    
    
     I = imgP_colored(1:image_row_org,1:image_col_org,2);
     class_of_I = class(I);
     [x,y] = meshgrid(1:image_col_org,1:image_row_org);
     [xi,yi] = meshgrid(1:interpolation_factor:image_col_org,1:interpolation_factor:image_row_org);
     New_Image = cast(interp2(x,y,double(I),xi,yi,'linear'),class_of_I);
     for i = 1:(1/interpolation_factor - 1) 
     New_Image(:,end+1)=New_Image(:,end);
     New_Image(end+1,:)=New_Image(end,:);     
     end  
     imgP_color(:,:,2) = floor(New_Image);    

     I = imgP_colored(1:image_row_org,1:image_col_org,3);
     class_of_I = class(I);
     [x,y] = meshgrid(1:image_col_org,1:image_row_org);
     [xi,yi] = meshgrid(1:interpolation_factor:image_col_org,1:interpolation_factor:image_row_org);
     New_Image = cast(interp2(x,y,double(I),xi,yi,'linear'),class_of_I);
     for i = 1:(1/interpolation_factor - 1)
     New_Image(:,end+1)=New_Image(:,end);
     New_Image(end+1,:)=New_Image(end,:);
     end
     imgP_color(:,:,3) = floor(New_Image); 
     
     image_row=image_row_org/interpolation_factor;    
     image_col=image_col_org/interpolation_factor; 
     
    %%%
     
    

     
     
     
    
     
%    TSS

%    Three Step Search with full MSE

        
     [motionVect128, computations128] = motionEstTSS(imgP,imgI,mbSize128,p127);
     MotionVectorArray128{imgINumber} = motionVect128(:,:);
     motionVect128_reshaped(:,:,2) = reshape(motionVect128(2,:),image_col/mbSize128,image_row/mbSize128)';
     motionVect128_reshaped(:,:,1) = reshape(motionVect128(1,:),image_col/mbSize128,image_row/mbSize128)';
     MotionVectorArray128_reshaped{imgINumber} =  motionVect128_reshaped(:,:,:);
     motionVect128_reshaped_kronned_y = kron(motionVect128_reshaped(:,:,1),ones(mbSize128/mbSize64));
     motionVect128_reshaped_kronned_x = kron(motionVect128_reshaped(:,:,2),ones(mbSize128/mbSize64));
     motionVect128_adjusted(2,:) = reshape(motionVect128_reshaped_kronned_x',1,(image_col/mbSize64)*(image_row/mbSize64));    
     motionVect128_adjusted(1,:) = reshape(motionVect128_reshaped_kronned_y',1,(image_col/mbSize64)*(image_row/mbSize64));   
     MotionVectorArray128_adjusted{imgINumber} = motionVect128_adjusted(:,:);
   
     %%%%%%%% Labeling and kronning
     
     motionVect128_reshaped_labeled = motionVect_labeling(motionVect128_reshaped, sensitivity_limit_128);
     MotionVectorArray128_reshaped_labeled{imgINumber} = motionVect128_reshaped_labeled(:,:,:);     
     motionVect128_reshaped_labaled_kronned_y = kron(motionVect128_reshaped_labeled(:,:,1),ones(mbSize128/mbSize4));
     motionVect128_reshaped_labaled_kronned_x = kron(motionVect128_reshaped_labeled(:,:,2),ones(mbSize128/mbSize4));
     motionVect128_reshaped_labaled_kronned_label = kron(motionVect128_reshaped_labeled(:,:,3),ones(mbSize128/mbSize4));
     motionVect128_reshaped_labeled_kronned(:,:,1) = motionVect128_reshaped_labaled_kronned_y; 
     motionVect128_reshaped_labeled_kronned(:,:,2) = motionVect128_reshaped_labaled_kronned_x; 
     motionVect128_reshaped_labeled_kronned(:,:,3) = motionVect128_reshaped_labaled_kronned_label; 
     MotionVectorArray128_reshaped_labeled_kronned{imgINumber} = motionVect128_reshaped_labeled_kronned(:,:,:);
          
     %%%%%%%%
     
     [motionVect64, computations64] = guided_motionEstTSS(imgP,imgI,mbSize64,p63,motionVect128_adjusted);
     MotionVectorArray64{imgINumber} = motionVect64(:,:);
     motionVect64_reshaped(:,:,2) = reshape(motionVect64(2,:),image_col/mbSize64,image_row/mbSize64)';
     motionVect64_reshaped(:,:,1) = reshape(motionVect64(1,:),image_col/mbSize64,image_row/mbSize64)';
     MotionVectorArray64_reshaped{imgINumber} =  motionVect64_reshaped(:,:,:);
     motionVect64_reshaped_kronned_y = kron(motionVect64_reshaped(:,:,1),ones(mbSize64/mbSize32));
     motionVect64_reshaped_kronned_x = kron(motionVect64_reshaped(:,:,2),ones(mbSize64/mbSize32));
     motionVect64_adjusted(2,:) = reshape(motionVect64_reshaped_kronned_x',1,(image_col/mbSize32)*(image_row/mbSize32));    
     motionVect64_adjusted(1,:) = reshape(motionVect64_reshaped_kronned_y',1,(image_col/mbSize32)*(image_row/mbSize32));   
     MotionVectorArray64_adjusted{imgINumber} = motionVect64_adjusted(:,:);  

     %%%%%%%% Labeling and kronning
     
     motionVect64_reshaped_labeled = motionVect_labeling(motionVect64_reshaped, sensitivity_limit_64);
     MotionVectorArray64_reshaped_labeled{imgINumber} = motionVect64_reshaped_labeled(:,:,:); 
     motionVect64_reshaped_labaled_kronned_y = kron(motionVect64_reshaped_labeled(:,:,1),ones(mbSize64/mbSize4));
     motionVect64_reshaped_labaled_kronned_x = kron(motionVect64_reshaped_labeled(:,:,2),ones(mbSize64/mbSize4));
     motionVect64_reshaped_labaled_kronned_label = kron(motionVect64_reshaped_labeled(:,:,3),ones(mbSize64/mbSize4));
     motionVect64_reshaped_labeled_kronned(:,:,1) = motionVect64_reshaped_labaled_kronned_y; 
     motionVect64_reshaped_labeled_kronned(:,:,2) = motionVect64_reshaped_labaled_kronned_x; 
     motionVect64_reshaped_labeled_kronned(:,:,3) = motionVect64_reshaped_labaled_kronned_label; 
     MotionVectorArray64_reshaped_labeled_kronned{imgINumber} = motionVect64_reshaped_labeled_kronned(:,:,:);
               
     %%%%%%%%
     
     [motionVect32, computations32] = guided_motionEstTSS(imgP,imgI,mbSize32,p31,motionVect64_adjusted);
     MotionVectorArray32{imgINumber} = motionVect32(:,:);
     motionVect32_reshaped(:,:,2) = reshape(motionVect32(2,:),image_col/mbSize32,image_row/mbSize32)';
     motionVect32_reshaped(:,:,1) = reshape(motionVect32(1,:),image_col/mbSize32,image_row/mbSize32)'; 
     MotionVectorArray32_reshaped{imgINumber} =  motionVect32_reshaped(:,:,:);
     motionVect32_reshaped_kronned_y = kron(motionVect32_reshaped(:,:,1),ones(mbSize32/mbSize16));
     motionVect32_reshaped_kronned_x = kron(motionVect32_reshaped(:,:,2),ones(mbSize32/mbSize16));
     motionVect32_adjusted(2,:) = reshape(motionVect32_reshaped_kronned_x',1,(image_col/mbSize16)*(image_row/mbSize16));    
     motionVect32_adjusted(1,:) = reshape(motionVect32_reshaped_kronned_y',1,(image_col/mbSize16)*(image_row/mbSize16));   
     MotionVectorArray32_adjusted{imgINumber} = motionVect32_adjusted(:,:);  
     
     %%%%%%%% Labeling and kronning
     
     motionVect32_reshaped_labeled = motionVect_labeling(motionVect32_reshaped, sensitivity_limit_32);
     MotionVectorArray32_reshaped_labeled{imgINumber} = motionVect32_reshaped_labeled(:,:,:); 
     motionVect32_reshaped_labaled_kronned_y = kron(motionVect32_reshaped_labeled(:,:,1),ones(mbSize32/mbSize4));
     motionVect32_reshaped_labaled_kronned_x = kron(motionVect32_reshaped_labeled(:,:,2),ones(mbSize32/mbSize4));
     motionVect32_reshaped_labaled_kronned_label = kron(motionVect32_reshaped_labeled(:,:,3),ones(mbSize32/mbSize4));
     motionVect32_reshaped_labeled_kronned(:,:,1) = motionVect32_reshaped_labaled_kronned_y; 
     motionVect32_reshaped_labeled_kronned(:,:,2) = motionVect32_reshaped_labaled_kronned_x; 
     motionVect32_reshaped_labeled_kronned(:,:,3) = motionVect32_reshaped_labaled_kronned_label; 
     MotionVectorArray32_reshaped_labeled_kronned{imgINumber} = motionVect32_reshaped_labeled_kronned(:,:,:);
               
     %%%%%%%%     
     
     [motionVect16, computations16] = guided_motionEstTSS(imgP,imgI,mbSize16,p15,motionVect32_adjusted);
     MotionVectorArray16{imgINumber} = motionVect16(:,:);
     motionVect16_reshaped(:,:,2) = reshape(motionVect16(2,:),image_col/mbSize16,image_row/mbSize16)';
     motionVect16_reshaped(:,:,1) = reshape(motionVect16(1,:),image_col/mbSize16,image_row/mbSize16)'; 
     MotionVectorArray16_reshaped{imgINumber} =  motionVect16_reshaped(:,:,:);
     motionVect16_reshaped_kronned_y = kron(motionVect16_reshaped(:,:,1),ones(mbSize16/mbSize8));
     motionVect16_reshaped_kronned_x = kron(motionVect16_reshaped(:,:,2),ones(mbSize16/mbSize8));
     motionVect16_adjusted(2,:) = reshape(motionVect16_reshaped_kronned_x',1,(image_col/mbSize8)*(image_row/mbSize8));    
     motionVect16_adjusted(1,:) = reshape(motionVect16_reshaped_kronned_y',1,(image_col/mbSize8)*(image_row/mbSize8));   
     MotionVectorArray16_adjusted{imgINumber} = motionVect16_adjusted(:,:);
     
     %%%%%%%% Labeling and kronning
     
     motionVect16_reshaped_labeled = motionVect_labeling(motionVect16_reshaped, sensitivity_limit_16);
     MotionVectorArray16_reshaped_labeled{imgINumber} = motionVect16_reshaped_labeled(:,:,:); 
     motionVect16_reshaped_labaled_kronned_y = kron(motionVect16_reshaped_labeled(:,:,1),ones(mbSize16/mbSize4));
     motionVect16_reshaped_labaled_kronned_x = kron(motionVect16_reshaped_labeled(:,:,2),ones(mbSize16/mbSize4));
     motionVect16_reshaped_labaled_kronned_label = kron(motionVect16_reshaped_labeled(:,:,3),ones(mbSize16/mbSize4));
     motionVect16_reshaped_labeled_kronned(:,:,1) = motionVect16_reshaped_labaled_kronned_y; 
     motionVect16_reshaped_labeled_kronned(:,:,2) = motionVect16_reshaped_labaled_kronned_x; 
     motionVect16_reshaped_labeled_kronned(:,:,3) = motionVect16_reshaped_labaled_kronned_label; 
     MotionVectorArray16_reshaped_labeled_kronned{imgINumber} = motionVect16_reshaped_labeled_kronned(:,:,:);
               
     %%%%%%%%
     
     [motionVect8, computations8] = guided_motionEstTSS(imgP,imgI,mbSize8,p7,motionVect16_adjusted);
     MotionVectorArray8{imgINumber} = motionVect8(:,:);     
     motionVect8_reshaped(:,:,2) = reshape(motionVect8(2,:),image_col/mbSize8,image_row/mbSize8)';
     motionVect8_reshaped(:,:,1) = reshape(motionVect8(1,:),image_col/mbSize8,image_row/mbSize8)'; 
     MotionVectorArray8_reshaped{imgINumber} =  motionVect8_reshaped(:,:,:);
     motionVect8_reshaped_kronned_y = kron(motionVect8_reshaped(:,:,1),ones(mbSize8/mbSize4));
     motionVect8_reshaped_kronned_x = kron(motionVect8_reshaped(:,:,2),ones(mbSize8/mbSize4));
     motionVect8_adjusted(2,:) = reshape(motionVect8_reshaped_kronned_x',1,(image_col/mbSize4)*(image_row/mbSize4));    
     motionVect8_adjusted(1,:) = reshape(motionVect8_reshaped_kronned_y',1,(image_col/mbSize4)*(image_row/mbSize4));   
     MotionVectorArray8_adjusted{imgINumber} = motionVect8_adjusted(:,:);  

     %%%%%%%% Labeling and kronning
     
     motionVect8_reshaped_labeled = motionVect_labeling(motionVect8_reshaped, sensitivity_limit_8);
     MotionVectorArray8_reshaped_labeled{imgINumber} = motionVect8_reshaped_labeled(:,:,:); 
     motionVect8_reshaped_labaled_kronned_y = kron(motionVect8_reshaped_labeled(:,:,1),ones(mbSize8/mbSize4));
     motionVect8_reshaped_labaled_kronned_x = kron(motionVect8_reshaped_labeled(:,:,2),ones(mbSize8/mbSize4));
     motionVect8_reshaped_labaled_kronned_label = kron(motionVect8_reshaped_labeled(:,:,3),ones(mbSize8/mbSize4));
     motionVect8_reshaped_labeled_kronned(:,:,1) = motionVect8_reshaped_labaled_kronned_y; 
     motionVect8_reshaped_labeled_kronned(:,:,2) = motionVect8_reshaped_labaled_kronned_x; 
     motionVect8_reshaped_labeled_kronned(:,:,3) = motionVect8_reshaped_labaled_kronned_label; 
     MotionVectorArray8_reshaped_labeled_kronned{imgINumber} = motionVect8_reshaped_labeled_kronned(:,:,:);
                         
     %%%%%%%%     
     
     [motionVect4, computations4] = guided_motionEstTSS(imgP,imgI,mbSize4,p3,motionVect8_adjusted);
     MotionVectorArray4{imgINumber} = motionVect4(:,:);
     motionVect4_reshaped(:,:,2) = reshape(motionVect4(2,:),image_col/mbSize4,image_row/mbSize4)';
     motionVect4_reshaped(:,:,1) = reshape(motionVect4(1,:),image_col/mbSize4,image_row/mbSize4)'; 
     MotionVectorArray4_reshaped{imgINumber} = motionVect4_reshaped(:,:);    
      

     %%%%%%%% Labeling and kronning
     
     motionVect4_reshaped_labeled = motionVect_labeling(motionVect4_reshaped, sensitivity_limit_4);
     MotionVectorArray4_reshaped_labeled{imgINumber} = motionVect4_reshaped_labeled(:,:,:); 
     motionVect4_reshaped_labaled_kronned_y = kron(motionVect4_reshaped_labeled(:,:,1),ones(mbSize4/mbSize4));
     motionVect4_reshaped_labaled_kronned_x = kron(motionVect4_reshaped_labeled(:,:,2),ones(mbSize4/mbSize4));
     motionVect4_reshaped_labaled_kronned_label = kron(motionVect4_reshaped_labeled(:,:,3),ones(mbSize4/mbSize4));
     motionVect4_reshaped_labeled_kronned(:,:,1) = motionVect4_reshaped_labaled_kronned_y; 
     motionVect4_reshaped_labeled_kronned(:,:,2) = motionVect4_reshaped_labaled_kronned_x; 
     motionVect4_reshaped_labeled_kronned(:,:,3) = motionVect4_reshaped_labaled_kronned_label; 
     MotionVectorArray4_reshaped_labeled_kronned{imgINumber} = motionVect4_reshaped_labeled_kronned(:,:,:);
                         

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
     
     
     
    %%%%%%%% Variable block recombination

    motionVect_reshaped_labeled_kronned(:,:,1)=mbSize4*ones(size(motionVect4_reshaped_labeled_kronned,1),size(motionVect4_reshaped_labeled_kronned,2));
    motionVect_reshaped_labeled_kronned(:,:,2)=mbSize4*ones(size(motionVect4_reshaped_labeled_kronned,1),size(motionVect4_reshaped_labeled_kronned,2));
    motionVect_reshaped_labeled_kronned(:,:,3)=mbSize4*ones(size(motionVect4_reshaped_labeled_kronned,1),size(motionVect4_reshaped_labeled_kronned,2));


     
    for i = 1 : size(motionVect_reshaped_labeled_kronned,1)
        for j = 1 : size(motionVect_reshaped_labeled_kronned,2)     
     
            if motionVect4_reshaped_labeled_kronned(i,j,3)==1

                motionVect_reshaped_labeled_kronned(i,j,1)=motionVect4_reshaped_labeled_kronned(i,j,1);
                motionVect_reshaped_labeled_kronned(i,j,2)=motionVect4_reshaped_labeled_kronned(i,j,2);
                motionVect_reshaped_labeled_kronned(i,j,3)=4;
                
            end    
        end
    end
    
    for i = 1 : size(motionVect_reshaped_labeled_kronned,1)
        for j = 1 : size(motionVect_reshaped_labeled_kronned,2)     
     
            if motionVect8_reshaped_labeled_kronned(i,j,3)==1

                motionVect_reshaped_labeled_kronned(i,j,1)=motionVect8_reshaped_labeled_kronned(i,j,1);
                motionVect_reshaped_labeled_kronned(i,j,2)=motionVect8_reshaped_labeled_kronned(i,j,2);
                motionVect_reshaped_labeled_kronned(i,j,3)=8;
                
            end    
        end
    end   
    
    for i = 1 : size(motionVect_reshaped_labeled_kronned,1)
        for j = 1 : size(motionVect_reshaped_labeled_kronned,2)     
     
            if motionVect16_reshaped_labeled_kronned(i,j,3)==1

                motionVect_reshaped_labeled_kronned(i,j,1)=motionVect16_reshaped_labeled_kronned(i,j,1);
                motionVect_reshaped_labeled_kronned(i,j,2)=motionVect16_reshaped_labeled_kronned(i,j,2);
                motionVect_reshaped_labeled_kronned(i,j,3)=16;
          
            end    
        end
    end
    
    for i = 1 : size(motionVect_reshaped_labeled_kronned,1)
        for j = 1 : size(motionVect_reshaped_labeled_kronned,2)     
     
            if motionVect32_reshaped_labeled_kronned(i,j,3)==1

                motionVect_reshaped_labeled_kronned(i,j,1)=motionVect32_reshaped_labeled_kronned(i,j,1);
                motionVect_reshaped_labeled_kronned(i,j,2)=motionVect32_reshaped_labeled_kronned(i,j,2);
                motionVect_reshaped_labeled_kronned(i,j,3)=32;
          
            end    
        end
    end    
    
    for i = 1 : size(motionVect_reshaped_labeled_kronned,1)
        for j = 1 : size(motionVect_reshaped_labeled_kronned,2)     
     
            if motionVect64_reshaped_labeled_kronned(i,j,3)==1

                motionVect_reshaped_labeled_kronned(i,j,1)=motionVect64_reshaped_labeled_kronned(i,j,1);
                motionVect_reshaped_labeled_kronned(i,j,2)=motionVect64_reshaped_labeled_kronned(i,j,2);
                motionVect_reshaped_labeled_kronned(i,j,3)=64;
          
            end    
        end
    end     
    
    for i = 1 : size(motionVect_reshaped_labeled_kronned,1)
        for j = 1 : size(motionVect_reshaped_labeled_kronned,2)     
     
            if motionVect128_reshaped_labeled_kronned(i,j,3)==1

                motionVect_reshaped_labeled_kronned(i,j,1)=motionVect128_reshaped_labeled_kronned(i,j,1);
                motionVect_reshaped_labeled_kronned(i,j,2)=motionVect128_reshaped_labeled_kronned(i,j,2);
                motionVect_reshaped_labeled_kronned(i,j,3)=128;
          
            end    
        end
    end    
       

     MotionVectorArray_reshaped_labeled_kronned{imgINumber} = motionVect_reshaped_labeled_kronned(:,:,:);
     
     motionVect_reshaped_labeled_kronned_y=motionVect_reshaped_labeled_kronned(:,:,1);
     motionVect_reshaped_labeled_kronned_x=motionVect_reshaped_labeled_kronned(:,:,2);
     motionVect_reshaped_labeled_kronned_adjusted(2,:) = reshape(motionVect_reshaped_labeled_kronned_x',1,(image_col/mbSize4)*(image_row/mbSize4));    
     motionVect_reshaped_labeled_kronned_adjusted(1,:) = reshape(motionVect_reshaped_labeled_kronned_y',1,(image_col/mbSize4)*(image_row/mbSize4));   
     motionVectArray_reshaped_labeled_kronned_adjusted{imgINumber} = motionVect_reshaped_labeled_kronned_adjusted(:,:);
 
                       
    

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
     
    
    %%%%%%%%%% Block contour and MovementAreas drawing
    
     motionVect_reshaped_labeled_kronned_imagesize(:,:,1)=kron(motionVect_reshaped_labeled_kronned(:,:,3),ones(mbSize4));
 
     imgI_withBlockContour=255*ones(size(imgI_color));
     imgI_MovementAreas_withBlockContour=255*ones(size(imgI_color));
     

    Total_number_of_blocks128 = 0;
    Total_number_of_blocks64 = 0;
    Total_number_of_blocks32 = 0;
    Total_number_of_blocks16 = 0;
    Total_number_of_blocks8 = 0;
    Total_number_of_blocks4 = 0;
         

     for i = 1 : mbSize128 : size(motionVect_reshaped_labeled_kronned_imagesize,1)-mbSize128+1
         for j = 1 : mbSize128 : size(motionVect_reshaped_labeled_kronned_imagesize,2)-mbSize128+1     
    
            if all(motionVect_reshaped_labeled_kronned_imagesize(i+1:i+mbSize128-2,j+1:j+mbSize128-2,1) == 128)
                  
                
                imgI_withBlockContour(i+1:i+mbSize128-2,j+1:j+mbSize128-2,:) =  imgI_color(i+1:i+mbSize128-2,j+1:j+mbSize128-2,:);             
                imgI_MovementAreas_withBlockContour(i+1:i+mbSize128-2,j+1:j+mbSize128-2,1) = 129; 
                imgI_MovementAreas_withBlockContour(i+1:i+mbSize128-2,j+1:j+mbSize128-2,2) = 129; 
                imgI_MovementAreas_withBlockContour(i+1:i+mbSize128-2,j+1:j+mbSize128-2,3) = 129;
                
                Total_number_of_blocks128 = Total_number_of_blocks128 + 1;                
                
             end    
         end
     end        
     
     for i = 1 : mbSize64 : size(motionVect_reshaped_labeled_kronned_imagesize,1)-mbSize64+1
         for j = 1 : mbSize64 : size(motionVect_reshaped_labeled_kronned_imagesize,2)-mbSize64+1     
    
            if all(motionVect_reshaped_labeled_kronned_imagesize(i+1:i+mbSize64-2,j+1:j+mbSize64-2,1) == 64)
                   

                imgI_withBlockContour(i+1:i+mbSize64-2,j+1:j+mbSize64-2,:) =  imgI_color(i+1:i+mbSize64-2,j+1:j+mbSize64-2,:);  
                imgI_MovementAreas_withBlockContour(i+1:i+mbSize64-2,j+1:j+mbSize64-2,1) = 255; 
                imgI_MovementAreas_withBlockContour(i+1:i+mbSize64-2,j+1:j+mbSize64-2,2) = 0; 
                imgI_MovementAreas_withBlockContour(i+1:i+mbSize64-2,j+1:j+mbSize64-2,3) = 0;
                
                Total_number_of_blocks64 = Total_number_of_blocks64 + 1;  
                
             end    
         end
     end        
     
     for i = 1 : mbSize32 : size(motionVect_reshaped_labeled_kronned_imagesize,1)-mbSize32+1
         for j = 1 : mbSize32 : size(motionVect_reshaped_labeled_kronned_imagesize,2)-mbSize32+1     
    
            if all(motionVect_reshaped_labeled_kronned_imagesize(i+1:i+mbSize32-2,j+1:j+mbSize32-2,1) == 32)
                   

                imgI_withBlockContour(i+1:i+mbSize32-2,j+1:j+mbSize32-2,:) =  imgI_color(i+1:i+mbSize32-2,j+1:j+mbSize32-2,:);  
                imgI_MovementAreas_withBlockContour(i+1:i+mbSize32-2,j+1:j+mbSize32-2,1) = 200; 
                imgI_MovementAreas_withBlockContour(i+1:i+mbSize32-2,j+1:j+mbSize32-2,2) = 100; 
                imgI_MovementAreas_withBlockContour(i+1:i+mbSize32-2,j+1:j+mbSize32-2,3) = 0;
                
                Total_number_of_blocks32 = Total_number_of_blocks32 + 1;  
                                         
             end    
         end
     end        

     for i = 1 : mbSize16 : size(motionVect_reshaped_labeled_kronned_imagesize,1)-mbSize16+1
         for j = 1 : mbSize16 : size(motionVect_reshaped_labeled_kronned_imagesize,2)-mbSize16+1     
    
            if all(motionVect_reshaped_labeled_kronned_imagesize(i+1:i+mbSize16-2,j+1:j+mbSize16-2,1) == 16)
                 

                imgI_withBlockContour(i+1:i+mbSize16-2,j+1:j+mbSize16-2,:) =  imgI_color(i+1:i+mbSize16-2,j+1:j+mbSize16-2,:);  
                imgI_MovementAreas_withBlockContour(i+1:i+mbSize16-2,j+1:j+mbSize16-2,1) = 255; 
                imgI_MovementAreas_withBlockContour(i+1:i+mbSize16-2,j+1:j+mbSize16-2,2) = 129; 
                imgI_MovementAreas_withBlockContour(i+1:i+mbSize16-2,j+1:j+mbSize16-2,3) = 0;
                
                Total_number_of_blocks16 = Total_number_of_blocks16 + 1;  
                                         
             end    
         end
     end        
     
     for i = 1 : mbSize8 : size(motionVect_reshaped_labeled_kronned_imagesize,1)-mbSize8+1
         for j = 1 : mbSize8 : size(motionVect_reshaped_labeled_kronned_imagesize,2)-mbSize8+1     
    
            if all(motionVect_reshaped_labeled_kronned_imagesize(i+1:i+mbSize8-2,j+1:j+mbSize8-2,1) == 8)
                  

                imgI_withBlockContour(i+1:i+mbSize8-2,j+1:j+mbSize8-2,:) =  imgI_color(i+1:i+mbSize8-2,j+1:j+mbSize8-2,:);  
                imgI_MovementAreas_withBlockContour(i+1:i+mbSize8-2,j+1:j+mbSize8-2,1) = 255; 
                imgI_MovementAreas_withBlockContour(i+1:i+mbSize8-2,j+1:j+mbSize8-2,2) = 255; 
                imgI_MovementAreas_withBlockContour(i+1:i+mbSize8-2,j+1:j+mbSize8-2,3) = 0;
                
                Total_number_of_blocks8 = Total_number_of_blocks8 + 1;  
                                         
             end    
         end
     end        
     
     for i = 1 : mbSize4 : size(motionVect_reshaped_labeled_kronned_imagesize,1)-mbSize4+1
         for j = 1 : mbSize4 : size(motionVect_reshaped_labeled_kronned_imagesize,2)-mbSize4+1     
    
            if all(motionVect_reshaped_labeled_kronned_imagesize(i+1:i+mbSize4-2,j+1:j+mbSize4-2,1) == 4)
    

                imgI_withBlockContour(i+1:i+mbSize4-2,j+1:j+mbSize4-2,:) =  imgI_color(i+1:i+mbSize4-2,j+1:j+mbSize4-2,:);  
                imgI_MovementAreas_withBlockContour(i+1:i+mbSize4-2,j+1:j+mbSize4-2,1) = 255; 
                imgI_MovementAreas_withBlockContour(i+1:i+mbSize4-2,j+1:j+mbSize4-2,2) = 255; 
                imgI_MovementAreas_withBlockContour(i+1:i+mbSize4-2,j+1:j+mbSize4-2,3) = 153;
                
                Total_number_of_blocks4 = Total_number_of_blocks4 + 1;  
                                         
             end    
         end
     end 
     
     
    imgIArray_withBlockContour{imgINumber}=imgI_withBlockContour(:,:,:);
    imgIArray_MovementAreas_withBlockContour{imgINumber}=imgI_MovementAreas_withBlockContour(:,:,:); 
    motionVectArray_reshaped_labeled_kronned_imagesize{imgINumber}=motionVect_reshaped_labeled_kronned_imagesize;
    
    
    
     
     
    %%%%%%%%%% Clustering algorithm and drawing
    
    
    imgI_Clustering_MovementAreas_withBlockContour=zeros(size(imgI_MovementAreas_withBlockContour,1),size(imgI_MovementAreas_withBlockContour,2),4);
    
    inst_cluster_counter=0;
    Centerpoint=1;
    
    
    max_mbSize = max(max(motionVect_reshaped_labeled_kronned_imagesize))/2;
    min_mbSize=min(min(motionVect_reshaped_labeled_kronned_imagesize));
    
    if min_mbSize < mbSize8
        
        min_mbSize = min_mbSize*2;
        
    elseif  min_mbSize >= max_mbSize
        
        min_mbSize = mbSize8;
      
    end
    
        
        
    
    color_panel=[1:180];
    color_panel_red=[255,0,0,255,255,0,128,0,0,128,255,0,0,255,255,0,128,0,0,128,255,0,0,255,255,0,128,0,0,128,255,0,0,255,255,0,128,0,0,128,255,0,0,255,255,0,128,0,0,128,255,0,0,255,255,0,128,0,0,128,255,0,0,255,255,0,128,0,0,128,255,0,0,255,255,0,128,0,0,128,255,0,0,255,255,0,128,0,0,128,255,0,0,255,255,0,128,0,0,128,255,0,0,255,255,0,128,0,0,128,255,0,0,255,255,0,128,0,0,128,255,0,0,255,255,0,128,0,0,128,255,0,0,255,255,0,128,0,0,128,255,0,0,255,255,0,128,0,0,128,255,0,0,255,255,0,128,0,0,128,255,0,0,255,255,0,128,0,0,128,255,0,0,255,255,0,128,0,0,128];
    color_panel_green=[0,255,0,25,0,255,0,128,0,128,0,255,0,25,0,255,0,128,0,1280,255,0,25,0,255,0,128,0,128,0,255,0,25,0,255,0,128,0,128,0,255,0,25,0,255,0,128,0,1280,255,0,25,0,255,0,128,0,128,0,255,0,25,0,255,0,128,0,128,0,255,0,25,0,255,0,128,0,1280,255,0,25,0,255,0,128,0,128,0,255,0,25,0,255,0,128,0,128,0,255,0,25,0,255,0,128,0,1280,255,0,25,0,255,0,128,0,128,0,255,0,25,0,255,0,128,0,128,0,255,0,25,0,255,0,128,0,1280,255,0,25,0,255,0,128,0,128,0,255,0,25,0,255,0,128,0,128,0,255,0,25,0,255,0,128,0,1280,255,0,25,0,255,0,128,0,128];
    color_panel_blue=[0,0,255,0,255,255,0,0,128,0,0,0,255,0,255,255,0,0,128,0,0,0,255,0,255,255,0,0,128,0,0,0,255,0,255,255,0,0,128,0,0,0,255,0,255,255,0,0,128,0,0,0,255,0,255,255,0,0,128,0,0,0,255,0,255,255,0,0,128,0,0,0,255,0,255,255,0,0,128,0,0,0,255,0,255,255,0,0,128,0,0,0,255,0,255,255,0,0,128,0,0,0,255,0,255,255,0,0,128,0,0,0,255,0,255,255,0,0,128,0,0,0,255,0,255,255,0,0,128,0,0,0,255,0,255,255,0,0,128,0,0,0,255,0,255,255,0,0,128,0,0,0,255,0,255,255,0,0,128,0,0,0,255,0,255,255,0,0,128,0,0,0,255,0,255,255,0,0,128,0];
            
    
    if(imgINumber==start_frame_number)
    color_counter=1;  
    end    
    
    %Step 1: Filter out only small blocks (size 8)
    
     for i = 1 : min_mbSize : size(motionVect_reshaped_labeled_kronned_imagesize,1)-min_mbSize+1
         for j = 1 : min_mbSize : size(motionVect_reshaped_labeled_kronned_imagesize,2)-min_mbSize+1     
    
            if all(motionVect_reshaped_labeled_kronned_imagesize(i:i+min_mbSize-1,j:j+min_mbSize-1,1) == min_mbSize)

                imgI_Clustering_MovementAreas_withBlockContour(i:i+min_mbSize-1,j:j+min_mbSize-1,1) = color_panel(color_counter);  
                                         
            end    
         end
     end     
    

  
     
    %Step 2: Pick first block of size 8 as center point
    
    Centerpoint = find(imgI_Clustering_MovementAreas_withBlockContour(:,:,1) == color_panel(color_counter));
    
while isempty(Centerpoint) ~= 1  %condition takes into account that threre are no more clusters
    
    stopdown=0;
    stopright=0;
    stopleft=0;
    stopup=0;
    
    Centerpoint_x = ceil(Centerpoint(1)/image_row_org);
    Centerpoint_y = rem(Centerpoint(1),image_row_org);
    

    inst_cluster_counter=inst_cluster_counter+1;
    
    if inst_cluster_counter > 10

    Centerpoint=[];
    
    else
    
    %Step 3: Get 4 edge points at large blocks (size 64)
    
    %Down
    
      for i = Centerpoint_y : min_mbSize : size(motionVect_reshaped_labeled_kronned_imagesize,1)-min_mbSize+1
            
            if stopdown == 0     
                
               if all(motionVect_reshaped_labeled_kronned_imagesize(i:i+min_mbSize-1,Centerpoint_x:Centerpoint_x+min_mbSize-1,1) < max_mbSize)
             
                    imgI_Clustering_MovementAreas_withBlockContour(i:i+min_mbSize-1,Centerpoint_x:Centerpoint_x+min_mbSize-1,1) = color_panel(color_counter+inst_cluster_counter);
              
                else

                    downpoint_y = i;
                    stopdown = 1;
                 
                end
             
            end
          
      end
    
     %Right
    
      for j = Centerpoint_x : min_mbSize : size(motionVect_reshaped_labeled_kronned_imagesize,2)-min_mbSize+1
            
            if stopright == 0     
                
               if all(motionVect_reshaped_labeled_kronned_imagesize(Centerpoint_y:Centerpoint_y+min_mbSize-1,j:j+min_mbSize-1,1) < max_mbSize)
             
                    imgI_Clustering_MovementAreas_withBlockContour(Centerpoint_y:Centerpoint_y+min_mbSize-1,j:j+min_mbSize-1,1) = color_panel(color_counter+inst_cluster_counter);
              
                else

                    rightpoint_x = j;
                    stopright = 1;
                 
                end
             
            end
          
      end      
 
     %Left
    
      for j = Centerpoint_x : -min_mbSize : 1
            
            if stopleft == 0     
                
               if all(motionVect_reshaped_labeled_kronned_imagesize(Centerpoint_y:Centerpoint_y+min_mbSize-1,j:j+min_mbSize-1,1) < max_mbSize)
             
                    imgI_Clustering_MovementAreas_withBlockContour(Centerpoint_y:Centerpoint_y+min_mbSize-1,j:j+min_mbSize-1,1) = color_panel(color_counter+inst_cluster_counter);
              
                else

                    leftpoint_x = j;
                    stopleft = 1;
                 
                end
             
            end
          
      end       
      
    %Up
    
      for i = Centerpoint_y : -min_mbSize : 1
          
            if stopup == 0     
                
               if all(motionVect_reshaped_labeled_kronned_imagesize(i:i+min_mbSize-1,Centerpoint_x:Centerpoint_x+min_mbSize-1,1) < max_mbSize)
             
                    imgI_Clustering_MovementAreas_withBlockContour(i:i+min_mbSize-1,Centerpoint_x:Centerpoint_x+min_mbSize-1,1) = color_panel(color_counter+inst_cluster_counter);
              
                else

                    uppoint_y = i;
                    stopup = 1;
                 
                end
             
            end
      end        
      

    %Step 4: Create cluster using 4 edge points
    
   if stopup == 1 && stopdown == 1 && stopright == 1 && stopleft == 1
    
     for i = uppoint_y : downpoint_y
         for j = leftpoint_x : rightpoint_x 
    
            imgI_Clustering_MovementAreas_withBlockContour(i,j,1) = color_panel(color_counter+inst_cluster_counter);
                                         
         end
     end  
     
   end
  

   %Step 4.1: Include all points in original cluster as centerpoints to improve cluster shape
   
 
 
   
     for Centerpoint_y_temp = uppoint_y : min_mbSize : downpoint_y
         for Centerpoint_x_temp = leftpoint_x : min_mbSize : rightpoint_x 
  
             
    stopdown_temp=0;
    stopright_temp=0;
    stopleft_temp=0;
    stopup_temp=0;          
             
    %Step 4.1.1: Get 4 edge points at large blocks (size 64)
    
    %Down
    
      for i = Centerpoint_y_temp : min_mbSize : size(motionVect_reshaped_labeled_kronned_imagesize,1)-min_mbSize+1
            
            if stopdown_temp == 0     
                
               if all(motionVect_reshaped_labeled_kronned_imagesize(i:i+min_mbSize-1,Centerpoint_x_temp:Centerpoint_x_temp+min_mbSize-1,1) < max_mbSize)
             
                    imgI_Clustering_MovementAreas_withBlockContour(i:i+min_mbSize-1,Centerpoint_x_temp:Centerpoint_x_temp+min_mbSize-1,1) = color_panel(color_counter+inst_cluster_counter);
              
                else

                    downpoint_y_temp = i;
                    stopdown_temp = 1;
                 
                end
             
            end
          
      end
    
     %Right
    
      for j = Centerpoint_x_temp : min_mbSize : size(motionVect_reshaped_labeled_kronned_imagesize,2)-min_mbSize+1
            
            if stopright_temp == 0     
                
               if all(motionVect_reshaped_labeled_kronned_imagesize(Centerpoint_y_temp:Centerpoint_y_temp+min_mbSize-1,j:j+min_mbSize-1,1) < max_mbSize)
             
                    imgI_Clustering_MovementAreas_withBlockContour(Centerpoint_y_temp:Centerpoint_y_temp+min_mbSize-1,j:j+min_mbSize-1,1) = color_panel(color_counter+inst_cluster_counter);
              
                else

                    rightpoint_x_temp = j;
                    stopright_temp = 1;
                 
                end
             
            end
          
      end      
 
     %Left
    
      for j = Centerpoint_x_temp : -min_mbSize : 1
            
            if stopleft_temp == 0     
                
               if all(motionVect_reshaped_labeled_kronned_imagesize(Centerpoint_y_temp:Centerpoint_y_temp+min_mbSize-1,j:j+min_mbSize-1,1) < max_mbSize)
             
                    imgI_Clustering_MovementAreas_withBlockContour(Centerpoint_y_temp:Centerpoint_y_temp+min_mbSize-1,j:j+min_mbSize-1,1) = color_panel(color_counter+inst_cluster_counter);
              
                else

                    leftpoint_x_temp = j;
                    stopleft_temp = 1;
                 
                end
             
            end
          
      end       
      
    %Up
    
      for i = Centerpoint_y_temp : -min_mbSize : 1
          
            if stopup_temp == 0     
                
               if all(motionVect_reshaped_labeled_kronned_imagesize(i:i+min_mbSize-1,Centerpoint_x_temp:Centerpoint_x_temp+min_mbSize-1,1) < max_mbSize)
             
                    imgI_Clustering_MovementAreas_withBlockContour(i:i+min_mbSize-1,Centerpoint_x_temp:Centerpoint_x_temp+min_mbSize-1,1) = color_panel(color_counter+inst_cluster_counter);
              
                else

                    uppoint_y_temp = i;
                    stopup_temp = 1;
                 
                end
             
            end
      end        
      
    %Step 4.1.2: Create cluster using 4 edge points
    
   if stopup_temp == 1 && stopdown_temp == 1 && stopright_temp == 1 && stopleft_temp == 1
    
     for i = uppoint_y_temp : downpoint_y_temp
         for j = leftpoint_x_temp : rightpoint_x_temp 
    
            imgI_Clustering_MovementAreas_withBlockContour(i,j,1) = color_panel(color_counter+inst_cluster_counter);
                                         
         end
     end  
     
   end                       
             
         end        
     end
     
     
    Centerpoint = find(imgI_Clustering_MovementAreas_withBlockContour(:,:,1) == color_panel(color_counter));
   
    end   
end      
 

    %Step 5: Overwriting correction
    

    non_zero = nonzeros(unique(imgI_Clustering_MovementAreas_withBlockContour(:,:,1)));
    true_cluster_counter= size(non_zero,1);

    
     for i = 1 : image_row_org
         for j = 1 : image_col_org 
   
            for k = 1: true_cluster_counter
             
            if imgI_Clustering_MovementAreas_withBlockContour(i,j,1) == non_zero(k)
                
            imgI_Clustering_MovementAreas_withBlockContour(i,j,1) = color_panel(color_counter+k);
            
            end
            
            end
            
         end
     end     

    non_zero = nonzeros(unique(imgI_Clustering_MovementAreas_withBlockContour(:,:,1)));
    true_cluster_counter= size(non_zero,1);

    %Step 6: incrementing color counter correctly (increment when disappear)

    case3_test=0; %%%%%%%%%%% TESTING FLAG
    
  if(imgINumber~=start_frame_number)  

    if(true_cluster_counter == 0 && trueArray_cluster_counter{imgINumber-1}==1)  
    
             color_counter=color_counter+1;
     
    elseif  (true_cluster_counter == 0)
     
             color_counter=color_counter;
        
    else
      
    if (true_cluster_counter == trueArray_cluster_counter{imgINumber-1})
   
        anorm=0;
        
         for i = 1 : true_cluster_counter
        
           clusterpoint_t = find(imgI_Clustering_MovementAreas_withBlockContour(:,:,1) == color_panel(color_counter+i));
           
           if isempty(clusterpoint_t)==1
               
           maxright_clusterpoint_t=image_col_org;
           maxleft_clusterpoint_t=1;
           
           else
           
           maxright_clusterpoint_t = ceil(clusterpoint_t(end)/image_row_org);
           maxleft_clusterpoint_t = ceil(clusterpoint_t(1)/image_row_org);
            
           end
        
           clusterpoint_tminus1 = find(imgIArray_Clustering_MovementAreas_withBlockContour{imgINumber-1}(:,:,1) == color_panel(color_counter+i));        
           
           if isempty(clusterpoint_tminus1)==1
               
           maxright_clusterpoint_tminus1 = image_col_org;
           maxleft_clusterpoint_tminus1 = 1;          
           
           else
           
           maxright_clusterpoint_tminus1 = ceil(clusterpoint_tminus1(end)/image_row_org);
           maxleft_clusterpoint_tminus1 = ceil(clusterpoint_tminus1(1)/image_row_org);          
      
           end
           
              if (maxright_clusterpoint_tminus1 >= maxright_clusterpoint_t) || (maxleft_clusterpoint_tminus1 >= maxleft_clusterpoint_t)
         
                   color_counter=color_counter;
        
              else    
            
                   anorm=anorm+1;             
                
              end
              
            
          end
         
        if anorm == true_cluster_counter
            
            color_counter=color_counter+1;
            
        end    
              
    end
 
    
    if (true_cluster_counter < trueArray_cluster_counter{imgINumber-1})
        
        anorm=0;        

       for i = 1 : true_cluster_counter
           
           clusterpoint_t = find(imgI_Clustering_MovementAreas_withBlockContour(:,:,1) == color_panel(color_counter+i));
           
           if isempty(clusterpoint_t)==1
               
           maxright_clusterpoint_t=image_col_org;
           maxleft_clusterpoint_t=1;
           
           else
           
           maxright_clusterpoint_t = ceil(clusterpoint_t(end)/image_row_org);
           maxleft_clusterpoint_t = ceil(clusterpoint_t(1)/image_row_org);
            
           end
        
           clusterpoint_tminus1 = find(imgIArray_Clustering_MovementAreas_withBlockContour{imgINumber-1}(:,:,1) == color_panel(color_counter+i));        
           
           if isempty(clusterpoint_tminus1)==1
               
           maxright_clusterpoint_tminus1 = image_col_org;
           maxleft_clusterpoint_tminus1 = 1;          
           
           else
           
           maxright_clusterpoint_tminus1 = ceil(clusterpoint_tminus1(end)/image_row_org);
           maxleft_clusterpoint_tminus1 = ceil(clusterpoint_tminus1(1)/image_row_org);          
      
           end       
      
         
              if (maxright_clusterpoint_tminus1 >= maxright_clusterpoint_t) || (maxleft_clusterpoint_tminus1 >= maxleft_clusterpoint_t)
         
                   color_counter=color_counter;
        
              else    
            
                   anorm=anorm+1;             
                
              end  
              
        if anorm == true_cluster_counter
            
            color_counter=color_counter+1;
            
        end  
              
           
       end
        
    end    
    
    
    if (true_cluster_counter > trueArray_cluster_counter{imgINumber-1})

    case3_test=case3_test+1; %%%%%%%%%%% TESTING FLAG
           
    end
        
  end     
    

  end


    %Step 7: redraw accordingly if color counter increased

  if(imgINumber~=start_frame_number)  
    
       
    if color_counter ~= colorArray_counter{imgINumber-1}
 
    non_zero = nonzeros(unique(imgI_Clustering_MovementAreas_withBlockContour(:,:,1)));
    true_cluster_counter= size(non_zero,1);        
        
     for i = 1 : image_row_org
         for j = 1 : image_col_org 
   
            for k = 1: true_cluster_counter
             
            if imgI_Clustering_MovementAreas_withBlockContour(i,j,1) == non_zero(k)
                
            imgI_Clustering_MovementAreas_withBlockContour(i,j,1) = color_panel(color_counter+k);
            
            end
            
            end
            
         end
     end          
        
    end    
   
  end  
    
    %Step 8: redraw in RGB 


       

     for i = 1 : image_row_org
         for j = 1 : image_col_org 
   
            for k = 1: true_cluster_counter
             
            if imgI_Clustering_MovementAreas_withBlockContour(i,j,1) == non_zero(k)
                
            imgI_Clustering_MovementAreas_withBlockContour(i,j,2) = color_panel_red(color_counter+k);
            imgI_Clustering_MovementAreas_withBlockContour(i,j,3) = color_panel_green(color_counter+k);
            imgI_Clustering_MovementAreas_withBlockContour(i,j,4) = color_panel_blue(color_counter+k);
            
            end
            
            end
            
         end
     end          
        
   
    

    
     imgIArray_Clustering_MovementAreas_withBlockContour{imgINumber}=imgI_Clustering_MovementAreas_withBlockContour;
     trueArray_cluster_counter{imgINumber}=true_cluster_counter;
     colorArray_counter{imgINumber}=color_counter;  
    

%    Total_number_of_blocks_displayed = Total_number_of_blocks256 + Total_number_of_blocks128 + Total_number_of_blocks64 + Total_number_of_blocks32 + Total_number_of_blocks16 + Total_number_of_blocks8 + Total_number_of_blocks4;       
    Total_number_of_blocks_displayed = Total_number_of_blocks128 + Total_number_of_blocks64 + Total_number_of_blocks32 + Total_number_of_blocks16 + Total_number_of_blocks8 + Total_number_of_blocks4;  
    Total_number_of_blocks_displayed_FullBMA = size(motionVect4_reshaped,1)*size(motionVect4_reshaped,2);  
    %    Total_number_of_blocks_calculated = (size(motionVect256_reshaped,1)*size(motionVect256_reshaped,2)) + 4*(size(motionVect256_reshaped,1)*size(motionVect256_reshaped,2) - Total_number_of_blocks256) + 4*(size(motionVect128_reshaped,1)*size(motionVect128_reshaped,2) - Total_number_of_blocks128 - 4*Total_number_of_blocks256) + 4*(size(motionVect64_reshaped,1)*size(motionVect64_reshaped,2) - Total_number_of_blocks64 - 4*Total_number_of_blocks128 - 16*Total_number_of_blocks256) + 4*(size(motionVect32_reshaped,1)*size(motionVect32_reshaped,2) - Total_number_of_blocks32 - 4*Total_number_of_blocks64 - 16*Total_number_of_blocks128 - 64*Total_number_of_blocks256) + 4*(size(motionVect16_reshaped,1)*size(motionVect16_reshaped,2) - Total_number_of_blocks16 - 4*Total_number_of_blocks32 - 16*Total_number_of_blocks64 - 64*Total_number_of_blocks128 - 256*Total_number_of_blocks256) + 4*(size(motionVect8_reshaped,1)*size(motionVect8_reshaped,2) - Total_number_of_blocks8 - 4*Total_number_of_blocks16 - 16*Total_number_of_blocks32 - 64*Total_number_of_blocks64 - 256*Total_number_of_blocks128 - 1024*Total_number_of_blocks256);    
    Total_number_of_blocks_calculated = (size(motionVect128_reshaped,1)*size(motionVect128_reshaped,2)) + 4*(size(motionVect128_reshaped,1)*size(motionVect128_reshaped,2) - Total_number_of_blocks128) + 4*(size(motionVect64_reshaped,1)*size(motionVect64_reshaped,2) - Total_number_of_blocks64 - 4*Total_number_of_blocks128) + 4*(size(motionVect32_reshaped,1)*size(motionVect32_reshaped,2) - Total_number_of_blocks32 - 4*Total_number_of_blocks64 - 16*Total_number_of_blocks128) + 4*(size(motionVect16_reshaped,1)*size(motionVect16_reshaped,2) - Total_number_of_blocks16 - 4*Total_number_of_blocks32 - 16*Total_number_of_blocks64 - 64*Total_number_of_blocks128)+ 4*(size(motionVect8_reshaped,1)*size(motionVect8_reshaped,2) - Total_number_of_blocks8 - 4*Total_number_of_blocks16 - 16*Total_number_of_blocks32 - 64*Total_number_of_blocks64 - 256*Total_number_of_blocks128);
%    Total_number_of_blocks_calculated_FullBMA = ones(size(Total_number_of_blocks_calculated,1),size(Total_number_of_blocks_calculated,2))*((size(motionVect256_reshaped,1)*size(motionVect256_reshaped,2)) + 4*(size(motionVect256_reshaped,1)*size(motionVect256_reshaped,2)) + 4*(size(motionVect128_reshaped,1)*size(motionVect128_reshaped,2)) + 4*(size(motionVect64_reshaped,1)*size(motionVect64_reshaped,2)) + 4*(size(motionVect32_reshaped,1)*size(motionVect32_reshaped,2)) + 4*(size(motionVect16_reshaped,1)*size(motionVect16_reshaped,2)) + 4*(size(motionVect8_reshaped,1)*size(motionVect8_reshaped,2)));    
    Total_number_of_blocks_calculated_FullBMA = size(motionVect128_reshaped,1)*size(motionVect128_reshaped,2) + 4*(size(motionVect128_reshaped,1)*size(motionVect128_reshaped,2)) + 4*(size(motionVect64_reshaped,1)*size(motionVect64_reshaped,2)) + 4*(size(motionVect32_reshaped,1)*size(motionVect32_reshaped,2)) + 4*(size(motionVect16_reshaped,1)*size(motionVect16_reshaped,2)) + 4*(size(motionVect8_reshaped,1)*size(motionVect8_reshaped,2));
    Total_number_of_blocksArray(1,imgINumber) = Total_number_of_blocks_displayed;
    Total_number_of_blocksArray(2,imgINumber) = Total_number_of_blocks_calculated;
    Total_number_of_blocksArray(3,imgINumber) = Total_number_of_blocks_displayed_FullBMA;        
    Total_number_of_blocksArray(4,imgINumber) = Total_number_of_blocks_calculated_FullBMA;
        
   
     color_counter_str = num2str(color_counter-1);
     true_cluster_counter_str = num2str(true_cluster_counter);


     imgI_withBlockContour_display = uint8(imgI_withBlockContour);
   
     imgI_MovementAreas_withBlockContour_display = uint8(imgI_MovementAreas_withBlockContour);
 
     imgI_Clustering_MovementAreas_withBlockContour_display = uint8(imgI_Clustering_MovementAreas_withBlockContour(:,:,2:4));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

    
    imgComp_ABMA = motionComp(imgI, motionVect_reshaped_labeled_kronned_adjusted, mbSize4);     
    imgComp_FullBMA = motionComp(imgI, motionVect4, mbSize4);  
    
    imgDiff_PredMinusOri_plus256_ABMA = uint16(imgComp_ABMA - imgP + 256);
    imgDiff_PredMinusOri_plus256_FullBMA = uint16(imgComp_FullBMA - imgP + 256);
    
    
    imgDiffArray_ABMA{imgINumber}=imgDiff_PredMinusOri_plus256_ABMA;
    imgDiffArray_FullBMA{imgINumber}=imgDiff_PredMinusOri_plus256_FullBMA;

    
    %%%%%
    imgDiff_PredMinusOri_cropped_ABMA=uint8(imgDiff_PredMinusOri_plus256_ABMA/2);

    
    imgDiffArray_cropped_ABMA{imgINumber}=imgDiff_PredMinusOri_cropped_ABMA;
    
    % Final residues written (crop to original size (1:original_size(1),1:original_size(2)))
    imwrite(imgDiff_PredMinusOri_cropped_ABMA(1:original_size(1),1:original_size(2)),strcat(imageName,'_imgDiff_PredMinusOri_cropped_ABMA_128to',num2str(mbSize4),'_PixelInterpolation_',num2str(interpolation_factor),'_',num2str(imgINumber),'.bmp'));    
    %%%%%
    
    fprintf('Done for frame:  %d \n', imgINumber)
    toc
    
end

 close all