%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%
%-%                                                                     %-%
%-%          A R E A   U N D E R   T H E   C U R V E   ! ! !            %-%
%-%                                                                     %-%
%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%
%done on STAsym interpolated data (interpolated_*.STAsym) and 
%baseline-subtraction interpolated data (BS_interpolated_mean_*)%% AUC for STAsym interpolated data
for ii = 1 : length(data_in_ppm_sets)
  % sum_roi
  [auc_STAsym_sum_roi(ii)] = ...
       auc(interpolated_sum_roi(ii).ppm_positive, interpolated_sum_roi(ii).STAsym, ...
           input.ppm_mid_point_of_auc, input.width_integral, ...
           input.endpoint_auc_from_zero);
  % Rsqr_sum_roi
  [auc_STAsym_Rsqr_sum_roi(ii)] = ...
       auc(interpolated_Rsqr_sum_roi(ii).ppm_positive, ...
           interpolated_Rsqr_sum_roi(ii).STAsym, ...
           input.ppm_mid_point_of_auc, input.width_integral, ...
           input.endpoint_auc_from_zero);
  % Rsqr_rois
  if masks.number_of_rois > 1 
    for kk = 1 : masks.number_of_rois
      [auc_STAsym_Rsqr_rois(kk,ii)] = auc(interpolated_Rsqr_rois(kk,ii).ppm_positive, ...
                                        interpolated_Rsqr_rois(kk,ii).STAsym, ...
                                        input.ppm_mid_point_of_auc, input.width_integral, ...
                                        input.endpoint_auc_from_zero);      
    end
  end
  % pixels
  for ll = 1 : size(interpolated_pixels,2)
    [auc_STAsym_pixels(ii,ll)] = auc(interpolated_pixels(ii,ll).ppm_positive, ...
                                     interpolated_pixels(ii,ll).STAsym, ...
                                     input.ppm_mid_point_of_auc, ...
                                     input.width_integral, ...
                                     input.endpoint_auc_from_zero);
  end
end

%% AUC for baseline-subtraction interpolated data
% only done on the 1st approach BS data that is to average the raw baselines 
% and then interpolate ("BS_interpolated_mean_*" variables).
for ii = 1 : length(data_in_ppm_sets)
  % sum_roi
  [auc_BS_sum_roi(ii)] = auc(interpolated_sum_roi(ii).ppm, ...
                             BS_interpolated_mean_sum_roi(ii,:), ...
                             input.ppm_mid_point_of_auc, input.width_integral, ...
                             input.endpoint_auc_from_zero);
  % Rsqr_sum_roi
  [auc_BS_Rsqr_sum_roi(ii)] = auc(interpolated_Rsqr_sum_roi(ii).ppm, ...
                                BS_interpolated_mean_Rsqr_sum_roi(ii,:), ...
                                input.ppm_mid_point_of_auc, input.width_integral, ...
                                input.endpoint_auc_from_zero);
  % Rsqr_rois
  if masks.number_of_rois > 1 
    for kk = 1 : masks.number_of_rois
      [auc_BS_Rsqr_rois(kk,ii)] = auc(interpolated_Rsqr_rois(kk,ii).ppm, ...
                                    BS_interpolated_mean_Rsqr_rois(kk,ii,:), ...
                                    input.ppm_mid_point_of_auc, input.width_integral, ...
                                    input.endpoint_auc_from_zero);      
    end
  end
  % pixels 
  for ll = 1 : size(interpolated_pixels,2)
    [auc_BS_pixels(ii,ll)] = auc(interpolated_pixels(ii,ll).ppm, ...
                             BS_interpolated_mean_pixels(ii,:,ll), ...
                             input.ppm_mid_point_of_auc, input.width_integral, ...
                             input.endpoint_auc_from_zero);
  end
end
