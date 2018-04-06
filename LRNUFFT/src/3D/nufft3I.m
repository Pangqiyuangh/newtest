function nufft3fun = nufft3I(x,iflag,ns,rt,tol)
% NUFFT2I: Computation of nonuniform FFT2 in R^2 - Type I.
%   gfun = NUFFT2I(x,iflag,ns,rt,tol) provides the fast algorithm for
%   nufft2 of type I. x is the location of sources on interval
%   [0,ns-1]x[0,ns-1], iflag determines the sign of FFT2, and ns is the
%   number of Fourier modes computed. The function returns a function that
%   fast evaluate nufft2.
%
%   NUFFT2 of type I is defined as follows.
%                  n
%     g(k1,k2) = w sum c(j) exp(+/-i 2pi * (k1 x(j,1) + k2 x(j,2)) / ns)
%                  j=1
%   for 1 <= k1, k2 <= ns and 1 <= x(j,1), x(j,2) <= ns.
%   If (iflag .ge.0) the + sign is used in the exponential and a = 1/ns^2.
%   If (iflag .lt.0) the - sign is used in the exponential and a = 1.
%
%   See also FFT, FFT2, NUFFTI, NUFFT2II, NUFFT2III.


if nargin < 2
    iflag = -1;
else
    iflag = sign(iflag);
end

if nargin < 3
    ns = ceil(max(max(x)))+1;
end

if nargin < 4
    rt = 135;
end

if nargin < 5
    tol = 1e-12;
end

[k1,k2,k3] = ndgrid(0:ns-1,0:ns-1,0:ns-1);
k = [k1(:) k2(:) k3(:)];

fftconst = iflag*1i/ns*2*pi;

ratiofun = @(k,x)exp(fftconst*k*(x-round(x))');
[U,V] = lowrank(k,x,ratiofun,tol,rt,rt);

xsub = mod(round(x),ns)+1;
xxsub = sub2ind([ns ns ns],xsub(:,1),xsub(:,2),xsub(:,3));
spPerm = sparse(xxsub,1:ns^3,ones(1,ns^3),ns^3,ns^3);
r = size(V,2);

nufft3fun = @(c)nufft3Ifun(c);

    function fft3c = nufft3Ifun(c)
        [n,ncol] = size(c);
        
        c = repmat(conj(V),1,ncol).*reshape(repmat(c,r,1),n,r*ncol);
        c = reshape(spPerm*c,ns,ns,ns,r*ncol);
        if iflag < 0
            fft3c = fft3(c);
        else
            fft3c = ifft3(c);
        end
        fft3c = squeeze( sum( reshape( ...
            repmat(U,1,ncol).*reshape(fft3c,ns^3,r*ncol), n, r, ncol), 2) );
    end

end