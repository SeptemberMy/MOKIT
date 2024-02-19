! written by jxzou at 20210115: generate Gaussian .gjf from ORCA .mkl file
! TODO: un-normalize the contracted coefficients of each basis function (this
!       does affect the calculation)

! Note: this utility can only be applied to all-electron basis set, since the
!  .mkl file does not contain ECP information

! The 'Shell types' array in Gaussian .fch file:
!
!   Spherical     |   
! -5,-4,-3,-2,-1, 0, 1
!  H  G  F  D  L  S  P
!
! 'L' is 'SP' in Pople-type basis sets

program main
 implicit none
 integer :: i
 character(len=240) :: mklname, gjfname

 i = iargc()
 if(.not. (i==1 .or. i==2)) then
  write(6,'(/,A)') ' ERROR in subroutine mkl2gjf: wrong command line arguments.'
  write(6,'(A)')   ' Example 1: mkl2gjf a.mkl'
  write(6,'(A,/)') ' Example 2: mkl2gjf a.mkl b.gjf'
  stop
 end if

 mklname = ' '
 call getarg(1, mklname)
 call require_file_exist(mklname)

 if(i == 2) then
  call getarg(2, gjfname)
 else
  call find_specified_suffix(mklname, '.mkl', i)
  gjfname = mklname(1:i-1)//'.gjf'
 end if

 call mkl2gjf(mklname, gjfname)
end program main

! generate Gaussian .gjf from ORCA .mkl file
subroutine mkl2gjf(mklname, gjfname)
 use mkl_content
 implicit none
 integer :: i, j, k, nc, nline, ncol, fid, nfmark, ngmark, nhmark
 integer, allocatable :: f_mark(:), g_mark(:), h_mark(:)
 real(kind=8), allocatable :: coeff(:,:)
 character(len=240), intent(in) :: mklname, gjfname
 logical :: uhf

 call find_specified_suffix(gjfname, '.gjf', i)
 open(newunit=fid,file=TRIM(gjfname),status='replace')
 write(fid,'(A)') '%chk='//gjfname(1:i-1)//'.chk'
 write(fid,'(A)') '%nprocshared=4'
 write(fid,'(A)') '%mem=4GB'

 call check_uhf_in_mkl(mklname, uhf)
 call read_mkl(mklname, uhf, .true.)
 deallocate(shl2atm)

 if(ANY(nuc > 18)) then
  write(6,'(/,A)') "Warning in subroutine mkl2gjf: element(s)>'Ar' detected."
  write(6,'(A)') 'NOTE: the .mkl file does not contain ECP/PP information. If y&
                 &ou use ECP/PP'
  write(6,'(A)') '(in ORCA .inp file), there would be no ECP in the generated .&
                 &gjf file. You'
  write(6,'(A)') "should manually add ECP data into .gjf, and change 'gen' into&
                 & 'genecp'. If"
  write(6,'(A,/)') 'you are using an all-electron basis set, there is no proble&
                   &m.'
 end if
 deallocate(nuc)

 write(fid,'(A)',advance='no') '#p'
 if(uhf) then
  write(fid,'(A)',advance='no') ' UHF/'
 else
  if(mult /= 1) then
   write(fid,'(A)',advance='no') ' ROHF/'
  else
   write(fid,'(A)',advance='no') ' RHF/'
  end if
 end if
 write(fid,'(A)') 'gen int=nobasistransform nosymm guess=cards'
 ! we do not know using gen or genecp, since ECP data is not included in .mkl

 write(fid,'(/,A,/)') 'generated by utility mkl2gjf in MOKIT'
 write(fid,'(I0,1X,I0)') charge, mult

 ! print elements and Cartesian coordinates
 do i = 1, natom, 1
  write(fid,'(A2,3(1X,F18.8))') elem(i), coor(1:3,i)
 end do ! for i
 deallocate(elem, coor)
 write(fid,'(/)',advance='no')

 ! print basis set
 do i = 1, natom, 1
  write(fid,'(I0,A2)') i, ' 0'
  nc = all_pg(i)%nc

  do j = 1, nc, 1
   nline = all_pg(i)%prim_gau(j)%nline
   ncol = all_pg(i)%prim_gau(j)%ncol
   write(fid,'(A,2X,I0,A)') all_pg(i)%prim_gau(j)%stype, nline, '  1.00'

   do k = 1, nline, 1
    select case(ncol)
    case(2)
     write(fid,'(2ES20.10)') all_pg(i)%prim_gau(j)%coeff(k,1:2)
    case(3)
     write(fid,'(3ES20.10)') all_pg(i)%prim_gau(j)%coeff(k,1:3)
    case default
     write(6,'(/,A)') 'ERROR in subroutine mkl2gjf: ncol out of range.'
     write(6,'(A,I0)') 'ncol=', ncol
     stop
    end select
   end do ! for k
  end do ! for j

  write(fid,'(A)') '****'
 end do ! for i
 deallocate(all_pg)
 ! print basis set done

 ! update MO coefficients
 if(uhf) then ! UHF
  k = 2*nif
  allocate(coeff(nbf,k))
  coeff(:,1:nif) = alpha_coeff
  coeff(:,nif+1:) = beta_coeff
 else         ! R(O)HF
  k = nif
  allocate(coeff(nbf,k), source=alpha_coeff)
 end if

 ! find F+3, G+3 and H+3 functions, multiply them by -1
 allocate(f_mark(ncontr), g_mark(ncontr), h_mark(ncontr))
 call read_bas_mark_from_shltyp(ncontr, shell_type, nfmark, ngmark, nhmark, &
                                f_mark, g_mark, h_mark)
 deallocate(shell_type)
 call update_mo_using_bas_mark(nbf, k, nfmark, ngmark, nhmark, f_mark, g_mark, &
                               h_mark, coeff)
 deallocate(f_mark, g_mark, h_mark)

 if(uhf) then ! UHF
  alpha_coeff = coeff(:,1:nif)
  beta_coeff = coeff(:,nif+1:)
 else         ! R(O)HF
  alpha_coeff = coeff
 end if
 deallocate(coeff)
 ! update MO coefficients done

 write(fid,'(/,A)') '(5E18.10)'
 do i = 1, nif, 1
  write(fid,'(I5,A,E15.8)') i, ' Alpha MO OE=', ev_a(i)
  write(fid,'((5E18.10))') (alpha_coeff(j,i),j=1,nbf)
 end do ! for i
 deallocate(alpha_coeff, ev_a)

 if(uhf) then
  write(fid,'(/)',advance='no')
  do i = 1, nif, 1
   write(fid,'(I5,A,E15.8)') i, ' Beta MO OE=', ev_b(i)
   write(fid,'((5E18.10))') (beta_coeff(j,i),j=1,nbf)
  end do ! for i
  deallocate(beta_coeff, ev_b)
 end if

 write(fid,'(/)')
 close(fid)
end subroutine mkl2gjf

