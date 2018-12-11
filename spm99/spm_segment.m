function spm_segment(PF,PG,opts)
% Segment an MR image into Gray, White, CSF & other.
%
% --- The Prompts Explained ---
%
% 'select MRI(s) for subject '
% If more than one volume is specified (eg T1 & T2), then they must be
% in register (same position, size, voxel dims etc..).
%
% 'select Template(s) '
% If the images have been spatially normalised, then there is no need to
% select any images. Otherwise, select one or more template images which
% will be used for affine normalisation of the images. Note that the
% affine transform is only determined from the first image specified
% for segmentation. 
%
% 'Attempt to correct intensity inhomogeneities?'
% This uses a Bayesian framework (again) to model intensity
% inhomogeneities in the image(s).  The variance associated with each
% tissue class is assumed to be multiplicative (with the
% inhomogeneities).  The low frequency intensity variability is
% modelled by a linear combination of three dimensional DCT basis
% functions (again), using a fast algorithm (again) to generate the
% curvature matrix.  The regularization is based upon minimizing the
% integral of square of the third derivatives of the modulation field
% (the integral of the squares of the first and second derivs give the
% membrane and bending energies respectively).  A small amount of
% regularization is used when correcting for `Lots of inhomogeneity',
% whereas more regularization is used for `A little inhomogeneity'.
%
%_______________________________________________________________________
%
%                      The algorithm is three step:
%
% 1) Determine the affine transform which best matches the image with a
%    template image. If the name of more than one image is passed, then
%    the first image is used in this step. This step is not performed if
%    no template images are specified.
%
% 2) Perform Cluster Analysis with a modified Mixture Model and a-priori
%    information about the likelihoods of each voxel being one of a
%    number of different tissue types. If more than one image is passed,
%    then they they are all assumed to be in register, and the voxel
%    values are fitted to multi-normal distributions.
%
% 3) Write the segmented image. The names of these images have
%    "_seg1", "_seg2" & "_seg3" appended to the name of the
%    first image passed.
%
%_______________________________________________________________________
% Refs:
%
% Ashburner J & Friston KJ (1997) Multimodal Image Coregistration and
% Partitioning - a Unified Framework. NeuroImage 6:209-217
%
%_______________________________________________________________________
%
% The template image, and a-priori likelihood images are modified
% versions of those kindly supplied by Alan Evans, MNI, Canada
% (ICBM, NIH P-20 project, Principal Investigator John Mazziotta).
%_______________________________________________________________________
% @(#)spm_segment.m	2.12 John Ashburner 00/02/10

% Programmers notes
%
% FORMAT spm_segment(PF,PG,opts)
% PF   - name(s) of image(s) to segment (must have same dimensions).
% PG   - name(s) of template image(s) for realignment.
%      - or a 4x4 transformation matrix which maps from the image to
%        the set of templates.
% opts - options string.
%        - 't' - write images called *_seg_tmp* rather than *_seg*
%                (that are smoothed with an 8mm Gaussian).
%        - 'f' - fix number of voxels in each cluster
%        - 'c' - attempt to correct small intensity inhomogeneities
%        - 'C' - attempt to correct large intensity inhomogeneities
%        - 'w' - write inhomogeneity corrected image(s) (with the 'c'
%                or 'C' options only)
%
debug = 0;


linfun = inline('fprintf([''%-60s%s''],x,[sprintf(''\b'')*ones(1,60)])','x');

if nargin<3
	% set to ' ' rather than '' to get rid of annoying warnings
	%opts = 'f';
	opts = ' ';
	if nargin<2
		PG = '';
	end
end

global SWD
DIR1   = fullfile(SWD,'templates');
DIR2   = fullfile(SWD,'apriori');

if (nargin==0)
	SPMid = spm('FnBanner',mfilename,'2.12');
	[Finter,Fgraph,CmdLine] = spm('FnUIsetup','Segment');
	spm_help('!ContextHelp','spm_segment.m');

	n     = spm_input('number of subjects',1,'e',1);
	if n < 1,
		spm_figure('Clear','Interactive');
		return;
	end;


	for i = 1:n,
		PF = spm_get(Inf,'.img',...
			['Select MRI(s) for subject ' num2str(i)]);
		eval(['PF' num2str(i) ' = PF;']);
	end;

	PG = '';

	if spm_input('Are they spatially normalised?', 1, 'y/n') == 'n',
		% Get template
		%-----------------------------------------------------------------------
		templates = str2mat(	fullfile(DIR1,'T1.img'),...
					fullfile(DIR1,'T2.img'),...
					fullfile(DIR1,'PD.img'),...
					fullfile(DIR1,'EPI.img'));

		% Get modality of target
		respt = spm_input('Modality of first image?','+1','m',...
			'modality - T1 MRI|modality - T2 MRI|modality - PD MRI|modality - EPI MR|--other--',...
			[1 2 3 4 0],1);
		if respt > 0,
			PG = deblank(templates(respt,:));
		else,
			ok = 0;
			while ~ok,
				PG = spm_get(Inf,'.img',['Select Template(s) for affine matching'],DIR1);
				if size(PG,1)>0,
					vv = spm_vol(PG);
					if prod(size(vv))==1,
						ok = 1;
					else,
						tmp1 = cat(1,vv.dim);
						tmp2 = cat(3,vv.mat);
						if ~any(any(diff(tmp1(:,1:3)))) & ~any(any(any(diff(tmp2,1,3)))),
							ok=1;
						end;
					end;
				else,
					ok = 0;
				end;
			end;
		end;
	end;

	tmp = spm_input('Attempt to correct intensity inhomogeneities?',...
		'+1','m',...
		['No inhomogeneity correction|' ...
		 'A little inhomogeneity correction|' ...
		 'Lots of inhomogeneity correction'],...
		[' ' 'c' 'C'],1);
	opts = [tmp opts];
	if any(opts == 'c') | any(opts == 'C'),
		tmp = spm_input('Save inhomogeneity corrected images ?',...
			'+1','m',...
			['Don''t save corrected images|' ...
			 'Save inhomogeneity corrected images'],...
			[' ' 'w'],1);
		opts = [tmp opts];
	end;

	spm('Pointer','Watch');
	for i = 1:n,
		spm('FigName',['Segment: working on subj ' num2str(i)],Finter,CmdLine);
		fprintf('\Segmenting Subject %d: ', i);

		eval(['PF = PF' num2str(i) ';']);
		if (size(PF,1)~=0) spm_segment(PF,PG,opts); end
	end;

	fprintf('\r%60s%s', ' ',sprintf('\b')*ones(1,60));
	spm_figure('Clear','Interactive');
	spm('FigName','Segment: done',Finter,CmdLine);
	spm('Pointer');
	return;
end;

%_______________________________________________________________________
%_______________________________________________________________________

%- A-Priori likelihood images.
PB    = str2mat(	fullfile(DIR2,'gray.img'),...
			fullfile(DIR2,'white.img'),...
			fullfile(DIR2,'csf.img'));

niter     = 64;        % Maximum number of iterations of Mixture Model
nc        = [1 1 1 3]; % Number of clusters for each probability image


% Determine matrix MM that will transform the image to Talairach space.
%_______________________________________________________________________
if ~isempty(PG) & isstr(PG)
	% Affine registration so that a priori images match the image to
	% be segmented.
	%-----------------------------------------------------------------------
	linfun('Smoothing..');
	VG = spm_vol(PG);
	for i=1:prod(size(VG)),
		VG(i).pinfo(1:2,:) = VG(i).pinfo(1:2,:)/spm_global(VG(i));
	end;

	spm_smooth(PF(1,:),'spm_seg_tmp.img',8);
	VF = spm_vol('spm_seg_tmp.img');
	VF.pinfo(1:2,:) = VF.pinfo(1:2,:)/spm_global(VF);

	global sptl_MskBrn
	VW = [];
	if ~isempty(sptl_MskBrn), VW = spm_vol(sptl_MskBrn); end;

	% perform affine normalisation at different sampling frequencies
	% with increasing numbers of parameters.
	linfun('Determining Affine Mapping..');
	global sptl_Ornt
	if prod(size(sptl_Ornt)) == 12,
		prms = [sptl_Ornt ones(1,size(PG,1))]';
	else,
		prms = [0 0 0  0 0 0  1 1 1  0 0 0 ones(1,size(PG,1))]';
	end;
	spm_chi2_plot('Init','Affine Registration','Convergence');
	prms = spm_affsub3('affine3', VG, VF, 1, 8, prms);
	prms = spm_affsub3('affine3', VG, VF, 1, 6, prms, VW);
	spm_chi2_plot('Clear');
	spm_unlink(	'spm_seg_tmp.img',...
			'spm_seg_tmp.hdr',...
			'spm_seg_tmp.mat')
	MM = spm_matrix(prms);

elseif all(size(PG) == [4 4])
	% Assume that second argument is a matrix that will do the job
	%-----------------------------------------------------------------------
	MM = PG;
else
	% Assume that image is normalized
	%-----------------------------------------------------------------------
	MM = spm_matrix([0 0 0 0 0 0 1 1 1 0 0 0]');
end

VF = spm_vol(PF);
VB = spm_vol(PB);
m  = size(PF,1);
%-----------------------------------------------------------------------



% Voxels to sample during the cluster analysis
%-----------------------------------------------------------------------

% A bounding box for the brain in Talairach space.
bb1 = [ [-88 88]' [-122 86]' [-60 95]'];

% A mapping from a unit radius sphere to a hyper-ellipse
% that is just enclosed by the bounding box in Talairach
% space.
M0 = [diag(diff(bb1)/2) mean(bb1)';[0 0 0 1]];

% The mapping from voxels to Talairach space is
% MM*VF(1).mat, so the ellipse in the space
% of the first image becomes:
M0 = inv(MM*VF(1).mat)*M0;

% So to work out the bounding box in the space of the
% image that just encloses the hyper-ellipse.
tmp = M0(1:3,1:3);
tmp = diag(tmp*tmp'/diag(sqrt(diag(tmp*tmp'))));
bb  = round([M0(1:3,4)-tmp M0(1:3,4)+tmp])';

% Want to sample about every 4mm
tmp  = inv(VF(1).mat);
tmp  = tmp(1:3,1:3);
samp = round(max(abs(tmp*[4 4 4]'), [1 1 1]'));
%-----------------------------------------------------------------------



reg = 0;
if any(opts == 'c') | any(opts == 'C')
	% I don't know what the best values for reg are yet.
	% I guess a bit more experimentation is needed.
	reg = 10000000; co = 32;
	if any(opts == 'C'), reg = 1000000; co = 25; end

	% Stuff for intensity modulation
	%-----------------------------------------------------------------------
	% Set up basis functions
	tmp = sqrt(sum(VF(1).mat(1:3,1:3).^2));
	nbas = max(round((VF(1).dim(1:3).*tmp)/co),[1 1 1]);
	B1=spm_dctmtx(VF(1).dim(1),nbas(1),bb(1,1):samp(1):bb(2,1));
	B2=spm_dctmtx(VF(1).dim(2),nbas(2),bb(1,2):samp(2):bb(2,2));
	B3=spm_dctmtx(VF(1).dim(3),nbas(3),bb(1,3):samp(3):bb(2,3));

	d = [size(B1,1) size(B2,1) size(B3,1)];

	% Set up a priori covariance matrix - based on energy per
	% millimeter
	mm = sqrt(sum(VF(1).mat(1:3,1:3).^2)).*VF(1).dim(1:3);
	kx=(pi*((1:nbas(1))'-1)/mm(1)).^2; ox=ones(nbas(1),1);
	ky=(pi*((1:nbas(2))'-1)/mm(2)).^2; oy=ones(nbas(2),1);
	kz=(pi*((1:nbas(3))'-1)/mm(3)).^2; oz=ones(nbas(3),1);

	% Cost function based on sum of squared 3rd derivatives
	IC0 = (	  kron(kz.*kz.*kz,kron(oy        ,ox        )) + ...
		  kron(oz        ,kron(ky.*ky.*ky,ox        )) +...
		  kron(oz        ,kron(oy        ,kx.*kx.*kx)) +...
		3*kron(kz.*kz    ,kron(ky        ,ox        )) + ...
		3*kron(kz.*kz    ,kron(oy        ,kx        )) + ...
		3*kron(kz        ,kron(ky.*ky    ,ox        )) + ...
		3*kron(oz        ,kron(ky.*ky    ,kx        )) +...
		3*kron(kz        ,kron(oy        ,kx.*kx    )) + ...
		3*kron(oz        ,kron(ky        ,kx.*kx    )) +...
		6*kron(kz        ,kron(ky        ,kx        )) )*reg;

	% Unused cost function based upon bending energy..
	% IC0 = (kron(kz.*kz,kron(oy,ox)) + kron(oz,kron(ky.*ky,ox)) + kron(oz,kron(oy,kx.*kx)) +...
	% 	 2*kron(kz,kron(ky,ox))   + 2*kron(kz,kron(oy,kx))   +  2*kron(oz,kron(ky,kx)))*reg;
	% Unused cost function based upon membrane energy..
	% IC0 =(kron(kron(oz,oy),kx) + kron(kron(oz,ky),ox) + kron(kron(kz,oy),ox))*reg;

	% Assume a tiny variance for the DC coefficient.
	IC0(1)     = max(IC0)*1000;
	IC0        = diag(IC0);

	% Mode of the a priori distribution
	X0         = zeros(prod(nbas),1);
	X0(1)      = sqrt(prod(VF(1).dim(1:3)));

	% Initial estimate for intensity modulation field
	T          = zeros(nbas(1),nbas(2),nbas(3),m);
	T(1,1,1,:) = sqrt(prod(VF(1).dim(1:3)));
	%-----------------------------------------------------------------------
else,
	T = sqrt(prod(VF(1).dim(1:3)));
	nbas = [1 1 1];
end;


lkp    = []; for i=1:size(nc,2), lkp = [lkp ones(1,nc(i))*i]; end;

n      = size(lkp,2);
nb     = prod(size(VB));

sumbp  = zeros(1,n);
osumpr = -Inf;

% Occasionally the dynamic range of the images is such that many voxels
% all have the same intensity.  Adding cv0 is an attempt to improve the
% stability of the algorithm if this occurs. The value 0.083 was obtained
% from var(rand(1000000,1)).  It prbably isn't the best way of doing
% things, but it appears to work.
cv0 = zeros(m,m);
for i=1:m, cv0(i,i)=0.083*mean(VF(i).pinfo(1,:)); end;

cv  = zeros(m,m,n);	% (Co)variances
mn  = zeros(m,n);	% Means
mg  = zeros(1,n);	% Number of voxels/cluster

z   = bb(1,3):samp(3):bb(2,3);
d   = [length(bb(1,1):samp(1):bb(2,1)) length(bb(1,2):samp(2):bb(2,2)) length(bb(1,3):samp(2):bb(2,3))];

spm_chi2_plot('Init','Segmenting','Log-likelihood','Iteration #');
for iter = 1:niter,
	linfun(['Segmenting ' num2str(iter) '..']); 

	% Initialize variables that are modified during the loop over each plane
	%-----------------------------------------------------------------------
	sumpr= 0;
	mom0 = zeros(1,n)+eps;
	mom1 = zeros(m,n);
	mom2 = zeros(m,m,n)+eps;

	if reg~=0,
		Alpha = zeros(prod(nbas),prod(nbas),m);
		Beta  = zeros(prod(nbas),m);
	end;

	%-----------------------------------------------------------------------
	for pp = 1:length(z),	% Loop over planes
		clear dat bp pr


		B = spm_matrix([-bb(1,1)/samp(1)+1 -bb(1,2)/samp(2)+1 -z(pp)...
			0 0 0 1/samp(1) 1/samp(2) 1]);

		% Ignore voxels of value zero - since we don't know if it is because they
		% are truly zero - or if it is because they are zeros due to some kind of
		% image editing or from outside the original FOV
		msk = zeros(d(1)*d(2),1);

		for i=1:m,
			M   = VF(i).mat\VF(1).mat*inv(B);
			tmp = spm_slice_vol(VF(i),M, d(1:2),1);
			msk = msk | tmp(:)==0;
			if reg~=0,
				% Non-uniformity correct.
				t = reshape(reshape(T(:,:,:,i),...
					nbas(1)*nbas(2),nbas(3))*B3(pp,:)', nbas(1), nbas(2));
				rawdat(:,:,i) = tmp;
				tmp = tmp.*(B1*t*B2');
			end;
			dat(:,i) = tmp(:);
		end;
		msk = find(~msk);

		% If there are at least some voxels to work with..
		if length(msk)>0,

			% A priori probability data for GM, WM and CSF..
			bp = zeros(d(1)*d(2),nb+1);
			for j=1:nb,
				M       = inv(B*inv(MM*VF(1).mat)*VB(j).mat);
				tmp     = spm_slice_vol(VB(j),M, d(1:2),1)/nc(j);
				bp(:,j) = tmp(:);
			end;
			% A priori probability for all other tissue..
			bp(:,nb+1) = abs(ones(d(1)*d(2),1) - bp(:,1:nb)*nc(1:nb)')/nc(nb+1);

			pr = zeros(d(1)*d(2),n);
			if iter==1,
				% Initial probability estimates based upon
				% a priori knowledge
				%-----------------------------------------------------------------------
				for i=1:n,
					pr(msk,i) = bp(msk,lkp(i));
					sumbp(i)  = sumbp(i) + sum(bp(msk,lkp(i)));
				end;
			else,
				% Compute PDFs for each cluster
				%-----------------------------------------------------------------------
				for i=1:n,
					amp       = 1/sqrt((2*pi)^m * det(cv(:,:,i)));
					dst       = (dat(msk,:)-ones(size(msk,1),1)*mn(:,i)')/sqrtm(cv(:,:,i));
					dst       = sum(dst.*dst,2);
					pr(msk,i) = amp*exp(-0.5*dst).*(bp(msk,lkp(i))*(mg(1,i)/sumbp(i)));
				end;
				%-----------------------------------------------------------------------
			end;

			% Compute log likelihood, and normalize likelihoods to sum to unity
			%-----------------------------------------------------------------------
			sp       = sum(pr(msk,:),2);
			sumpr    = sumpr + sum(log(sp));
			msk2     = find(~sp);
			sp(msk2) = 1;
			for i=1:n, pr(msk,i) = pr(msk,i)./sp; end;
			%-----------------------------------------------------------------------


			% Compute new n, mean & var for each cluster - step 1
			%-----------------------------------------------------------------------
			for i=1:n,
				mom0(1,i)   = mom0(1,i)   + sum(pr(:,i));
				mom1(:,i)   = mom1(:,i)   + sum((pr(:,i)*ones(1,m)).*dat)';
				mom2(:,:,i) = mom2(:,:,i) + ((pr(:,i)*ones(1,m)).*dat)'*dat;
			end;
			%-----------------------------------------------------------------------

			if reg~=0 & iter > 1,
				% Build up A'*A and A'*b to solve for intensity modulations
				%-----------------------------------------------------------------------
				pr  = reshape(pr ,d(1),d(2),n);
				for j=1:m,
					for i=1:2,
						wt = pr(:,:,i)*(cv(j,j,i).^(-0.5));
						if i==1,
							[alpha,beta] = spm_kronutil(wt.*rawdat(:,:,j),wt*mn(j,i),B1,B2);
						else,
							[alph ,bet ] = spm_kronutil(wt.*rawdat(:,:,j),wt*mn(j,i),B1,B2);
							alpha = alpha + alph;
							beta  = beta  + bet;
						end;
					end;
					Alpha(:,:,j) = Alpha(:,:,j) + kron(B3(pp,:)'*B3(pp,:),alpha);
					Beta(:,j)    = Beta(:,j)    + kron(B3(pp,:)', beta);
				end;
				pr  = reshape(pr ,d(1)*d(2),n);
			end;
		end;
	end;

	% Solve for intensity modulations
	%-----------------------------------------------------------------------
	if reg~=0 & iter>1,
		for i=1:m,
			x = (Alpha(:,:,i) + IC0)\(IC0*X0 + Beta(:,i));
			T(:,:,:,i) = reshape(x,nbas);
		end;
	end;
	%-----------------------------------------------------------------------

	if iter>2, spm_chi2_plot('Set',sumpr); end;


	% Compute new n, mean & var for each cluster - step 2
	%-----------------------------------------------------------------------
	for i=1:n,
		mg(1,i)   = mom0(1,i);
		if any(opts == 'f') & i<=nb, mg(1,i) = sumbp(i); end;
		mn(:,i)   = mom1(:,i)/mom0(1,i);

		tmp       = (mom0(1,i).*mn(:,i))*mn(:,i)';
		tmp       = tmp-eye(size(tmp))*eps*1000;
		cv(:,:,i) = (mom2(:,:,i) - tmp)/mom0(1,i) + cv0;
	end;
	%-----------------------------------------------------------------------


	if iter==1,
		% Split the clusters
		%-----------------------------------------------------------------------
		nn = 0;
		for j=1:length(nc),
			for i=2:nc(j),
				cv(:,:,nn+i) = cv(:,:,nn+i)*0.8^(1-i);
				mn(:,nn+i)   = mn(:,nn+i)*0.8^(1-i);
			end;
			nn = nn + nc(j);
		end;

		% Background Cluster.
		%    Strictly speaking, since voxels contain absolute values,
		%    the distributions should be modified accordingly. However
		%    in practice, the only allowance made for this is for the
		%    distribution of a background cluster. The mean of this
		%    cluster is assumed to be zero, and in order for the model
		%    to fit properly, the number of voxels contained in this 
		%    cluster is doubled.
		%-----------------------------------------------------------------------
		mn(:,n)   = zeros(m,1);
		mg(1,n)   = 2*mg(1,n);
		cv(:,:,n) = (mom2(:,:,n))/mom0(1,n);
	end;

	% Stopping criterion
	%-----------------------------------------------------------------------
	if iter == 4,
		sumpr2 = sumpr;
	elseif iter > 4,
		if (sumpr-osumpr)/(sumpr-sumpr2) < 0.0003
			break;
		end;
	end;
	osumpr = sumpr;
end;
spm_chi2_plot('Clear');

%save segmentation_results.mat T mg mn cv MM


%-----------------------------------------------------------------------
%-----------------------------------------------------------------------

% Create headers, open files etc...
%-----------------------------------------------------------------------
dm     = VF(1).dim(1:3);
planes = 1:VF(1).dim(3);
k      = prod(dm(1:2));

if any(opts == 't')
	app  = '_seg_tmp';
	nimg = 2;
else
	app  = '_seg';
	nimg = nb;
end


B1 = spm_dctmtx(VF(1).dim(1),nbas(1));
B2 = spm_dctmtx(VF(1).dim(2),nbas(2));
B3 = spm_dctmtx(VF(1).dim(3),nbas(3));

for j=1:nimg,
	VO(j) = struct(...
		'fname',  [spm_str_manip(PF(1,:),'rd') app num2str(j) '.img'],...
		'dim',    [VF(1).dim(1:3) 2],...
		'mat',    VF(1).mat,...
		'pinfo',  [1/255 0 0]',...
		'descrip','Segmented image');
	spm_create_image(VO(j));
end;

if any(opts == 'w'),
	fpc = ones(m,1)*(-1);
	for j=1:m,
		[pth,nm,xt,vr] = fileparts(deblank(VF(j).fname));
		VC(j) = struct(...
			'fname',  fullfile(pth,['corr_' nm xt vr]),...
			'dim',    [VF(1).dim(1:3) VF(j).dim(4)],...
			'mat',    VF(1).mat,...
			'pinfo',  VF(j).pinfo(:,1),...
			'descrip','Corrected image');
		spm_create_image(VC(j));
	end;
end;


% Write the segmented images.
%-----------------------------------------------------------------------
spm_progress_bar('Init',dm(3),'Writing Segmented','planes completed');
clear pr bp dat dat0

for pp=1:size(planes,2)
	linfun(['Writing Segmented ' num2str(pp) '..']);
	p  = planes(pp);
	B  = spm_matrix([0 0 -p]);
	M2 = B*inv(MM*VF(1).mat);

	for i=1:m,
		% The image data
		M1  = inv(B*(VF(1).mat\VF(i).mat));
		tmp = spm_slice_vol(VF(i), M1, dm(1:2), 1);
		if reg~=0,
			% Apply non-uniformity correction
			t = reshape(reshape(T(:,:,:,i),...
				nbas(1)*nbas(2),nbas(3))*B3(pp,:)', nbas(1), nbas(2));
			t = B1*t*B2';
			dat0(:,i) = tmp(:).*t(:);
		else,
			dat0(:,i) = tmp(:);
		end;
	end;

	bp = zeros(size(dat0,1),nb+1);
	for j=1:nb,
		M       = inv(M2*VB(j).mat);
		tmp     = spm_slice_vol(VB(j), M, dm(1:2),1);
		bp(:,j) = tmp(:)/nc(j);
	end;

	bp(:,nb+1) = abs(ones(k,1) - bp(:,1:nb)*nc(1:nb)')/nc(nb+1);

	for i=1:n,
		amp     = 1/sqrt((2*pi)^m * det(cv(:,:,i)));
		dst     = (dat0-ones(k,1)*mn(:,i)')/sqrtm(cv(:,:,i));
		dst     = sum(dst.*dst,2);
		pr(:,i) = amp*exp(-0.5*dst).*(bp(:,lkp(i))*(mg(1,i)/sumbp(i)));
	end;

	sp = (sum(pr,2)+eps);

	for j=1:nimg,
		tmp = find(lkp(1:(length(lkp)-1))==j);
		if length(tmp) == 1,
			dat = pr(:,tmp);
		else,
			dat = sum(pr(:,tmp),2);
		end;
		spm_write_plane(VO(j),reshape(dat./sp,VO(j).dim(1:2)),pp);
	end;

	if any(opts == 'w'),
		% Write nonuniformity corrected images.
		%-----------------------------------------------------------------------
		for i=1:m,
			spm_write_plane(VC(i),reshape(dat0(:,i),VC(i).dim(1:2)),pp);
		end;
	end;
	spm_progress_bar('Set',pp);
end;
spm_progress_bar('Clear');


% Do the graphics
%=======================================================================
spm_figure('Clear','Graphics');
fg = spm_figure('FindWin','Graphics');
if ~isempty(fg),
	% Show some text
	%-----------------------------------------------------------------------
	ax = axes('Position',[0.05 0.8 0.9 0.2],'Visible','off','Parent',fg);
	text(0.5,0.80, 'Segmentation','FontSize',16,'FontWeight','Bold',...
		'HorizontalAlignment','center','Parent',ax);

	text(0,0.65, ['Image:  ' spm_str_manip(PF(1,:),'k50d')],...
		'FontSize',14,'FontWeight','Bold','Parent',ax);

	text(0,0.40, 'Means:','FontSize',12,'FontWeight','Bold','Parent',ax);
	text(0,0.30, 'Std devs:' ,'FontSize',12,'FontWeight','Bold','Parent',ax);
	text(0,0.20, 'N vox:','FontSize',12,'FontWeight','Bold','Parent',ax);
	for j=1:nb,
		text((j+0.5)/(nb+1),0.40, num2str(mn(1,j)),...
			'FontSize',12,'FontWeight','Bold',...
			'HorizontalAlignment','center','Parent',ax);
		text((j+0.5)/(nb+1),0.30, num2str(sqrt(cv(1,1,j))),...
			'FontSize',12,'FontWeight','Bold',...
			'HorizontalAlignment','center','Parent',ax);
		text((j+0.5)/(nb+1),0.20, num2str(mg(1,j)/sum(mg(1,:))),...
			'FontSize',12,'FontWeight','Bold',...
			'HorizontalAlignment','center','Parent',ax);
	end;
	if m > 1,
		text(0,0.10,...
		'Note: only means and variances for the first image are shown',...
		'Parent',ax,'FontSize',12);
	end;

	% and display a few images.
	%-----------------------------------------------------------------------
	V = spm_vol(deblank(PF(1,:)));
	for j=1:nimg,
		iname = [spm_str_manip(PF(1,:),'rd') app num2str(j) '.img'];
		VS(j) = spm_vol(iname);
	end;
	M1 = VS(1).mat;
	M2 = VF(1).mat;
	for i=1:5,
		M   = spm_matrix([0 0 i*V(1).dim(3)/6]);
		img = spm_slice_vol(V(1),M,V(1).dim(1:2),1);
		img(1,1) = eps;
		ax = axes('Position',[0.05 0.75*(1-i/5)+0.05 0.9/(nb+1) 0.75/5],'Visible','off','Parent',fg);
		imagesc(rot90(img), 'Parent', ax);
		set(ax,'Visible','off','DataAspectRatio',[1 1 1]);

		for j=1:nimg,
			img = spm_slice_vol(VS(j),M2\M1*M,V(1).dim(1:2),1);
			ax  = axes('Position',...
				[0.05+j*0.9/(nb+1) 0.75*(1-i/5)+0.05 0.9/(nb+1) 0.75/5],...
				'Visible','off','Parent',fg);
			image(rot90(img*64), 'Parent', ax);
			set(ax,'Visible','off','DataAspectRatio',[1 1 1]);
		end;
	end;

	spm_print;
	drawnow;
end;


if any(opts == 't'),
	for i=1:nimg,
		linfun(['Smoothing ' num2str(i) '..']);
		iname1 = [spm_str_manip(PF(1,:),'rd') app num2str(i)];
		iname2 = [spm_str_manip(PF(1,:),'rd') '_sseg_tmp' num2str(i)];
		spm_smooth([iname1 '.img'],[iname2 '.img'],8);
		spm_unlink([iname1 '.img'], [iname1 '.hdr'], [iname1 '.mat']);
	end;
end;
linfun(' ');
return;
