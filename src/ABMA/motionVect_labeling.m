function [motionVect_reshaped_labeled] = motionVect_labeling(motionVect_reshaped, sensitivity_limit)

motionVect_reshaped_labeled=motionVect_reshaped;

motionVect_reshaped_labeled(:,:,3)=zeros(size(motionVect_reshaped,1),size(motionVect_reshaped,2));


%contour motion vector are by defaulted labeled ok
motionVect_reshaped_labeled(:,1,3)=1;
motionVect_reshaped_labeled(:,size(motionVect_reshaped,2),3)=1;
motionVect_reshaped_labeled(1,:,3)=1;
motionVect_reshaped_labeled(size(motionVect_reshaped,1),:,3)=1;


    for i = 2 : size(motionVect_reshaped,1)-1
        for j = 2 : size(motionVect_reshaped,2)-1

        eightD_neighbours_y = [motionVect_reshaped_labeled(i-1,j,1),motionVect_reshaped_labeled(i,j-1,1),motionVect_reshaped_labeled(i+1,j,1),motionVect_reshaped_labeled(i,j+1,1),motionVect_reshaped_labeled(i-1,j+1,1),motionVect_reshaped_labeled(i-1,j-1,1),motionVect_reshaped_labeled(i+1,j-1,1),motionVect_reshaped_labeled(i+1,j+1,1)]; 
        eightD_neighbours_x = [motionVect_reshaped_labeled(i-1,j,2),motionVect_reshaped_labeled(i,j-1,2),motionVect_reshaped_labeled(i+1,j,2),motionVect_reshaped_labeled(i,j+1,2),motionVect_reshaped_labeled(i-1,j+1,2),motionVect_reshaped_labeled(i-1,j-1,2),motionVect_reshaped_labeled(i+1,j-1,2),motionVect_reshaped_labeled(i+1,j+1,2)];
        eightD_neighbours_mean_y = mean(eightD_neighbours_y);
        eightD_neighbours_mean_x = mean(eightD_neighbours_x);
              
        if abs(motionVect_reshaped_labeled(i,j,1)-eightD_neighbours_mean_y) < sensitivity_limit && abs(motionVect_reshaped_labeled(i,j,2)-eightD_neighbours_mean_x) < sensitivity_limit
           
            motionVect_reshaped_labeled(i,j,3)=1;
            
        end    
            
        end    
    end
  