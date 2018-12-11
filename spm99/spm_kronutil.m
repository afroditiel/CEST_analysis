function varargout = spm_kronutil(varargin)
% doing things with Kronecker Tensor Products - a compiled routine
% FORMAT [alpha,beta]=spm_kronutil(img1,img2,b1,b2)
%
% Performs:
% 
% 	[m1,m2]=size(img1);
% 	[m1,m2]=size(img2);
% 	[m1,n1]=size(b1);
% 	[m2,n2]=size(b2);
% 
% 	alpha = zeros(n1*n2,n1*n2);
% 	beta  = zeros(n1*n2,1);
% 	for i=1:m2
% 		tmp   = kron(img1(:,i),ones(1,n1)).*b1;
% 		alpha = alpha + kron(b2(i,:)'*b2(i,:),  tmp'*tmp);
% 		beta  = beta  + kron(b2(i,:)', tmp'*img2(:,i));
% 	end
% 
% which is equivalent to, but a lot faster than:
% 
% 	B     = kron(b2,b1);
% 	A     = diag(img1(:))*B;
% 	b     = img2(:);
% 	alpha = A'*A;
% 	beta  = A'*b;
%_______________________________________________________________________
% @(#)spm_kronutil.m	2.2 John Ashburner 99/04/19

%-This is merely the help file for the compiled routine
error('spm_kronutil.c not compiled - see spm_MAKE.sh')
