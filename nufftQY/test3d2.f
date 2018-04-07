	program test
	implicit none
        
        integer r,kflag
        parameter (r=563,kflag=-1)
        integer ms
        parameter (ms=48)
        integer nj
        parameter (nj=ms*ms*ms)
        integer i,iflag,ier,num,j
        integer,allocatable :: xsub(:,:),xxsub(:)
        integer n1,n2,mt,k1,k2,mm,k3
        real*16 begin1,end1
        integer*8  time_begin,time_end,countrage,countmax
        real*16,allocatable :: U1(:,:),V1(:,:),U2(:,:),V2(:,:)
        real*16 time1,time2
        real*16 arr(4)
        real*8 pi
        real*8,allocatable :: xj(:),yj(:),zj(:)
        parameter (pi=3.141592653589793238462643383279502884197d0)
        complex*16,allocatable :: U(:,:),V(:,:),cj(:),S(:)
        complex*16,allocatable :: fk(:,:,:),fk1(:),uu(:,:,:,:)
        complex*16,allocatable :: NN(:,:,:,:)
        real*8 eps,error
        real*8,allocatable :: x(:,:)
        double complex in1, out1
        dimension in1(ms,ms,ms), out1(ms,ms,ms)
        integer*16 :: plan
        integer FFTW_FORWARD,FFTW_MEASURE
        parameter (FFTW_FORWARD=-1)
        parameter (FFTW_MEASURE=0)

        character*8 date
        character*10 time
        character*5 zone
        integer*4 values1(8),values2(8)

        allocate(U1(r,nj))
        allocate(U2(r,nj))
        allocate(V1(r,ms*ms*ms))
        allocate(V2(r,ms*ms*ms))
        allocate(xj(nj))
        allocate(yj(nj))
        allocate(zj(nj))
        allocate(S(nj))
        allocate(fk1(nj))
        allocate(U(nj,r))
        allocate(V(r,ms*ms*ms))
        allocate(cj(ms*ms*ms))
        allocate(fk(ms,ms,ms))
        allocate(uu(ms,ms,ms,r))
        allocate(xsub(nj,3))
        allocate(xxsub(nj))
        allocate(x(nj,3))
        
        arr(1)=3600
        arr(2)=60
        arr(3)=1
        arr(4)=0.001


        iflag=-1
        eps=1E-8
        num=1
        
        open(unit = 10,file = 'U3r2.txt')
        read(10,*) U1
        open(unit = 20,file = 'V3r2.txt')
        read(20,*) V1
        open(unit = 10,file = 'U3i2.txt')
        read(10,*) U2
        open(unit = 10,file = 'V3i2.txt')
        read(10,*) V2
        !open(unit = 10,file = 'Re2r1.txt')
        !read(10,*) re1
        !open(unit = 10,file = 'Re2i1.txt')
        !read(10,*) re2
        !re=dcmplx(re1,re2)


        call dfftw_plan_dft_3d(plan,ms,ms,ms,in1,out1,FFTW_FORWARD,0)

        print *,'start 3D type 2 testing:'
        print *,'nj  =',nj,'ms  =',ms
        print *,'rank r = ',r
        print *,'eps             =',eps
        !re=dcmplx(re1,re2)        
        U=transpose(dcmplx(U1,U2))
        
        V=dcmplx(V1,V2)
        V=conjg(V)
        !print *,V(1:5,1)
        if (kflag .lt. 0) then
		uu=reshape(transpose(V),(/ms,ms,ms,r/))
		mm=floor(ms/2.0+0.6)
		allocate(NN(mm,mm,mm,r))
		NN=uu(1:mm,1:mm,1:mm,:)
		uu(1:mm,1:mm,1:mm,:)=uu(mm+1:ms,mm+1:ms,mm+1:ms,:)
		uu(mm+1:ms,mm+1:ms,mm+1:ms,:)=NN
		NN=uu(1:mm,mm+1:ms,1:mm,:)
		uu(1:mm,mm+1:ms,1:mm,:)=uu(mm+1:ms,1:mm,mm+1:ms,:)
		uu(mm+1:ms,1:mm,mm+1:ms,:)=NN
		NN=uu(mm+1:ms,1:mm,1:mm,:)
		uu(mm+1:ms,1:mm,1:mm,:)=uu(1:mm,mm+1:ms,mm+1:ms,:)
		uu(1:mm,mm+1:ms,mm+1:ms,:)=NN
		NN=uu(mm+1:ms,mm+1:ms,1:mm,:)
		uu(mm+1:ms,mm+1:ms,1:mm,:)=uu(1:mm,1:mm,mm+1:ms,:)
		uu(1:mm,1:mm,mm+1:ms,:)=NN
		V=transpose(reshape(uu,(/ms*ms*ms,r/)))
        endif
        !print *,'V=',V(1,1)
        !U=conjg(U)
        !print *,V(2,:)
        !print *,U(1,:)
        
        do k3 = -ms/2,(ms-1)/2
	 do k1 = -ms/2, (ms-1)/2
	   do k2 = -ms/2, (ms-1)/2
	      j =  (k1+ms/2+1) + (k2+ms/2)*ms + (k3+ms/2)*ms*ms
	      xj(j) = pi*dcos(-pi*k1/ms)
	      yj(j) = pi*dcos(-pi*k2/ms)
	      zj(j) = pi*dcos(-pi*k3/ms)
	      cj(j) = dcmplx(dsin(pi*j/ms),dcos(pi*j/ms))
	   enddo
	 enddo
        enddo
        x(:,1)=xj
        x(:,2)=yj
        x(:,3)=zj
        xsub=mod(floor(x/2/pi*ms+0.5),ms)+1
        do i = 1,nj
           xxsub(i)=xsub(i,3)*ms*ms-ms*ms+xsub(i,2)*ms-ms+xsub(i,1)
        enddo
        !print *,'xxsub=',size(xxsub)
        call date_and_time(date,time,zone,values1)
        do i=1,num
        call nufft3dIIapp(nj,plan,cj,U,V,xxsub,ms,kflag,r,S)
        enddo
        call date_and_time(date,time,zone,values2)
        !print *,'S(1:5)=',S(1:5)
        time1=sum((values2(5:8)-values1(5:8))*arr)
        print *,' T_our         = ',time1/num
        
        call date_and_time(date,time,zone,values1)
        do i=1,num
        call nufft3d2f90(nj,xj,yj,zj,fk,iflag,eps,ms,ms,ms,cj,ier)
        enddo
        call date_and_time(date,time,zone,values2)
        time2=sum((values2(5:8)-values1(5:8))*arr)
        print *,' T_nyu         = ',time2/num
        print *,' T_our/T_nyu   = ',time1/time2
        fk1=reshape(fk,(/nj/))
        error=sqrt(real(sum((S-fk1)*conjg(S-fk1))/
     &  sum(fk1*conjg(fk1))))
        print *,' relative error= ',error
        
        call dfftw_destroy_plan(plan)
        

	end program
