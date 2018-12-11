
% Sets the defaults which are used by SPM
%
% FORMAT spm_defaults
%_______________________________________________________________________
%
% This file is intended to be customised for the site.
% Individual users can make copies which can be stored in their own
% matlab subdirectories. If ~/matlab is ahead of the SPM directory
% in the MATLABPATH, then the users own personal defaults are used.
%
% Care must be taken when modifying this file
%_______________________________________________________________________
% @(#)spm_defaults.m	2.14 John Ashburner, Andrew Holmes 99/10/29

global PRINTSTR LOGFILE CMDLINE GRID
global PET_UFp PET_DIM PET_VOX PET_TYPE PET_SCALE PET_OFFSET PET_ORIGIN PET_DESCRIP
global fMRI_UFp fMRI_DIM fMRI_VOX fMRI_TYPE fMRI_SCALE fMRI_OFFSET fMRI_ORIGIN fMRI_DESCRIP
global fMRI_T fMRI_T0

% Default command for printing
%-----------------------------------------------------------------------
PRINTSTR = [spm_figure('DefPrintCmd'),'spm99.ps'];

% Log user input to SPM. If LOGFILE is '', then don't log.
%-----------------------------------------------------------------------
LOGFILE = '';

% Command Line
% Values can be:
%       0 - GUI for input and file selection
%       1 - command line for input and file selection
%      -1 - command line for input, GUI for file selection
%-----------------------------------------------------------------------
CMDLINE = 0;

% GRID should be in the range of 0 to 1.
% It determines the intensity of any grids which are superimposed
% on displayed images.
%-----------------------------------------------------------------------
GRID = 0.4;


% Header defaults
%=======================================================================

% PET header defaults
%-----------------------------------------------------------------------
PET_DIM      = [128 128 63];		% Dimensions [x y z]
PET_VOX      = [2.09 2.09 2.37];		% Voxel size [x y z]
PET_TYPE     = 2;			% Data type
PET_SCALE    = 1.0;			% Scaling coeficient
PET_OFFSET   = 0;			% Offset in bytes
PET_ORIGIN   = [0 0 0];			% Origin in voxels
PET_DESCRIP  = 'SPM-compatible';

% fMRI header defaults
%-----------------------------------------------------------------------
fMRI_DIM     = [64 64 64];		% Dimensions [x y z]
fMRI_VOX     = [3 3 3];			% Voxel size [x y z]
fMRI_TYPE    = 4;			% Data type
fMRI_SCALE   = 1;			% Scaling coeficient
fMRI_OFFSET  = 0;			% Offset in bytes
fMRI_ORIGIN  = [0 0 0];			% Origin in voxels
fMRI_DESCRIP = 'SPM-compatible';

% Stats defaults
%=======================================================================

% UFp - Upper tail F probability threshold used to filter voxels after
% stats
%-----------------------------------------------------------------------
PET_UFp  = 0.05;
fMRI_UFp = 0.001;


% Realignment defaults
%=======================================================================
global sptl_WhchPtn sptl_CrtWht sptl_DjstFMRI sptl_MskOptn sptl_RlgnQlty
global sptl_WghtRg

% Which Option?
% This gives the flexibility for coregistering and reslicing images
% seperately, or alternatively reduces flexibility and keeps things
% simple for the user.
%-----------------------------------------------------------------------
%sptl_WhchPtn = 1;	% Combine coregistration and reslicing 
sptl_WhchPtn = -1;	% Allow separate coregistration and reslicing


% Create What? Give flexibility about which images are written resliced,
% or remove an extra question.
%-----------------------------------------------------------------------
%sptl_CrtWht = 1;	% All Images + Mean Image
sptl_CrtWht = -1;	% Full options

% Adjust FMRI?
% Adjust the data (fMRI) to remove movement-related components
% The adjustment procedure is based on a autoregression-moving 
% average-like model of the effect of position on signal and 
% explicitly includes a spin excitation history effect.
%-----------------------------------------------------------------------
%sptl_DjstFMRI =  0;	% Never adjust
%sptl_DjstFMRI =  1;	% Always adjust
sptl_DjstFMRI = -1;	% Optional adjust

% Mask Option.
% To avoid artifactual movement-related variance the realigned
% set of images can be internally masked, within the set (i.e.
% if any image has a zero value at a voxel than all images have
% zero values at that voxel).  Zero values occur when regions
% 'outside' the image are moved 'inside' the image during
% realignment.
%-----------------------------------------------------------------------
%sptl_MskOptn = -1;	% Optional mask
sptl_MskOptn =  1;	% Always mask

% Quality versus speed trade-off.  Highest quality (1) gives most
% precise results, whereas lowest quality gives fastest realignment.
% The idea is that some voxels contribute little to the estimation of
% the realignment parameters.  The sptl_RlgnQlty variable selects the
% number of voxels that are used.
%-----------------------------------------------------------------------
sptl_RlgnQlty = 0.5;
% sptl_RlgnQlty = 1.0; % Best, but slowest

% Weight Registration? 
% Give the option of providing a weighting image to weight each voxel
% of the reference image differently when estimating the realignment
% parameters.  The weights are proportional to the inverses of the
% standard deviations.
%-----------------------------------------------------------------------
sptl_WghtRg = 0;     % Dont give option to supply a weighting image.
%sptl_WghtRg = 1;     % Give option to supply a weighting image.


% Coregistration defaults
%=======================================================================
global sptl_QckCrg sptl_UsMtlInfrmtn

% Option to just do a quick between mode coregistration
% This option misses out the segmenting, and coregistering segments
% steps.
%-----------------------------------------------------------------------
%sptl_QckCrg = 1;	% Quick and simple
sptl_QckCrg = 0;	% Full

% Option to use Mutual Information coregistration.
%-----------------------------------------------------------------------
sptl_UsMtlInfrmtn = 0; % Dont use MI
%sptl_UsMtlInfrmtn = 1; % Use MI

% Spatial Normalisation defaults
%=======================================================================
global sptl_Ornt sptl_CO sptl_NAP sptl_NBss sptl_NItr sptl_BB sptl_Vx
global sptl_Rglrztn sptl_MskBrn sptl_MskObj

% Orientation/position of images. Used as a starting estimate for
% affine normalisation.
%-----------------------------------------------------------------------
%sptl_Ornt = [0 0 0  0 0 0  1 1 1 0 0 0]; % Neurological Convention (R is R)
sptl_Ornt = [0 0 0  0 0 0 -1 1 1 0 0 0]; % Radiological Convention (L is R)


% Customisation Option. Include option to customise the normalisation
% options.
% ie. # affine params, # nonlinear basis images & # nonlinear iterations.
%-----------------------------------------------------------------------
%sptl_CO = -1;		% Allow customised
sptl_CO  =  1;		% Disallow Customised

% Number of nonlinear basis functions
%-----------------------------------------------------------------------
%sptl_NBss = [0 0 0];	% None (ie. perform affine normalisation only).
sptl_NBss = [7 8 7];

% Regularization fudge factor:
%	small values	-> less regularization -> more warping
%	large values	-> more regularization -> less warping
%-----------------------------------------------------------------------
sptl_Rglrztn = 0.01;

% Number of iterations of nonlinear spatial normalisation.
%-----------------------------------------------------------------------
sptl_NItr = 12;

% Estimate the spatial normalization parameters from region specified
% by the image sptl_MskBrn, or use the whole volume.
%-----------------------------------------------------------------------
%sptl_MskBrn = ''; % Estimate from the whole head
sptl_MskBrn = fullfile(spm('Dir'),'apriori','brainmask.img');

% Estimate the spatial normalization parameters from only a limited
% region of the object image.  This is intended for spatially
% normalizing brains with lesions etc., by incorporating weighting
% via an image with values between zero and one that matches the space
% of the object image.
%-----------------------------------------------------------------------
sptl_MskObj = 0; % Estimate from the whole FOV of object image
%sptl_MskObj = 1; % Estimate using a weighting image

% Bounding Box. The definition of the volume of the normalised image
% which is written (mm relative to AC).
% [[lowX lowY lowZ];[highX highY highZ]]
%-----------------------------------------------------------------------
sptl_BB = [[-78 -112 -50];[78 76 85]];
%sptl_BB = [[-90 -126 -72];[91 91 109]];

% Voxel sizes in mm of the normalised images
%-----------------------------------------------------------------------
sptl_Vx = [2 2 2];	% 2mm x 2mm x 2mm

% fMRI defaults for time sampling
%-----------------------------------------------------------------------
fMRI_T = 16;
fMRI_T0 = 1;

