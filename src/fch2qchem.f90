! written by jxzou at 20220816: transfer MOs from Gaussian->Q-Chem
! Thanks to wsr for the previous version of fch2qchem (https://gitlab.com/jeanwsr/mokit)

! Current limitations:
! 1) not supported for GHF
! 2) not supported for different basis set for the same element

program main
 use util_wrapper, only: formchk
 implicit none
 integer :: i, npair
 character(len=4) :: str
 character(len=240) :: fchname
 character(len=60), parameter :: error_warn = ' ERROR in subroutine fch2qchem:&
                                              & wrong command line arguments!'

 i = iargc()
 if(.not. (i==1 .or. i==3)) then
  write(6,'(/,A)') error_warn
  write(6,'(A)')   ' Example 1: fch2qchem water.fch'
  write(6,'(A,/)') ' Example 2: fch2qchem water.fch -gvb 2'
  stop
 end if

 call getarg(1, fchname)
 call require_file_exist(fchname)

 str = ' '; npair = 0

 if(i == 3) then
  call getarg(2, str)
  if(str /= '-gvb') then
   write(6,'(/,A)') error_warn
   write(6,'(A)') "The 2nd argument can only be '-gvb'."
   stop
  end if

  call getarg(3, str)
  read(str,*) npair
  if(npair < 0) then
   write(6,'(/,A)') error_warn
   write(6,'(A)') 'The 3rd argument npair should be >=0.'
   stop
  end if
 end if

 ! if .chk file provided, convert into .fch file automatically
 i = LEN_TRIM(fchname)
 if(fchname(i-3:i) == '.chk') then
  call formchk(fchname)
  fchname = fchname(1:i-3)//'fch'
 end if

 call fch2qchem(fchname, npair)
end program main

subroutine fch2qchem(fchname, npair)
 use fch_content
 implicit none
 integer :: i, j, k, m, n, n1, n2, nif1, length, fid, purecart(4)
 integer :: n5dmark, n7fmark, n9gmark, n11hmark
 integer :: n6dmark, n10fmark, n15gmark, n21hmark
 integer :: RENAME, SYSTEM
 integer, intent(in) :: npair
 integer, allocatable :: itmp(:), d_mark(:), f_mark(:), g_mark(:), h_mark(:)
 character(len=1) :: str = ' '
 character(len=2) :: str2 = '  '
 character(len=1), parameter :: am_type(-1:6) = ['L','S','P','D','F','G','H','I']
 character(len=1), parameter :: am_type1(0:6) = ['s','p','d','f','g','h','i']
 character(len=240) :: proname, inpname, dirname
 character(len=240), intent(in) :: fchname
 real(kind=8), allocatable :: coeff(:,:)
 logical :: uhf, sph, has_sp, ecp, so_ecp

 i = index(fchname, '.fch', back=.true.)
 if(i == 0) then
  write(6,'(/,A)') "ERROR in subroutine fch2qchem: '.fch' suffix not found in&
                  & file "//TRIM(fchname)
  stop
 end if
 proname = fchname(1:i-1)
 inpname = fchname(1:i-1)//'.in'

 uhf = .false.; has_sp = .false.; ecp = .false.; so_ecp = .false.
 call check_uhf_in_fch(fchname, uhf) ! determine whether UHF
 call read_fch(fchname, uhf)

 purecart = 1
 if(ANY(shell_type == 2)) purecart(4) = 2 ! 6D
 if(ANY(shell_type == 3)) purecart(3) = 2 ! 10F
 if(ANY(shell_type == 4)) purecart(2) = 2 ! 15G
 if(ANY(shell_type == 5)) purecart(1) = 2 ! 21H
 if(LenNCZ > 0) ecp = .true.

 ! check if any spherical functions
 if(ANY(shell_type<-1) .and. ANY(shell_type>1)) then
  write(6,'(A)') 'ERROR in subroutine fch2qchem: mixed spherical harmonic/&
                 &Cartesian functions detected.'
  write(6,'(A)') 'You probably used a basis set like 6-31G(d) in Gaussian. Its&
                & default setting is (6D,7F).'
  write(6,'(A)') "You need to add '5D 7F' or '6D 10F' keywords in Gaussian."
  stop
 else if(ANY(shell_type<-1)) then
  sph = .true.
 else
  sph = .false.
 end if

! Firstly, generate the input file (.in)
 open(newunit=fid,file=TRIM(inpname),status='replace')
 write(fid,'(A)') '$comment'
 write(fid,'(A)') ' file generated by fch2qchem utility of MOKIT'
 write(fid,'(A,/)') '$end'

 write(fid,'(A)') '$molecule'
 write(fid,'(I0,1X,I0)') charge, mult
 do i = 1, natom, 1
  write(fid,'(A2,1X,3(1X,F18.8))') elem(i), coor(:,i)
 end do ! for i
 deallocate(coor)
 write(fid,'(A,/)') '$end'

 write(fid,'(A)') '$rem'
 write(fid,'(A)') 'method hf'
 if(uhf) then
  write(fid,'(A)') 'unrestricted true'
 else ! RHF, ROHF
  if(mult /= 1) write(fid,'(A)') 'unrestricted false'
 end if
 if(ecp) write(fid,'(A)') 'ecp gen'
 write(fid,'(A)') 'basis gen'
 write(fid,'(A)') 'scf_guess read'
 write(fid,'(A)') 'scf_convergence 8'
 write(fid,'(A)') 'thresh 12'
 write(fid,'(A,1X,4I0)') 'purecart', (purecart(i),i=1,4)
 !write(fid,'(A)') 'symmetry off' ! warning: this is useless
 write(fid,'(A)') 'sym_ignore true'
 if(npair > 0) then
  write(fid,'(A)') 'correlation pp'
  write(fid,'(A,I0)') 'gvb_n_pairs ',npair
  write(fid,'(A)') 'gvb_restart true'
 end if
 write(fid,'(A)') 'gui = 2' ! generate fchk
 write(fid,'(A,/)') '$end'

 ! print basis sets into the .in file
 write(fid,'(A)') '$basis'
 write(fid,'(A,1X,A)') elem(1), '0'
 k = 0
 do i = 1, ncontr, 1
  m = shell2atom_map(i)
  if(m > 1) then
   if(shell2atom_map(i-1) == m-1) then
    write(fid,'(A4,/,A,1X,A)') '****', elem(m), '0'
   end if
  end if

  m = shell_type(i); n = prim_per_shell(i)
  if(m < -1) m = -m
  if(m == -1) then
   str2 = 'SP'
  else
   str2 = am_type(m)//' '
  end if
  write(fid,'(A2,1X,I2,3X,A)') str2, n, '1.00'

  has_sp = .false.
  if(allocated(contr_coeff_sp)) then
   if(ANY(contr_coeff_sp(k+1:k+n) > 1d-6)) has_sp = .true.
  end if

  if(has_sp) then
   do j = k+1, k+n, 1
    write(fid,'(3(2X,ES15.8))') prim_exp(j), contr_coeff(j), contr_coeff_sp(j)
   end do ! for j
  else ! no SP in this paragraph
   do j = k+1, k+n, 1
    write(fid,'(2(2X,ES15.8))') prim_exp(j), contr_coeff(j)
   end do ! for j
  end if

  k = k + n
 end do ! for i

 write(fid,'(A4,/,A)') '****','$end'
 deallocate(ielem, prim_per_shell, prim_exp, contr_coeff)
 if(allocated(contr_coeff_sp)) deallocate(contr_coeff_sp)
 deallocate(shell2atom_map)

 if(ecp) then
  write(fid,'(/,A)') '$ecp'

  do i = 1, natom, 1
   if(LPSkip(i) /= 0) then
    cycle
   else
    write(fid,'(A)') elem(i)//'     0'
    write(fid,'(A,2X,I2,2X,I3)') elem(i)//'-ECP', LMax(i), INT(RNFroz(i))
    str = am_type1(LMax(i))

    do j = 1, 10, 1
     n1 = KFirst(i,j); n2 = KLast(i,j)
     if(n1 == 0) exit
     if(j == 1) then
      write(fid,'(A)') str//' potential'
     else
      write(fid,'(A)') am_type1(j-2)//'-'//str//' potential'
     end if
     write(fid,'(I2)') n2-n1+1
     do n = n1, n2, 1
      write(fid,'(I0,2(3X,ES15.8))') NLP(n), ZLP(n), CLP(n)
     end do ! for n
    end do ! for j

    write(fid,'(A)') '****'
   end if
  end do ! for i

  write(fid,'(A)') '$end'
  deallocate(KFirst, KLast, Lmax, LPSkip, NLP, RNFroz, CLP, CLP2, ZLP)
 end if

 close(fid)
 deallocate(elem)

! Secondly, permute MO coefficients and generate the orbital file 53.0
 if(uhf) then ! UHF
  allocate(coeff(nbf,2*nif))
  coeff(:,1:nif) = alpha_coeff
  coeff(:,nif+1:2*nif) = beta_coeff
  deallocate(alpha_coeff, beta_coeff)
  nif1 = 2*nif
 else         ! R(O) HF
  allocate(coeff(nbf,nif))
  coeff(:,:) = alpha_coeff
  deallocate(alpha_coeff)
  nif1 = nif
 end if

 ! record the indices of d, f, g and h functions
 allocate(d_mark(ncontr), f_mark(ncontr), g_mark(ncontr), h_mark(ncontr))

 if(sph) then
  call read_mark_from_shltyp_sph(ncontr, shell_type, n5dmark, n7fmark, n9gmark, &
                                 n11hmark, d_mark, f_mark, g_mark, h_mark)
  ! adjust the order of 5d, 7f, etc. functions
  call fch2qchem_permute_sph(n5dmark, n7fmark, n9gmark, n11hmark, k, d_mark, &
                             f_mark, g_mark, h_mark, nbf, nif1, coeff)
 else
  call read_mark_from_shltyp_cart(ncontr, shell_type, n6dmark, n10fmark, n15gmark,&
                                  n21hmark, d_mark, f_mark, g_mark, h_mark)
  ! adjust the order of 6d, 10f, etc. functions
  call fch2qchem_permute_cart(n6dmark, n10fmark, n15gmark, n21hmark, k, d_mark,&
                              f_mark, g_mark, h_mark, nbf, nif1, coeff)
 end if

 deallocate(d_mark, f_mark, g_mark, h_mark, shell_type)
 allocate(alpha_coeff(nbf,nif))
 alpha_coeff = coeff(:,1:nif)
 if(uhf) then
  allocate(beta_coeff(nbf,nif))
  beta_coeff = coeff(:,nif+1:2*nif)
 end if
 deallocate(coeff)

 call create_dir(proname)
 !open(newunit=fid,file='53.0',form='binary')
 open(newunit=fid,file=TRIM(proname)//'/53.0',access='stream')

 write(unit=fid) alpha_coeff
 if(uhf) then
  write(unit=fid) beta_coeff
 else
  write(unit=fid) alpha_coeff
 end if

 write(unit=fid) eigen_e_a
 if(uhf) then
  write(unit=fid) eigen_e_b
 else
  write(unit=fid) eigen_e_a
 end if

 deallocate(alpha_coeff, eigen_e_a)
 close(fid)
 if(npair > 0) call copy_bin_file(TRIM(proname)//'/53.0', TRIM(proname)//&
                                  '/169.0', .false.)

 ! move the newly created directory into $QCSCRATCH/
 dirname = ' '
 call getenv('QCSCRATCH', dirname)

 if(LEN_TRIM(dirname) == 0) then
  write(6,'(/,A)') '$QCSCRATCH not found. '//TRIM(proname)//' put in the curren&
                   &t directory.'
  write(6,'(A)') 'You need to put the directory into $QCSCRATCH/ before running&
                 & qchem.'
 else
  call remove_dir(TRIM(dirname)//'/'//TRIM(proname))
  i = SYSTEM('mv '//TRIM(proname)//' '//TRIM(dirname)//'/')
  if(i == 0) then
   write(6,'(/,A)') '$QCSCRATCH found. Directory '//TRIM(proname)//' moved into &
                    &$QCSCRATCH/'
   write(6,'(A)') 'You can run:'
   write(6,'(A)') 'qchem '//TRIM(inpname)//' '//TRIM(proname)//'.out '//&
                   TRIM(proname)
  else
   write(6,'(/,A)') 'Warning in subroutine fch2qchem: failed to move directory&
                    & into '//TRIM(dirname)//'/'
  end if
 end if
end subroutine fch2qchem

subroutine fch2qchem_permute_sph(n5dmark, n7fmark, n9gmark, n11hmark, k, d_mark, &
                              f_mark, g_mark, h_mark, nbf, nif, coeff2)
 implicit none
 integer :: i
 integer, intent(in) :: n5dmark, n7fmark, n9gmark, n11hmark, k, nbf, nif
 integer, intent(in) :: d_mark(k), f_mark(k), g_mark(k), h_mark(k)
 real(kind=8), intent(inout) :: coeff2(nbf,nif)

 if(n5dmark==0 .and. n7fmark==0 .and. n9gmark==0 .and. n11hmark==0) return

 do i = 1, n5dmark, 1
  call fch2qchem_permute_5d(nif, coeff2(d_mark(i):d_mark(i)+4,:))
 end do
 do i = 1, n7fmark, 1
  call fch2qchem_permute_7f(nif, coeff2(f_mark(i):f_mark(i)+6,:))
 end do
 do i = 1, n9gmark, 1
  call fch2qchem_permute_9g(nif, coeff2(g_mark(i):g_mark(i)+8,:))
 end do
 do i = 1, n11hmark, 1
  call fch2qchem_permute_11h(nif, coeff2(h_mark(i):h_mark(i)+10,:))
 end do

end subroutine fch2qchem_permute_sph

subroutine fch2qchem_permute_cart(n6dmark, n10fmark, n15gmark, n21hmark, k, d_mark, &
                              f_mark, g_mark, h_mark, nbf, nif, coeff2)
 implicit none
 integer :: i
 integer, intent(in) :: n6dmark, n10fmark, n15gmark, n21hmark, k, nbf, nif
 integer, intent(in) :: d_mark(k), f_mark(k), g_mark(k), h_mark(k)
 real(kind=8), intent(inout) :: coeff2(nbf,nif)

 if(n6dmark==0 .and. n10fmark==0 .and. n15gmark==0 .and. n21hmark==0) return

 do i = 1, n6dmark, 1
  call fch2qchem_permute_6d(nif, coeff2(d_mark(i):d_mark(i)+5,:))
 end do
 do i = 1, n10fmark, 1
  call fch2qchem_permute_10f(nif, coeff2(f_mark(i):f_mark(i)+9,:))
 end do
 do i = 1, n15gmark, 1
  call fch2qchem_permute_15g(nif, coeff2(g_mark(i):g_mark(i)+14,:))
 end do
 do i = 1, n21hmark, 1
  call fch2qchem_permute_21h(nif, coeff2(h_mark(i):h_mark(i)+20,:))
 end do

end subroutine fch2qchem_permute_cart

subroutine fch2qchem_permute_5d(nif,coeff)
 implicit none
 integer :: i
 integer, parameter :: order(5) = [5, 3, 1, 2, 4]
 integer, intent(in) :: nif
 real(kind=8), intent(inout) :: coeff(5,nif)
 real(kind=8), allocatable :: coeff2(:,:)
! From: the order of spherical d functions in Gaussian
! To: the order of spherical d functions in PySCF
! 1    2    3    4    5
! d0 , d+1, d-1, d+2, d-2
! d-2, d-1, d0 , d+1, d+2

 allocate(coeff2(5,nif), source=0d0)
 forall(i = 1:5) coeff2(i,:) = coeff(order(i),:)
 coeff = coeff2
 deallocate(coeff2)
end subroutine fch2qchem_permute_5d

subroutine fch2qchem_permute_6d(nif,coeff)
 implicit none
 integer :: i
 integer, parameter :: order(6) = [1, 4, 5, 2, 6, 3]
 integer, intent(in) :: nif
 real(kind=8), intent(inout) :: coeff(6,nif)
 real(kind=8), allocatable :: coeff2(:,:)
! From: the order of Cartesian d functions in Gaussian
! To: the order of Cartesian d functions in PySCF
! 1  2  3  4  5  6
! XX,YY,ZZ,XY,XZ,YZ
! XX,XY,XZ,YY,YZ,ZZ

 allocate(coeff2(6,nif), source=coeff)
 forall(i = 1:6) coeff(i,:) = coeff2(order(i),:)
 deallocate(coeff2)
end subroutine fch2qchem_permute_6d

subroutine fch2qchem_permute_7f(nif,coeff)
 implicit none
 integer :: i
 integer, parameter :: order(7) = [7, 5, 3, 1, 2, 4, 6]
 integer, intent(in) :: nif
 real(kind=8), intent(inout) :: coeff(7,nif)
 real(kind=8), allocatable :: coeff2(:,:)
! From: the order of spherical f functions in Gaussian
! To: the order of spherical f functions in PySCF
! 1    2    3    4    5    6    7
! f0 , f+1, f-1, f+2, f-2, f+3, f-3
! f-3, f-2, f-1, f0 , f+1, f+2, f+3

 allocate(coeff2(7,nif), source=0d0)
 forall(i = 1:7) coeff2(i,:) = coeff(order(i),:)
 coeff = coeff2
 deallocate(coeff2)
end subroutine fch2qchem_permute_7f

subroutine fch2qchem_permute_10f(nif,coeff)
 implicit none
 integer :: i
 integer, parameter :: order(10) = [1, 5, 6, 4, 10, 7, 2, 9, 8, 3]
 integer, intent(in) :: nif
 real(kind=8), intent(inout) :: coeff(10,nif)
 real(kind=8), allocatable :: coeff2(:,:)
! From: the order of Cartesian f functions in Gaussian
! To: the order of Cartesian f functions in PySCF
! 1   2   3   4   5   6   7   8   9   10
! XXX,YYY,ZZZ,XYY,XXY,XXZ,XZZ,YZZ,YYZ,XYZ
! XXX,XXY,XXZ,XYY,XYZ,XZZ,YYY,YYZ,YZZ,ZZZ

 allocate(coeff2(10,nif), source=coeff)
 forall(i = 1:10) coeff(i,:) = coeff2(order(i),:)
 deallocate(coeff2)
end subroutine fch2qchem_permute_10f

subroutine fch2qchem_permute_9g(nif,coeff)
 implicit none
 integer :: i
 integer, parameter :: order(9) = [9, 7, 5, 3, 1, 2, 4, 6, 8]
 integer, intent(in) :: nif
 real(kind=8), intent(inout) :: coeff(9,nif)
 real(kind=8), allocatable :: coeff2(:,:)
! From: the order of spherical g functions in Gaussian
! To: the order of spherical g functions in PySCF
! 1    2    3    4    5    6    7    8    9
! g0 , g+1, g-1, g+2, g-2, g+3, g-3, g+4, g-4
! g-4, g-3, g-2, g-1, g0 , g+1, g+2, g+3, g+4

 allocate(coeff2(9,nif), source=0d0)
 forall(i = 1:9) coeff2(i,:) = coeff(order(i),:)
 coeff = coeff2
 deallocate(coeff2)
end subroutine fch2qchem_permute_9g

subroutine fch2qchem_permute_15g(nif,coeff)
 implicit none
 integer :: i
 integer, intent(in) :: nif
 real(kind=8), intent(inout) :: coeff(15,nif)
 real(kind=8), allocatable :: coeff2(:,:)
! From: the order of Cartesian g functions in Gaussian
! To: the order of Cartesian g functions in PySCF
! 1    2    3    4    5    6    7    8    9    10   11   12   13   14   15
! ZZZZ,YZZZ,YYZZ,YYYZ,YYYY,XZZZ,XYZZ,XYYZ,XYYY,XXZZ,XXYZ,XXYY,XXXZ,XXXY,XXXX
! xxxx,xxxy,xxxz,xxyy,xxyz,xxzz,xyyy,xyyz,xyzz,xzzz,yyyy,yyyz,yyzz,yzzz,zzzz

 allocate(coeff2(15,nif), source=coeff)
 forall(i = 1:15) coeff(i,:) = coeff2(16-i,:)
 deallocate(coeff2)
end subroutine fch2qchem_permute_15g

subroutine fch2qchem_permute_11h(nif,coeff)
 implicit none
 integer :: i
 integer, parameter :: order(11) = [11, 9, 7, 5, 3, 1, 2, 4, 6, 8, 10]
 integer, intent(in) :: nif
 real(kind=8), intent(inout) :: coeff(11,nif)
 real(kind=8), allocatable :: coeff2(:,:)
! From: the order of spherical h functions in Gaussian
! To: the order of spherical h functions in PySCF
! 1    2    3    4    5    6    7    8    9    10   11
! h0 , h+1, h-1, h+2, h-2, h+3, h-3, h+4, h-4, h+5, h-5
! h-5, h-4, h-3, h-2, h-1, h0 , h+1, h+2, h+3, h+4, h+5

 allocate(coeff2(11,nif), source=0d0)
 forall(i = 1:11) coeff2(i,:) = coeff(order(i),:)
 coeff = coeff2
 deallocate(coeff2)
end subroutine fch2qchem_permute_11h

subroutine fch2qchem_permute_21h(nif,coeff)
 implicit none
 integer :: i
 integer, intent(in) :: nif
 real(kind=8), intent(inout) :: coeff(21,nif)
 real(kind=8), allocatable :: coeff2(:,:)
! From: the order of Cartesian h functions in Gaussian
! To: the order of Cartesian h functions in PySCF
! 1     2     3     4     5     6     7     8     9     10    11    12    13    14    15    16    17    18    19    20    21
! ZZZZZ,YZZZZ,YYZZZ,YYYZZ,YYYYZ,YYYYY,XZZZZ,XYZZZ,XYYZZ,XYYYZ,XYYYY,XXZZZ,XXYZZ,XXYYZ,XXYYY,XXXZZ,XXXYZ,XXXYY,XXXXZ,XXXXY,XXXXX
! xxxxx,xxxxy,xxxxz,xxxyy,xxxyz,xxxzz,xxyyy,xxyyz,xxyzz,xxzzz,xyyyy,xyyyz,xyyzz,xyzzz,xzzzz,yyyyy,yyyyz,yyyzz,yyzzz,yzzzz,zzzzz

 allocate(coeff2(21,nif), source=coeff)
 forall(i = 1:21) coeff(i,:) = coeff2(22-i,:)
 deallocate(coeff2)
end subroutine fch2qchem_permute_21h
