! written by jxzou at 20200623

module periodic_table
 use fch_content, only: elem2nuc, nuc2elem
 implicit none
 integer, parameter :: period_nelem = 118 ! 118 elements, H-Og
 ! If the period_nelem is imported from module fch_content, the f2py compiler
 ! cannot recognize it correctly, so here it is defined again.

 ! the radii below are read from Gaussian output file
 real(kind=8), parameter :: vdw_radii(period_nelem) = &
 (/1.4430d0, 1.1810d0, 1.2255d0, 1.3725d0, 2.0415d0, &
   1.9255d0, 1.8300d0, 1.7500d0, 1.6820d0, 1.6215d0, &
   1.4915d0, 1.5105d0, 2.2495d0, 2.1475d0, 2.0735d0, &
   2.0175d0, 1.9735d0, 1.9340d0, 1.9060d0, 1.6995d0, &
   1.6475d0, 1.5875d0, 1.5720d0, 1.5115d0, 1.4805d0, &
   1.4560d0, 1.4360d0, 1.4170d0, 1.7475d0, 1.3815d0, &
   2.1915d0, 2.1400d0, 2.1150d0, 2.1025d0, 2.0945d0, &
   2.0705d0, 2.0570d0, 1.8205d0, 1.6725d0, 1.5620d0, &
   1.5825d0, 1.5260d0, 1.4990d0, 1.4815d0, 1.4645d0, &
   1.4495d0, 1.5740d0, 1.4240d0, 2.2315d0, 2.1960d0, &
   2.2100d0, 2.2350d0, 2.2500d0, 2.2020d0, 2.2585d0, &
   1.8515d0, 1.7610d0, 1.7780d0, 1.8030d0, 1.7875d0, &
   1.7735d0, 1.7600d0, 1.7465d0, 1.6840d0, 1.7255d0, &
   1.7140d0, 1.7045d0, 1.6955d0, 1.6870d0, 1.6775d0, &
   1.8200d0, 1.5705d0, 1.5850d0, 1.5345d0, 1.4770d0, &
   1.5600d0, 1.4200d0, 1.3770d0, 1.6465d0, 1.3525d0, &
   2.1735d0, 2.1485d0, 2.1850d0, 2.3545d0, 2.3750d0, &
   2.3825d0, 2.4500d0, 1.8385d0, 1.7390d0, 1.6980d0, &
   1.7120d0, 1.6975d0, 1.7120d0, 1.7120d0, 1.6905d0, &
   1.6630d0, 1.6695d0, 1.6565d0, 1.6495d0, 1.6430d0, &
   1.6370d0, 1.6240d0, 1.6180d0, 1.7500d0, 1.7500d0, &
   1.7500d0, 1.7500d0, 1.7500d0, 1.7500d0, 1.7500d0, &
   1.7500d0, 1.7500d0, 1.7500d0, 1.7500d0, 1.7500d0, &
   1.7500d0, 1.7500d0, 1.7500d0/)

 ! Pyykko's covalent radii, see DOI: 10.1002/chem.200800987
 real(kind=8), parameter :: cov_rad(period_nelem) = &
 (/0.32d0,0.46d0,1.33d0,1.02d0,0.85d0, 0.75d0,0.71d0,0.63d0,0.64d0,0.67d0, &
   1.55d0,1.39d0,1.26d0,1.16d0,1.11d0, 1.03d0,0.99d0,0.96d0,1.96d0,1.71d0, &
   1.48d0,1.36d0,1.34d0,1.22d0,1.19d0, 1.16d0,1.11d0,1.10d0,1.12d0,1.18d0, &
   1.24d0,1.21d0,1.21d0,1.16d0,1.14d0, 1.17d0,2.10d0,1.85d0,1.63d0,1.54d0, &
   1.47d0,1.38d0,1.28d0,1.25d0,1.25d0, 1.20d0,1.28d0,1.36d0,1.42d0,1.40d0, &
   1.40d0,1.36d0,1.33d0,1.31d0,2.32d0, 1.96d0,1.80d0,1.63d0,1.76d0,1.74d0, &
   1.73d0,1.72d0,1.68d0,1.69d0,1.68d0, 1.67d0,1.66d0,1.65d0,1.64d0,1.70d0, &
   1.62d0,1.52d0,1.46d0,1.37d0,1.31d0, 1.29d0,1.22d0,1.23d0,1.24d0,1.33d0, &
   1.44d0,1.44d0,1.51d0,1.45d0,1.47d0, 1.42d0,2.23d0,2.01d0,1.86d0,1.75d0, &
   1.69d0,1.70d0,1.71d0,1.72d0,1.66d0, 1.66d0,1.68d0,1.68d0,1.65d0,1.67d0, &
   1.73d0,1.76d0,1.61d0,1.57d0,1.49d0, 1.43d0,1.41d0,1.34d0,1.29d0,1.28d0, &
   1.21d0,1.22d0,1.36d0,1.43d0,1.62d0, 1.75d0,1.65d0,1.57d0/)

 ! reduce distance thresholds for a single, double and triple bond
 real(kind=8), parameter :: rfac1 = 1.25d0
 real(kind=8), parameter :: rfac2 = 0.93d0
 real(kind=8), parameter :: rfac3 = 0.81d0

contains

pure function elem2vdw_radii(elem) result(radii)
 implicit none
 real(kind=8) :: radii
 character(len=2), intent(in) :: elem

 radii = vdw_radii(elem2nuc(elem))
end function elem2vdw_radii

! read elements array from a given .gjf array
subroutine read_elem_from_gjf(gjfname, natom, elem, ghost)
 implicit none
 integer :: i, j, k, nblank, fid
 integer, intent(in) :: natom
 character(len=6) :: str
 character(len=240) :: buf
 character(len=240), intent(in) :: gjfname
 character(len=2), intent(out) :: elem(natom)
 logical, intent(out) :: ghost(natom)

 forall(i = 1:natom) elem(i) = '  '
 ghost = .false.
 open(newunit=fid,file=TRIM(gjfname),status='old',position='rewind')
 nblank = 0

 do while(.true.)
  read(fid,'(A)') buf
  if(LEN_TRIM(buf) == 0) nblank = nblank + 1
  if(nblank == 2) exit
 end do ! for while

 read(fid,'(A)') buf ! skip charge and mult

 do i = 1, natom, 1
  read(fid,*) str
  str = ADJUSTL(str)
  k = LEN_TRIM(str)
  if(str(k-2:k) == '-Bq') then
   elem(i) = str(1:k-3)
   ghost(i) = .true.
  else if(str(2:3)=='(f' .or. str(2:3)=='(F') then
   call upper(str(1:1))
   elem(i) = str(1:1)//' '
  else if(str(3:4)=='(f' .or. str(3:4)=='(F') then
   call upper(str(1:1))
   call lower(str(2:2))
   elem(i) = str(1:2)
  else
   k = IACHAR(str(1:1))
   if((k>64 .and. k<91) .or. (k>96 .and. k<123)) then ! A-Z, a-z
    if(k>96 .and. k<123) str(1:1) = ACHAR(k-32)
    j = IACHAR(str(2:2))
    if(j>64 .and. j<91) str(2:2) = ACHAR(j+32)
    elem(i) = TRIM(str)
   else
    read(str,*) j
    if(j > period_nelem) then
     write(6,'(/,A)') 'ERROR in subroutine read_elem_from_gjf: j too large.'
     write(6,'(A,I0)') 'j=', j
     stop
    end if
    elem(i) = nuc2elem(j)
   end if
  end if
 end do ! for natom

 close(fid)
end subroutine read_elem_from_gjf

end module periodic_table

subroutine read_elem_and_coor_from_file(fname, natom, elem, coor)
 implicit none
 integer :: i, charge, mult
 integer, intent(in) :: natom
 integer, allocatable :: nuc(:)
 real(kind=8), intent(out) :: coor(3,natom)
 character(len=2), intent(out) :: elem(natom)
 character(len=240), intent(in) :: fname

 i = LEN_TRIM(fname)
 select case(fname(i-3:i))
 case('.xyz')
  call read_elem_and_coor_from_xyz(fname, natom, elem, coor)
 case('.gjf')
  allocate(nuc(natom))
  call read_elem_and_coor_from_gjf(fname, natom, elem, nuc, coor, charge, mult)
 case('.fch')
  allocate(nuc(natom))
  call read_elem_and_coor_from_fch(fname, natom, elem, nuc, coor, charge, mult)
 case default
  write(6,'(/,A)') 'ERROR in subroutine read_elem_and_coor_from_file: invalid f&
                   &ormat.'
  write(6,'(A)') 'Currently only .xyz/.gjf/.fch are supported.'
  stop
 end select

 if(allocated(nuc)) deallocate(nuc)
end subroutine read_elem_and_coor_from_file

subroutine read_elem_and_coor_from_gjf_pbc(gjfname, natom, elem, nuc, coor, &
                                           lat_vec, charge, mult)
 implicit none
 integer :: n
 integer, intent(in) :: natom
 integer, intent(out) :: charge, mult, nuc(natom)
 integer, allocatable :: nuc1(:)
 real(kind=8), intent(out) :: coor(3,natom), lat_vec(3,3)
 real(kind=8), allocatable :: coor1(:,:)
 character(len=2), intent(out) :: elem(natom)
 character(len=2), allocatable :: elem1(:)
 character(len=240), intent(in) :: gjfname

 n = natom + 3
 allocate(elem1(n), nuc1(n), coor1(3,n))
 call read_elem_and_coor_from_gjf(gjfname, n, elem1, nuc1, coor1, charge, mult)
 elem = elem1(1:n-3)
 nuc = nuc1(1:n-3)
 coor = coor1(:,1:n-3)
 lat_vec = coor1(:,n-2:n)
 deallocate(elem1, nuc1, coor1)
end subroutine read_elem_and_coor_from_gjf_pbc

! read atomic nuclear number and Cartesian coordinates from a file
subroutine read_nuc_and_coor_from_file(fname, natom, nuc, coor)
 use fch_content, only: elem2nuc
 implicit none
 integer :: i, charge, mult
 integer, intent(in) :: natom
 integer, intent(out) :: nuc(natom)
 real(kind=8), intent(out) :: coor(3,natom)
 character(len=2), allocatable :: elem(:)
 character(len=240), intent(in) :: fname

 allocate(elem(natom))
 i = LEN_TRIM(fname)

 select case(fname(i-3:i))
 case('.fch')
  call read_elem_and_coor_from_fch(fname, natom, elem, nuc, coor, charge, mult)
 case('.gjf')
  call read_elem_and_coor_from_gjf(fname, natom, elem, nuc, coor, charge, mult)
 case('.xyz')
  call read_elem_and_coor_from_xyz(fname, natom, elem, coor)
  forall(i = 1:natom) nuc(i) = elem2nuc(elem(i))
 case default
  write(6,'(/,A)') 'ERROR in subroutine read_elem_and_coor_from_file:'
  stop
 end select

 deallocate(elem)
end subroutine read_nuc_and_coor_from_file

! read 3 arrays elem, nuc, coor, and the total charge as well as multiplicity
! from a given .gjf file
subroutine read_elem_and_coor_from_gjf(gjfname, natom, elem, nuc, coor, charge, mult)
 use phys_cons, only: Bohr_const
 use fch_content, only: elem2nuc, possible_nuc2elem
 implicit none
 integer :: i, j, k, fid, nblank, ne
 integer, intent(in) :: natom
 integer, intent(out) :: nuc(natom), charge, mult
 real(kind=8), intent(out) :: coor(3,natom)
 character(len=2), intent(out) :: elem(natom)
 character(len=240) :: buf
 character(len=240), intent(in) :: gjfname
 logical :: bohr

 charge = 0; mult = 1; nuc = 0; coor = 0d0; bohr = .false.; nblank = 0

 open(newunit=fid,file=TRIM(gjfname),status='old',position='rewind')
 do while(.true.)
  read(fid,'(A)',iostat=i) buf
  if(i /= 0) exit
  if(LEN_TRIM(buf) == 0) nblank = nblank + 1
  if(nblank == 2) exit

  if(buf(1:1) =='#') then
   if(INDEX(buf,'units=au') /= 0) bohr = .true.
  end if
 end do ! for while

 if(i /= 0) then
  write(6,'(/,A)') 'ERROR in subroutine read_elem_and_coor_from_gjf: incomplete&
                   & file '//TRIM(gjfname)
  stop
 end if

 read(fid,*,iostat=k) charge, mult
 if(k /= 0) then
  write(6,'(/,A)') 'ERROR in subroutine read_elem_and_coor_from_gjf: failed to &
                   &read charge and mult.'
  write(6,'(A)') 'There exists syntax error in file '//TRIM(gjfname)
  stop
 end if

 do i = 1, natom, 1
  read(fid,'(A)') buf
  j = INDEX(buf,'('); k = INDEX(buf,')') ! in case for the fragment guess wfn
  if(j*k /= 0) buf(j:k) = ' '

  read(buf,*,iostat=k) elem(i), coor(1:3,i)
  if(k /= 0) then
   write(6,'(/,A)') 'ERROR in subroutine read_elem_and_coor_from_gjf: only 4-co&
                    &lumn format is supported.'
   close(fid)
   stop
  end if
 end do ! for i

 close(fid)
 if(bohr) coor = coor*Bohr_const ! convert Bohr to Angstrom

 ! standardize a set of elements, e.g. he -> He
 call standardize_elem(natom, elem)

 ! convert atomic numbers to atomic symbols if the user uses atomic numbers
 call possible_nuc2elem(natom, elem)

 ! convert element symbols to atomic order
 forall(i = 1:natom) nuc(i) = elem2nuc(elem(i))

 ne = SUM(nuc) - charge
 if(MOD(ne,2) /= MOD(mult-1,2)) then
  write(6,'(/,A)') REPEAT('-',79)
  write(6,'(A)') 'Warning from subroutine read_elem_and_coor_from_gjf:'
  write(6,'(2(A,I0),A)') 'The combination of multiplicity ', mult, ' and ', ne,&
                         &' electrons is impossible.'
  write(6,'(A)') 'Filename = '//TRIM(gjfname)
  write(6,'(A)') REPEAT('-',79)
 end if
end subroutine read_elem_and_coor_from_gjf

! read charge, spin multiplicities and atom2frag from a given .gjf file
subroutine read_frag_guess_from_gjf(gjfname, natom, atom2frag, nfrag, frag_char_mult)
 implicit none
 integer :: i, j, k, nblank, charge, mult, fid
 integer, intent(in) :: natom, nfrag
 integer, intent(out) :: atom2frag(natom), frag_char_mult(2,nfrag)
 character(len=240) :: buf
 character(len=240), intent(in) :: gjfname

 atom2frag = 0; frag_char_mult = 0
 open(newunit=fid,file=TRIM(gjfname),status='old',position='rewind')

 nblank = 0
 do while(.true.)
  read(fid,'(A)') buf
  if(LEN_TRIM(buf) == 0) nblank = nblank + 1
  if(nblank == 2) exit
 end do ! for while

 read(fid,*,iostat=k) charge, mult, ((frag_char_mult(j,i),j=1,2),i=1,nfrag)
 if(k /= 0) then
  write(6,'(A)') 'ERROR in subroutine read_frag_guess_from_gjf: failed to read&
                & charges and spin'
  write(6,'(A)') 'multiplicities of fragments. Please check syntax in file '//&
                 TRIM(gjfname)
  close(fid)
  stop
 end if

 do i = 1, natom, 1
  read(fid,'(A)') buf
  j = INDEX(buf,'='); k = INDEX(buf,')')

  if(j*k == 0) then
   write(6,'(A)') 'ERROR in subroutine read_frag_guess_from_gjf: failed to read&
                  & atom2frag.'
   write(6,'(A)') 'Problematic line: '//TRIM(buf)
   write(6,'(A)') 'Please check syntax in file '//TRIM(gjfname)
   close(fid)
   stop
  end if

  read(buf(j+1:k-1),*) atom2frag(i)
 end do ! for i

 close(fid)
end subroutine read_frag_guess_from_gjf

! read nuclear charge number from a given .fch file
subroutine read_nuc_from_fch(fchname, natom, nuc)
 implicit none
 integer :: i, fid
 integer, intent(in) :: natom
 integer, intent(out) :: nuc(natom)
 character(len=240) :: buf
 character(len=240), intent(in) :: fchname

 nuc = 0
 open(newunit=fid,file=TRIM(fchname),status='old',position='rewind')

 do while(.true.)
  read(fid,'(A)') buf
  if(buf(1:14) == 'Atomic numbers') exit
 end do ! for while

 read(fid,'(6(1X,I11))') (nuc(i),i=1,natom)
 close(fid)
end subroutine read_nuc_from_fch

! read the Cartesian coordinates from a given .fch file
subroutine read_coor_from_fch(fchname, natom, coor)
 use phys_cons, only: Bohr_const
 implicit none
 integer :: i, fid
 integer, intent(in) :: natom
 real(kind=8), intent(out) :: coor(3,natom)
 real(kind=8), allocatable :: coor0(:)
 character(len=240) :: buf
 character(len=240), intent(in) :: fchname

 open(newunit=fid,file=TRIM(fchname),status='old',position='rewind')

 ! find and read coordinates
 do while(.true.)
  read(fid,'(A)',iostat=i) buf
  if(i /= 0) exit
  if(buf(1:12) == 'Current cart') exit
 end do

 if(i /= 0) then
  write(6,'(A)') "ERROR in subroutine read_coor_from_fch: no 'Current &
                   & cart' found in file "//TRIM(fchname)
  close(fid)
  stop
 end if

 allocate(coor0(3*natom), source=0d0)
 read(fid,'(5(1X,ES15.8))') (coor0(i),i=1,3*natom)
 close(fid)

 coor0 = coor0*Bohr_const ! convert Bohr to Angstrom
 coor = RESHAPE(coor0,(/3,natom/))
 deallocate(coor0)
end subroutine read_coor_from_fch

! read 3 arrays elem, nuc, coor, and the total charge as well as multiplicity
! from a given .fch file
subroutine read_elem_and_coor_from_fch(fchname, natom, elem, nuc, coor, charge, mult)
 use phys_cons, only: Bohr_const
 use fch_content, only: nuc2elem
 implicit none
 integer :: i, fid
 integer, intent(in) :: natom
!f2py intent(in) :: natom
 integer, intent(out) :: charge, mult, nuc(natom)
 real(kind=8), intent(out) :: coor(3,natom)
 real(kind=8), allocatable :: coor0(:)
 character(len=2), intent(out) :: elem(natom)
!f2py intent(out) :: elem, nuc, coor, charge, mult
!f2py depend(natom) :: elem, nuc, coor
 character(len=240) :: buf
 character(len=240), intent(in) :: fchname
!f2py intent(in) :: fchname

 open(newunit=fid,file=TRIM(fchname),status='old',position='rewind')

 ! find charge and mult
 do while(.true.)
  read(fid,'(A)') buf
  if(buf(1:6) == 'Charge') exit
 end do
 BACKSPACE(fid)
 read(fid,'(A49,2X,I10)') buf, charge
 read(fid,'(A49,2X,I10)') buf, mult

 ! find atomic numbers/nuclear charges
 do while(.true.)
  read(fid,'(A)') buf
  if(buf(1:14) == 'Atomic numbers') exit
 end do ! for i
 read(fid,'(6(1X,I11))') (nuc(i),i=1,natom)

 ! find and read coordinates
 do while(.true.)
  read(fid,'(A)') buf
  if(buf(1:12) == 'Current cart') exit
 end do
 allocate(coor0(3*natom), source=0d0)
 read(fid,'(5(1X,ES15.8))') (coor0(i),i=1,3*natom)
 coor = RESHAPE(coor0,[3,natom])

 deallocate(coor0)
 close(fid)

 coor = coor*Bohr_const ! convert Bohr to Angstrom
 forall(i=1:natom) elem(i) = nuc2elem(nuc(i))
end subroutine read_elem_and_coor_from_fch

! calculate the nuclear dipole moment from
subroutine get_nuc_dipole(natom, nuc, coor, n_dipole)
 use phys_cons, only: Bohr_const
 implicit none
 integer :: i
 integer, intent(in) :: natom
!f2py intent(in) :: natom
 integer, intent(in) :: nuc(natom)
 real(kind=8), allocatable :: rnuc(:)
 real(kind=8), intent(in) :: coor(3,natom)
!f2py intent(in) :: nuc, coor
!f2py depend(natom) :: nuc, coor
 real(kind=8), intent(out) :: n_dipole(3) ! x,y,z 3-components
!f2py intent(out) :: n_dipole

 allocate(rnuc(natom))
 forall(i = 1:natom) rnuc(i) = DBLE(nuc(i))

 do i = 1, 3
  n_dipole(i) = DOT_PRODUCT(rnuc, coor(i,:))
 end do ! for i
 deallocate(rnuc)

 ! input coor are in Angstrom, convert n_dipole into a.u.
 n_dipole = n_dipole/Bohr_const
end subroutine get_nuc_dipole

! read Cartesian xyz coordinates from a .xyz file
! Note: 1) return array coor(3,natom) are in unit Angstrom
!       2) if 'bohr' key is found in the 2nd line of the xyz file,
!          coor will be multiplied by Bohr_const
subroutine read_elem_and_coor_from_xyz(xyzname, natom, elem, coor)
 use phys_cons, only: Bohr_const
 implicit none
 integer :: i, k, fid
 integer, intent(in) :: natom
 real(kind=8), intent(out) :: coor(3,natom)
 character(len=2), intent(out) :: elem(natom)
 character(len=240) :: buf
 character(len=240), intent(in) :: xyzname
 logical :: bohr

 elem = '  '; coor = 0d0

 open(newunit=fid,file=TRIM(xyzname),status='old',position='rewind')
 read(fid,'(A)') buf
 read(fid,'(A)') buf

 bohr = .false.
 call lower(buf)
 if(INDEX(buf,'bohr') > 0) then
  if(INDEX(buf,'angstrom') > 0) then
   write(6,'(/,A)') "ERROR in subroutine read_elem_and_coor_from_xyz: it's conf&
                    &using because both"
   write(6,'(A)') "'bohr' and 'angstrom' are detected in the 2nd line of file "&
                  //TRIM(xyzname)
   close(fid)
   stop
  else
   bohr = .true.
  end if
 end if

 do i = 1, natom, 1
  read(fid,*,iostat=k) elem(i), coor(1:3,i)
  if(k /= 0) then
   write(6,'(/,A)') 'ERROR in subroutine read_elem_and_coor_from_xyz: insuffici&
                    &ent number of atoms'
   write(6,'(A)') 'in file '//TRIM(xyzname)
   close(fid)
   stop
  end if
 end do ! for i

 close(fid)
 if(bohr) coor = coor*Bohr_const ! convert Bohr to Angstrom

 ! Some non-standard xyz files may include elements like 'C02', 'H06' or 'Hw'.
 ! Make the 2nd character as ' ' in such cases.
 do i = 1, natom, 1
  k = IACHAR(elem(i)(2:2))
  if((k>47 .and. k<58) .or. k==119) elem(i)(2:2) = ' '
 end do ! for i
end subroutine read_elem_and_coor_from_xyz

! read the number of frames from xyz file
subroutine read_nframe_from_xyz(xyzname, nframe)
 implicit none
 integer :: i, fid, natom
 integer, intent(out) :: nframe
 character(len=240) :: buf
 character*240, intent(in) :: xyzname

 nframe = 0
 open(newunit=fid,file=TRIM(xyzname),status='old',position='rewind')

 do while(.true.)
  read(fid,*,iostat=i) natom
  if(i /= 0) exit
  do i = 1, natom+1, 1
   read(fid,'(A)') buf
  end do ! for i
  nframe = nframe + 1
 end do ! for while

 close(fid)
end subroutine read_nframe_from_xyz

! read the i-th frame from a given .xyz file
subroutine read_iframe_from_xyz(xyzname, ith, natom, elem, coor)
 implicit none
 integer :: i, k, fid, nframe
 integer, intent(in) :: ith, natom
 real(kind=8), dimension(3,natom), intent(out) :: coor
 character(len=240) :: buf
 character*2, dimension(natom), intent(out) :: elem
 character*240, intent(in) :: xyzname

 nframe = 0; coor = 0d0; elem = ' '
 open(newunit=fid,file=TRIM(xyzname),status='old',position='rewind')

 if(ith > 1) then
  do while(.true.)
   read(fid,*,iostat=i) k
   if(i /= 0) exit
   do i = 1, k+1, 1
    read(fid,'(A)') buf
   end do ! for i
   nframe = nframe + 1
   if(nframe == ith-1) exit
  end do ! for while
 end if

 read(fid,'(A)') buf
 read(fid,'(A)') buf
 do i = 1, natom, 1
  read(fid,*) elem(i), coor(1:3,i)
 end do ! for i
 close(fid)
end subroutine read_iframe_from_xyz

! read all frames from a given .xyz file
subroutine read_all_frames_from_xyz(xyzname, nframe, natom, elem, coor)
 implicit none
 integer :: i, j, fid
 integer, intent(in) :: nframe, natom
 real(kind=8), dimension(3,natom,nframe), intent(out) :: coor
 character(len=240) :: buf
 character*2, dimension(natom,nframe), intent(out) :: elem
 character*240, intent(in) :: xyzname

 coor = 0d0; elem = ' '
 open(newunit=fid,file=TRIM(xyzname),status='old',position='rewind')

 do i = 1, nframe, 1
  read(fid,'(A)') buf
  read(fid,'(A)') buf
  do j = 1, natom, 1
   read(fid,*) elem(j,i), coor(1:3,j,i)
  end do ! for j
 end do ! for i
 close(fid)
end subroutine read_all_frames_from_xyz

! read the number of frames from pdb file
subroutine read_nframe_from_pdb(pdbname, nframe)
 implicit none
 integer :: i, fid
 integer, intent(out) :: nframe
 character(len=240) :: buf
 character*240, intent(in) :: pdbname

 nframe = 1 ! initialization
 open(newunit=fid,file=TRIM(pdbname),status='old',position='append')
 do while(.true.)
  BACKSPACE(fid,iostat=i)
  if(i /= 0) exit
  BACKSPACE(fid,iostat=i)
  if(i /= 0) exit
  read(fid,'(A)') buf
  if(buf(1:5) == 'MODEL') exit
 end do ! for while

 close(fid)
 if(i /= 0) return ! assume 1 frame

 i = INDEX(buf, ' ')
 read(buf(i+1:),*) nframe
end subroutine read_nframe_from_pdb

! read the i-th frame from a given .pdb file
! Return cell, elem, resname and coor.
! If the cell size is not recorded in the pdf file, the array cell will be 0.
! If there is no residue name recorded, the array resname will be ' '
subroutine read_iframe_from_pdb(pdbname, iframe, natom, cell, elem, resname, coor)
 implicit none
 integer :: i, j, fid, iatom
 integer, intent(in) :: iframe, natom
 real(kind=8), dimension(6), intent(out) :: cell
 real(kind=8), dimension(3,natom), intent(out) :: coor
 character(len=6) :: str
 character(len=240) :: buf
 character*240, intent(in) :: pdbname
 character*2, dimension(natom), intent(out) :: elem
 character*3, dimension(natom), intent(out) :: resname

 elem = '  '    ! initialization
 resname = '   '
 cell = 0d0 ! a,b,c,alpha,beta,gama
 coor = 0d0

 if(natom <= 0) then
  write(6,'(A)') 'ERROR in subroutine read_iframe_from_pdb: natom<=0.'
  write(6,'(A,I0)') 'Your input natom=', natom
  stop
 end if

 open(newunit=fid,file=TRIM(pdbname),status='old',position='rewind')
 do while(.true.)
  read(fid,'(A)',iostat=i) buf
  if(i /= 0) exit
  if(buf(1:5) == 'MODEL') then
   read(buf(6:),*) j
   if(j == iframe) exit
  end if
 end do ! for while

 if(i /= 0) then
  if(iframe /= 1) then
   write(6,'(A)') 'ERROR in subroutine read_iframe_from_pdb: fail to read&
                  & the i-th frame in file '//TRIM(pdbname)
   write(6,'(A,I0)') 'iframe=', iframe
   close(fid)
   stop
  else ! iframe == 1
   rewind(fid)
   do while(.true.)
    read(fid,'(A)',iostat=i) buf
    if(i /= 0) exit
    if(buf(1:4)=='ATOM' .or. buf(1:6)=='HETATM') exit
   end do ! for while
   if(i /= 0) then
    write(6,'(A)') 'ERROR in subroutine read_iframe_from_pdb: failed to read&
                   & the 1st frame in file '//TRIM(pdbname)
    close(fid)
    stop
   end if
   BACKSPACE(fid)
  end if
 end if

 do i = 1, 2
  BACKSPACE(fid,iostat=j)
  if(j /= 0) exit
  BACKSPACE(fid,iostat=j)
  if(j /= 0) exit
  read(fid,'(A)') buf
  if(buf(1:6) == 'CRYST1') then
   read(buf,*) str, cell(1:6)
   exit
  end if
 end do ! for i

 do i = 1, 3
  read(fid,'(A)') buf
  if(buf(1:4)=='ATOM' .or. buf(1:6)=='HETATM') exit
 end do ! for j
 BACKSPACE(fid)

 read(fid,*) resname(1:4)
 resname(4) = ADJUSTL(resname(4))
 read(resname(4),fmt=*,iostat=i) j
 BACKSPACE(fid)
 iatom = 0

 if(i /= 0) then ! the 4-th column is residue name
  do while(.true.)
   read(fid,'(A)') buf
   if(buf(1:3) == 'TER') cycle
   iatom = iatom + 1
   read(buf,*) str, j, elem(iatom), resname(iatom), j, coor(1:3,iatom)
   if(iatom == natom) exit
  end do ! for while
 else            ! the 4-th column is integer
  do while(.true.)
   read(fid,'(A)') buf
   if(buf(1:3) == 'TER') cycle
   iatom = iatom + 1
   read(buf,*) str, j, elem(iatom), j, coor(1:3,iatom)
   if(iatom == natom) exit
  end do ! for while
 end if

 close(fid)
 do i = 1, natom, 1
  j = IACHAR(elem(i)(2:2))
  if(j>47 .and. j<58) elem(i)(2:2) = ' '
 end do ! for i
end subroutine read_iframe_from_pdb

! read Cartesian coordinates from a (Open)Molcas output file
subroutine read_coor_from_molcas_out(outname, natom, coor)
 implicit none
 integer :: i, j, k, fid
 integer, intent(in) :: natom
 real(kind=8), intent(out) :: coor(3,natom)
 character(len=6) :: str
 character(len=240) :: buf
 character(len=240), intent(in) :: outname

 buf = ' '
 coor = 0d0
 open(newunit=fid,file=TRIM(outname),status='old',position='append')

 do while(.true.)
  BACKSPACE(fid)
  BACKSPACE(fid)
  read(fid,'(A)') buf
  if(buf(4:21) == 'This run of MOLCAS') then
   write(6,'(A)') "ERROR in subroutine read_coor_from_molcas_out: failed to&
                    & find 'Cartesian coordinates in A'"
   write(6,'(A)') 'keywords in file '//TRIM(outname)
   close(fid)
   stop
  end if
  if(buf(7:32) == 'Cartesian coordinates in A') exit
 end do ! for while

 do i = 1, 3
  read(fid,'(A)') buf
 end do

 do i = 1, natom, 1
  read(fid,*,iostat=j) k, str, coor(1:3,i)
  if(j /= 0) then
   write(6,'(A)') 'ERROR in subroutine read_coor_from_molcas_out: insufficient&
                    & number of atoms in file '//TRIM(outname)
   write(6,'(2(A,I0))') 'natom=', natom, ', but broken at i=', i
   close(fid)
   stop
  end if
 end do ! for i

 close(fid)
end subroutine read_coor_from_molcas_out

! read Cartesian coordinates from a Molpro output file
subroutine read_coor_from_molpro_out(outname, natom, coor)
 implicit none
 integer :: i, fid
 integer, intent(in) :: natom
 real(kind=8), intent(out) :: coor(3,natom)
 character(len=2) :: elem = ' '
 character(len=240) :: buf
 character(len=240), intent(in) :: outname

 coor = 0d0
 open(newunit=fid,file=TRIM(outname),status='old',position='append')

 do while(.true.)
  BACKSPACE(fid)
  BACKSPACE(fid)
  read(fid,'(A)') buf
  if(buf(2:13) == 'Current geom') exit

  if(buf(2:13) == 'Primary work') then
   write(6,'(A)') "ERROR in subroutine read_coor_from_molpro_out: no '&
                   &Current geom' found in file "//TRIM(outname)
   close(fid)
   stop
  end if
 end do ! for while

 do i = 1, 3
  read(fid,'(A)') buf
 end do

 do i = 1, natom, 1
  read(fid,*) elem, coor(1:3,i)
 end do ! for i

 close(fid)
end subroutine read_coor_from_molpro_out

! read Cartesian coordinates from an ORCA .engrad file
subroutine read_coor_from_engrad(engrad, natom, coor)
 use phys_cons, only: Bohr_const
 implicit none
 integer :: i, j, fid
 integer, intent(in) :: natom
 real(kind=8), intent(out) :: coor(3,natom)
 character(len=240) :: buf
 character(len=240), intent(in) :: engrad

 coor = 0d0
 open(newunit=fid,file=TRIM(engrad),status='old',position='rewind')

 do while(.true.)
  read(fid,'(A)',iostat=i) buf
  if(i /= 0) exit
  if(buf(1:14) == '# The atomic n') exit
 end do ! for while

 read(fid,'(A)') buf
 do i = 1, natom, 1
  read(fid,*) j, coor(:,i) ! unit in Bohr
 end do ! for i

 close(fid)
 coor = coor*Bohr_const
end subroutine read_coor_from_engrad

! write/create a Gaussian .EOu file
subroutine write_EOu(EOu, e, natom, grad)
 implicit none
 integer :: fid
 integer, intent(in) :: natom
 real(kind=8), intent(in) :: e, grad(3*natom)
 character(len=720), intent(in) :: EOu

 open(newunit=fid,file=TRIM(EOu),status='replace',position='rewind')
 write(fid,'(4D20.12)') e, 0d0,0d0,0d0
 write(fid,'(3D20.12)') grad
 close(fid)
end subroutine write_EOu

subroutine split_pbc_xyz_into_gjf(xyzname)
 implicit none
 integer :: i, j, natom, nfile, fid
 real(kind=8), allocatable :: coor(:,:)
 character(len=2), allocatable :: elem(:)
 character(len=240) :: buf, proname, gjfname
 character(len=240), intent(in) :: xyzname
!f2py intent(in) :: xyzname

 i = INDEX(xyzname, '.xyz', back=.true.)
 proname = xyzname(1:i-1)
 open(newunit=fid,file=TRIM(xyzname),status='old',position='rewind')
 nfile = 0

 do while(.true.)
  read(fid,'(A)',iostat=i) buf
  if(i /= 0) exit
  nfile = nfile + 1
  write(gjfname,'(A,I0,A)') TRIM(proname)//'_', nfile, '.gjf'
  read(buf,*) natom
  read(fid,'(A)') buf
  allocate(elem(natom+3), coor(3,natom+3))
  elem(natom+1:natom+3) = 'Tv'
  i = INDEX(buf, "Lattice=")
  j = INDEX(buf(i+9:), """")
  read(buf(i+9:i+7+j),*) coor(:,natom+1:natom+3)
  do i = 1, natom, 1
   read(fid,*) elem(i), coor(:,i)
  end do ! for i
  call write_gjf(gjfname, 0, 1, natom+3, elem, coor)
  deallocate(elem, coor)
 end do ! for while

 close(fid)
end subroutine split_pbc_xyz_into_gjf

! write/create a .gjf file
subroutine write_gjf(gjfname, charge, mult, natom, elem, coor)
 implicit none
 integer :: i, fid
 integer, intent(in) :: charge, mult, natom
 real(kind=8), intent(in) :: coor(3,natom)
 character(len=240) :: chkname
 character(len=2), intent(in) :: elem(natom)
 character(len=240), intent(in) :: gjfname

 call find_specified_suffix(gjfname, '.gjf', i)
 chkname = gjfname(1:i-1)//'.chk'

 open(newunit=fid,file=TRIM(gjfname),status='replace')
 write(fid,'(A)') '%chk='//TRIM(chkname)
 write(fid,'(A)') '%nprocshared=4'
 write(fid,'(A)') '%mem=2GB'
 write(fid,'(A,//,A,//,I0,1X,I0)') '#p B3LYP/6-31G(d,p) em=GD3BJ nosymm', &
                                   'Title', charge, mult
 do i = 1, natom, 1
  write(fid,'(A2,3(1X,F18.8))') elem(i), coor(:,i)
 end do ! for i

 write(fid,'(/)',advance='no')
 close(fid)
end subroutine write_gjf

! write/create a .xyz file
subroutine write_xyzfile(natom, elem, coor, xyzname)
 implicit none
 integer :: i, fid
 integer, intent(in) :: natom
!f2py intent(in) :: natom
 real(kind=8), dimension(3,natom), intent(in) :: coor
!f2py intent(in) :: coor
!f2py depend(natom) :: coor
 character*2, dimension(natom), intent(in) :: elem
!f2py intent(in) :: elem
!f2py depend(natom) :: elem
 character*240, intent(in) :: xyzname
!f2py intent(in) :: xyzname

 open(newunit=fid,file=TRIM(xyzname),status='replace')
 write(fid,'(I0)') natom
 write(fid,'(A)') 'xyz format file produced by rwgeom of MOKIT'

 do i = 1, natom, 1
  write(fid,'(A2,3(1X,F18.8))') elem(i), coor(1:3,i)
 end do ! for i

 close(fid)
end subroutine write_xyzfile

! write a frame of molecule into a given .pdb file
subroutine write_frame_into_pdb(pdbname, iframe, natom, cell, elem, resname, &
                                coor, append)
 implicit none
 integer :: i, fid
 integer, intent(in) :: iframe, natom
!f2py intent(in) iframe, natom
 character*240, intent(in) :: pdbname
!f2py intent(in) pdbname
 character*2, dimension(natom), intent(in) :: elem
!f2py intent(in) elem
!f2py depend(natom) elem
 character*3, dimension(natom), intent(in) :: resname
!f2py intent(in) resname
!f2py depend(natom) resname
 real(kind=8), intent(in) :: cell(6), coor(3,natom)
!f2py intent(in) cell, coor
!f2py depend(natom) cell, coor
 logical, intent(in) :: append
!f2py intent(in) append

 if(append) then
  open(newunit=fid,file=TRIM(pdbname),status='old',position='append')
 else
  open(newunit=fid,file=TRIM(pdbname),status='replace')
 end if

 write(fid,'(A)') 'REMARK   1 File created by rwgeom of MOKIT'
 if(ANY(cell > 1d-4)) then
  write(fid,'(A,3(1X,F8.3),3(1X,F6.2),A)') 'CRYST1',cell(1:3),cell(4:6),' P 1           1'
 end if
 if(iframe > 0) write(fid,'(A,1X,I8)') 'MODEL',iframe

 do i = 1, natom, 1
  if(LEN_TRIM(resname(i)) == 0) then
   write(fid,'(A6,I5,2X,A2,10X,I1,4X,3F8.3,A)') 'HETATM', i, elem(i), 0, &
    coor(1:3,i),'  1.00  0.00'
  else
   write(fid,'(A4,I7,2X,A2,2X,A3,5X,I1,4X,3F8.3,A)') 'ATOM', i, elem(i), &
    resname(i), 0, coor(1:3,i), '  1.00  0.00'
  end if
 end do ! for i

 write(fid,'(A)') 'END'
 close(fid)
end subroutine write_frame_into_pdb

! calculate an internal coordinate (bond, angle, or dihedral)
function calc_an_int_coor(n, coor) result(val)
 implicit none
 integer, intent(in) :: n
 real(kind=8) :: r1(3), r2(3), norm_1, norm_2, cos_a, val
 real(kind=8), intent(in) :: coor(3,n)

 val = 0d0
 r1 = coor(:,1) - coor(:,2)
 norm_1 = DSQRT(DOT_PRODUCT(r1,r1))

 select case(n)
 case(2) ! bond
  val = norm_1
 case(3) ! angle
  r2 = coor(:,3) - coor(:,2)
  norm_2 = DSQRT(DOT_PRODUCT(r2,r2))
  cos_a = DOT_PRODUCT(r1,r2)/(norm_1*norm_2)
  val = DACOS(cos_a)
 case(4) ! dihedral

 case default
  write(6,'(/,A,I0)') 'ERROR in function calc_an_int_coor: invalid n=',n
  stop
 end select
end function calc_an_int_coor

! generate a Hydrogen ring
subroutine gen_h_ring(numh, d_h_h, gjfname)
 implicit none
 integer :: i, mult
 integer, intent(in) :: numh
!f2py intent(in) :: numh
 real(kind=8) :: r, theta, c
 real(kind=8), intent(in) :: d_h_h ! in Angstrom
!f2py intent(in) :: d_h_h
 real(kind=8), parameter :: PI = 4d0*DATAN(1d0)
 real(kind=8), allocatable :: coor(:,:)
 character(len=2), allocatable :: elem(:)
 character(len=240), intent(in) :: gjfname
!f2py intent(in) :: gjfname

 mult = 1
 if(MOD(numh,2) == 1) mult = 2
 allocate(coor(3,numh), source=0d0)

 theta = 2d0*PI/DBLE(numh)
 r = d_h_h*DSIN((PI-theta)*0.5d0)/DSIN(theta)

 do i = 1, numh, 1
  c = theta*DBLE(i-1)
  coor(1,i) = DCOS(c)
  coor(2,i) = DSIN(c)
 end do ! for i
 coor = coor*r

 allocate(elem(numh))
 elem = 'H '

 call write_gjf(gjfname, 0, mult, numh, elem, coor)
 deallocate(elem, coor)
end subroutine gen_h_ring

! generate a linear Hydrogen chain
subroutine gen_h_chain(numh, d_h_h, gjfname)
 implicit none
 integer :: i, mult
 integer, intent(in) :: numh
!f2py intent(in) :: numh
 real(kind=8), intent(in) :: d_h_h ! in Angstrom
!f2py intent(in) :: d_h_h
 real(kind=8), allocatable :: coor(:,:)
 character(len=2), allocatable :: elem(:)
 character(len=240), intent(in) :: gjfname
!f2py intent(in) :: gjfname

 mult = 1
 if(MOD(numh,2) == 1) mult = 2
 allocate(coor(3,numh), source=0d0)

 do i = 1, numh, 1
  coor(3,i) = DBLE(i-1)*d_h_h
 end do ! for i

 allocate(elem(numh))
 elem = 'H '

 call write_gjf(gjfname, 0, mult, numh, elem, coor)
 deallocate(elem, coor)
end subroutine gen_h_chain

! replace Cartesian coordinates in .fch(k) file by coordinates from .gjf
subroutine replace_coor_in_fch_by_gjf(gjfname, fchname)
 implicit none
 integer :: natom
 real(kind=8), allocatable :: coor(:,:)
 character(len=2), allocatable :: elem(:)
 character(len=240), intent(in) :: gjfname, fchname
!f2py intent(in) :: gjfname, fchname

 call read_natom_from_gjf(gjfname, natom)
 allocate(elem(natom), coor(3,natom))
 call read_elem_and_coor_from_file(gjfname, natom, elem, coor)
 deallocate(elem)
 call replace_coor_in_fch(fchname, natom, coor)
 deallocate(coor)
end subroutine replace_coor_in_fch_by_gjf

! replace Cartesian coordinates in .fch(k) file by coordinates from .engrad
subroutine replace_coor_in_fch_by_engrad(engrad, fchname)
 implicit none
 integer :: natom
 real(kind=8), allocatable :: coor(:,:)
 character(len=240), intent(in) :: engrad, fchname

 call read_natom_from_engrad(engrad, natom)
 allocate(coor(3,natom))
 call read_coor_from_engrad(engrad, natom, coor)
 call replace_coor_in_fch(fchname, natom, coor)
 deallocate(coor)
end subroutine replace_coor_in_fch_by_engrad

! convert a .fch(k) file into a .xyz file
subroutine fch2xyz(fchname)
 implicit none
 integer :: i, natom, charge, mult
 integer, allocatable :: nuc(:)
 real(kind=8), allocatable :: coor(:,:)
 character(len=2), allocatable :: elem(:)
 character(len=240) :: xyzname
 character(len=240), intent(in) :: fchname
!f2py intent(in) :: fchname

 call find_specified_suffix(fchname, '.fch', i)
 xyzname = fchname(1:i-1)//'.xyz'

 call read_natom_from_fch(fchname, natom)
 allocate(nuc(natom), coor(3,natom), elem(natom))
 call read_elem_and_coor_from_fch(fchname, natom, elem, nuc, coor, charge, mult)
 deallocate(nuc)

 call write_xyzfile(natom, elem, coor, xyzname)
 deallocate(elem, coor)
end subroutine fch2xyz

! convert a .gjf file into a .xyz file
subroutine gjf2xyz(gjfname)
 implicit none
 integer :: i, natom, charge, mult
 integer, allocatable :: nuc(:)
 real(kind=8), allocatable :: coor(:,:)
 character(len=2), allocatable :: elem(:)
 character(len=240) :: xyzname
 character(len=240), intent(in) :: gjfname
!f2py intent(in) :: gjfname

 call find_specified_suffix(gjfname, '.gjf', i)
 xyzname = gjfname(1:i-1)//'.xyz'

 call read_natom_from_gjf(gjfname, natom)
 allocate(elem(natom), nuc(natom), coor(3,natom))
 call read_elem_and_coor_from_gjf(gjfname, natom, elem, nuc, coor, charge, mult)
 deallocate(nuc)
 call write_xyzfile(natom, elem, coor, xyzname)
 deallocate(elem, coor)
end subroutine gjf2xyz

! convert a .xyz file into a .gjf file
subroutine xyz2gjf(xyzname)
 implicit none
 integer :: i, natom, charge, mult
 real(kind=8), allocatable :: coor(:,:)
 character(len=2), allocatable :: elem(:)
 character(len=240) :: gjfname
 character(len=240), intent(in) :: xyzname
!f2py intent(in) :: xyzname

 call find_specified_suffix(xyzname, '.xyz', i)
 gjfname = xyzname(1:i-1)//'.gjf'
 charge = 0; mult = 1  ! initialization

 call read_natom_from_xyz(xyzname, natom)
 allocate(elem(natom), coor(3,natom))
 call read_elem_and_coor_from_xyz(xyzname, natom, elem, coor)
 call write_gjf(gjfname, charge, mult, natom, elem, coor)
 deallocate(elem, coor)
end subroutine xyz2gjf

! enlarge a cell in a specified .gjf file
subroutine enlarge_cell_in_gjf(gjfname, nd)
 implicit none
 integer :: i, natom, natom1, charge, mult, ntimes, nt(3)
 integer, intent(in) :: nd(3) ! [nx,ny,nz]
!f2py intent(in) :: nd
 integer, allocatable :: nuc(:)
 character(len=2), allocatable :: elem(:), elem1(:)
 character(len=240) :: gjfname1
 character(len=240), intent(in) :: gjfname
!f2py intent(in) :: gjfname
 real(kind=8) :: lat_vec(3,3)
 real(kind=8), allocatable :: coor(:,:), coor1(:,:)

 i = INDEX(gjfname, '.gjf', back=.true.)
 gjfname1 = gjfname(1:i-1)//'_new.gjf'

 call read_natom_from_gjf_pbc(gjfname, natom)
 allocate(elem(natom), nuc(natom), coor(3,natom))
 call read_elem_and_coor_from_gjf_pbc(gjfname, natom, elem, nuc, coor, lat_vec,&
                                      charge, mult)
 deallocate(nuc)
 nt = nd
 forall(i = 1:3, nt(i)<0) nt(i) = -nt(i)
 ntimes = (nt(1)+1)*(nt(2)+1)*(nt(3)+1)
 natom1 = natom*ntimes
 charge = charge*ntimes
 mult = (mult-1)*ntimes + 1

 allocate(elem1(natom1+3), coor1(3,natom1+3))
 call duplicate_cell(natom, elem, coor, lat_vec, nt, natom1, elem1(1:natom1), &
                     coor1(:,1:natom1))
 deallocate(elem, coor)

 elem1(natom1+1:natom1+3) = 'Tv'
 forall(i = 1:3) coor1(:,natom1+i) = lat_vec(:,i)
 call write_gjf(gjfname1, charge, mult, natom1+3, elem1, coor1)
 deallocate(elem1, coor1)
end subroutine enlarge_cell_in_gjf

! generate molecule clusters using each monomer in a cell as a center
subroutine gen_cluster_from_cell(gjfname, dis_thres)
 use fch_content, only: nuc2elem
 implicit none
 integer :: i, j, k, m, n, p, q, r, n1, n2, fid
 integer :: natom, natom_old, natom_new, nconn, nmol, charge, mult
 integer, allocatable :: nuc(:), conn(:,:), map(:,:), idx(:)
 real(kind=8) :: min_dis, curr_dis, vt(3), lat_vec(3,3)
 real(kind=8), intent(in) :: dis_thres
!f2py intent(in) :: dis_thres
 real(kind=8), allocatable :: coor(:,:), dis(:,:), mol_dis(:,:)
 character(len=2), allocatable :: elem(:)
 character(len=240) :: proname, gjfname1
 character(len=240), intent(in) :: gjfname
!f2py intent(in) :: gjfname
 type :: molecule_map
  integer :: natom = 0 ! No. of atoms in this cluster
  integer :: nadj = 0  ! No. of adjcent molecules within dis_thres
  integer, allocatable :: idx(:)  ! size natom
  integer, allocatable :: adjm(:) ! size nadj
  logical :: deleted = .false.
 end type molecule_map
 type(molecule_map), allocatable :: mol_map(:)
 logical, allocatable :: assigned(:), new_mol(:)

 call complement_mol_around_cell(gjfname, dis_thres)
 i = INDEX(gjfname, '.gjf', back=.true.)
 proname = gjfname(1:i-1)
 gjfname1 = gjfname(1:i-1)//'_new.gjf'

 call read_natom_from_gjf_pbc(gjfname1, natom)
 allocate(elem(natom), nuc(natom), coor(3,natom))
 call read_elem_and_coor_from_gjf_pbc(gjfname1, natom, elem, nuc, coor, &
                                      lat_vec, charge, mult)
 deallocate(elem)
 allocate(dis(natom,natom), conn(natom,natom))
 call gen_conn_from_coor(natom, coor, nuc, dis, conn)
 call find_nmol_from_conn(natom, conn, nmol)

 allocate(mol_map(nmol), assigned(natom))
 assigned = .false.
 nmol = 0

 do i = 1, natom, 1
  if(assigned(i)) cycle

  allocate(new_mol(i:natom))
  new_mol = .false.
  new_mol(i) = .true.
  natom_old = 1

  do while(.true.)
   do j = i, natom, 1
    if(.not. new_mol(j)) cycle
    nconn = COUNT(conn(:,j) > 0)
    if(nconn == 0) cycle
    ! Here only conn(:,j)>0 need to be checked, but we do not have the type
    ! array adj, so we loop from 1 to natom.
    do k = 1, natom, 1
     if(conn(k,j)==0 .or. k==j) cycle
     assigned(k) = .true.
     new_mol(k) = .true.
    end do ! for k
   end do ! for j

   natom_new = COUNT(new_mol .eqv. .true.)
   if(natom_new == natom_old) then
    exit
   else if(natom_new > natom_old) then
    natom_old = natom_new
   else
    write(6,'(/,A)') 'ERROR in subroutine gen_cluster_from_cell: natom_new < na&
                     &tom_old. Impossible.'
    write(6,'(A,I0)') 'natom=', natom
    stop
   end if
  end do ! for while

  assigned(i) = .true.
  nmol = nmol + 1
  mol_map(nmol)%natom = natom_new
  allocate(mol_map(nmol)%idx(natom_new))
  k = 0
  do j = i, natom, 1
   if(.not. new_mol(j)) cycle
   k = k + 1
   mol_map(nmol)%idx(k) = j
  end do ! for j
  deallocate(new_mol)
 end do ! for i

 deallocate(assigned, conn)
 n = nmol
 k = n*(n-1)/2
 allocate(map(2,k))
 forall(i=1:n-1, j=1:n, j>i) map(:,(2*n-i)*(i-1)/2+j-i) = [i,j]

 ! calculate the minimum distance between any two molecules
 allocate(mol_dis(n,n))
 forall(i = 1:n) mol_dis(i,i) = 0d0
!$omp parallel do schedule(dynamic) default(private) &
!$omp shared(k, map, dis, mol_map, mol_dis)
 do m = 1, k, 1
  i = map(1,m); j = map(2,m)
  min_dis = dis(mol_map(i)%idx(1), mol_map(j)%idx(1))
  n1 = mol_map(i)%natom; n2 = mol_map(j)%natom

  do p = 1, n1, 1
   r = mol_map(i)%idx(p)
   do q = 1, n2, 1
    curr_dis = dis(r, mol_map(j)%idx(q))
    if(curr_dis < min_dis) min_dis = curr_dis
   end do ! for q
  end do ! for p

  mol_dis(j,i) = min_dis
  mol_dis(i,j) = mol_dis(j,i)
 end do ! for m
!$omp end parallel do
 deallocate(dis)

 ! assuming orthogonal lattice, find molecules whose any atoms are in the cell
 forall(i = 1:3) vt(i) = lat_vec(i,i)
 mol_map(:)%deleted = .true.
 do i = 1, nmol, 1
  p = mol_map(i)%natom
  do j = 1, p, 1
   m = mol_map(i)%idx(j)
   if(ALL(coor(:,m) >0d0) .and. coor(1,m)<vt(1) .and. coor(2,m)<vt(2) .and. &
      coor(3,m)<vt(3)) then
    mol_map(i)%deleted = .false.
    exit
   end if
  end do ! for j
 end do ! for i

 ! construct molecules clusters
 do i = 1, nmol, 1
  if(mol_map(i)%deleted) cycle

  p = COUNT(mol_dis(:,i) < dis_thres)
  ! the central molecule is also included
  mol_map(i)%nadj = p
  allocate(mol_map(i)%adjm(p))
  m = 0
  do j = 1, nmol, 1
   if(mol_dis(j,i) < dis_thres) then
    m = m + 1
    mol_map(i)%adjm(m) = j
   end if
  end do ! for j
 end do ! for i
 deallocate(mol_dis)

 ! delete identical clusters
 do m = 1, k, 1
  i = map(1,m); j = map(2,m)
  if(mol_map(i)%deleted .or. mol_map(j)%deleted) cycle
  p = mol_map(i)%nadj
  if(p /= mol_map(j)%nadj) cycle
  allocate(idx(p))
  call sort_int_array(p, mol_map(i)%adjm, .true., idx)
  call sort_int_array(p, mol_map(j)%adjm, .true., idx)
  deallocate(idx)
  if(ALL(mol_map(i)%adjm==mol_map(j)%adjm)) mol_map(j)%deleted = .true.
 end do ! for m
 deallocate(map)

 n = 0
 do i = 1, nmol, 1
  if(mol_map(i)%deleted) cycle
  n = n + 1
  write(gjfname1,'(A,I0,A)') TRIM(proname)//'_', n, '.inp'
  open(newunit=fid,file=TRIM(gjfname1),status='replace')
  write(fid,'(A)') '%pal nprocs 64 end'
  write(fid,'(A)') '%maxcore 2968'
  !write(fid,'(A)') '! wB97M-V TightSCF noTRAH defgrid3 RIJCOSX def2-TZVP def2/J&
  !                 & EnGrad'
  write(fid,'(A)') '! PBE TightSCF noTRAH defgrid3 def2-TZVP def2/J EnGrad'
  write(fid,'(A)') '%scf'
  write(fid,'(A)') ' Thresh 1e-12'
  write(fid,'(A)') ' Tcut 1e-14'
  write(fid,'(A)') 'end'
  write(fid,'(A)') '* xyz 0 1'
  m = mol_map(i)%nadj
  do j = 1, m, 1
   q = mol_map(i)%adjm(j)
   r = mol_map(q)%natom
   do k = 1, r, 1
    write(fid,'(A,3(1X,F18.8))') nuc2elem(nuc(mol_map(q)%idx(k))), &
                                 coor(:,mol_map(q)%idx(k))
   end do ! for k
  end do ! for j
  write(fid,'(A)') '*'
  close(fid)
 end do ! for i
end subroutine gen_cluster_from_cell

! complement molecules around a cell according to a distance threshold
subroutine complement_mol_around_cell(gjfname, dis)
 use fch_content, only: elem2nuc
 use periodic_table, only: cov_rad, rfac1
 implicit none
 integer :: i, j, k, natom, natom1, charge, mult, ntimes, nt(3)
 integer, allocatable :: nuc(:), istat(:)
 character(len=2), allocatable :: elem(:), elem1(:)
 character(len=240) :: gjfname1
 character(len=240), intent(in) :: gjfname
!f2py intent(in) :: gjfname
 real(kind=8) :: lat_vec(3,3), lat_vec1(3,3), norm(3), r1(3), dis0
 real(kind=8), intent(in) :: dis ! distance threshold
!f2py intent(in) :: dis
 real(kind=8), parameter :: max_dis = 5.8d0 ! Ang, maximum possible bond length
 real(kind=8), allocatable :: coor(:,:), coor1(:,:)

 i = INDEX(gjfname, '.gjf', back=.true.)
 gjfname1 = gjfname(1:i-1)//'_new.gjf'

 call read_natom_from_gjf_pbc(gjfname, natom)
 allocate(elem(natom), nuc(natom), coor(3,natom))
 call read_elem_and_coor_from_gjf_pbc(gjfname, natom, elem, nuc, coor, lat_vec,&
                                      charge, mult)
 deallocate(nuc)

 forall(i = 1:3)
  norm(i) = DSQRT(DOT_PRODUCT(lat_vec(:,i), lat_vec(:,i)))
  nt(i) = 2*CEILING(dis/norm(i))
 end forall
 ntimes = (nt(1)+1)*(nt(2)+1)*(nt(3)+1)
 natom1 = natom*ntimes
 charge = charge*ntimes
 mult = (mult-1)*ntimes + 1

 lat_vec1 = lat_vec
 allocate(elem1(natom1), coor1(3,natom1))
 call duplicate_cell(natom, elem, coor, lat_vec1, nt, natom1, elem1(1:natom1), &
                     coor1(:,1:natom1))
 deallocate(elem)
 r1 = DBLE(nt(1)/2)*lat_vec(:,1) + DBLE(nt(2)/2)*lat_vec(:,2) + &
      DBLE(nt(3)/2)*lat_vec(:,3)
 forall(i = 1:natom1) coor1(:,i) = coor1(:,i) - r1

 do k = 1, natom1, 1
  if(SUM(DABS(coor1(:,k) - coor(:,1))) < 1d-8) exit
 end do ! for i
 k = k - 1
 deallocate(coor)

 allocate(istat(natom1), source=0)
 istat(k+1:k+natom) = 1

 do i = k+1, k+natom, 1
  r1 = coor1(:,i)
  do j = 1, k, 1
   if(istat(j) == 2) cycle
   norm = DABS(coor1(:,j) - r1)
   if(ANY(norm > dis)) cycle
   dis0 = DSQRT(DOT_PRODUCT(norm, norm))
   if(dis0 < dis) istat(j) = 2
  end do ! for j
  do j = k+natom+1, natom1, 1
   if(istat(j) == 2) cycle
   norm = DABS(coor1(:,j) - r1)
   if(ANY(norm > dis)) cycle
   dis0 = DSQRT(DOT_PRODUCT(norm, norm))
   if(dis0 < dis) istat(j) = 2
  end do ! for j
 end do ! for i

 k = COUNT(istat > 0)
 do while(.true.)
  do i = 1, natom1, 1
   if(.not. (istat(i)==2 .or. istat(i)==3)) cycle
   r1 = coor1(:,i)
   do j = 1, natom1, 1
    if(istat(j) /= 0) cycle
    norm = DABS(coor1(:,j) - r1)
    if(ANY(norm > max_dis)) cycle
    dis0 = DSQRT(DOT_PRODUCT(norm, norm))
    if(dis0 > max_dis) cycle
    dis0 = dis0/(cov_rad(elem2nuc(elem1(i))) + cov_rad(elem2nuc(elem1(j))))
    if(dis0 < rfac1) istat(j) = 3
   end do ! for j
  end do ! for i

  natom = COUNT(istat > 0)
  if(natom == k) exit
  k = natom
 end do ! for while

 allocate(elem(natom+3), coor(3,natom+3))
 j = 0
 do i = 1, natom1, 1
  if(istat(i) == 0) cycle
  j = j + 1
  elem(j) = elem1(i)
  coor(:,j) = coor1(:,i)
 end do ! for i

 deallocate(istat, elem1, coor1)
 elem(natom+1:natom+3) = 'Tv'
 coor(:,natom+1:natom+3) = lat_vec
 call write_gjf(gjfname1, charge, mult, natom+3, elem, coor)
 deallocate(elem, coor)
end subroutine complement_mol_around_cell

! duplicate cells in +x,+y,+z directions
subroutine duplicate_cell(natom, elem, coor, lat_vec, nt, natom1, elem1, coor1)
 implicit none
 integer :: i, j, k, m, n, ntimes, nx, ny, nz
 integer, intent(in) :: natom, natom1, nt(3)
 real(kind=8) :: r1(3), r2(3), r3(3)
 real(kind=8), intent(in) :: coor(3,natom)
 real(kind=8), intent(inout) :: lat_vec(3,3)
 real(kind=8), intent(out) :: coor1(3,natom1)
 character(len=2), intent(in) :: elem(natom)
 character(len=2), intent(out) :: elem1(natom1)

 nx = nt(1) + 1; ny = nt(2) + 1; nz = nt(3) + 1
 ntimes = nx*ny*nz

 forall(i = 1:ntimes) elem1((i-1)*natom+1:i*natom) = elem
 forall(i = 1:ntimes) coor1(:,(i-1)*natom+1:i*natom) = coor

 do i = 1, nx, 1
  r1 = DBLE(i-1)*lat_vec(:,1)
  do j = 1, ny, 1
   r2 = DBLE(j-1)*lat_vec(:,2)
   do k = 1, nz, 1
    if(i==1 .and. j==1 .and. k==1) cycle
    r3 = DBLE(k-1)*lat_vec(:,3)

    m = ((i-1)*ny*nz + (j-1)*nz + k-1)*natom
    forall(n = 1:natom) coor1(:,m+n) = coor1(:,m+n) + r1 + r2 + r3
   end do ! for k
  end do ! for j
 end do ! for i

 r1 = [DBLE(nx), DBLE(ny), DBLE(nz)]
 forall(i = 1:3) lat_vec(:,i) = lat_vec(:,i)*r1(i)
end subroutine duplicate_cell

! find the number of molecules in a given file (.gjf/.xyz supported)
subroutine find_nmol_in_file(fname, nmol)
 use fch_content, only: elem2nuc
 implicit none
 integer :: i, natom, charge, mult
 integer, allocatable :: nuc(:), conn(:,:)
 integer, intent(out) :: nmol
!f2py intent(out) :: nmol
 real(kind=8), allocatable :: coor(:,:), dis(:,:)
 character(len=2), allocatable :: elem(:)
 character(len=240), intent(in) :: fname
!f2py intent(in) :: fname

 i = LEN_TRIM(fname)

 select case(fname(i-3:i))
 case('.xyz')
  call read_natom_from_xyz(fname, natom)
  allocate(elem(natom), nuc(natom), coor(3,natom))
  call read_elem_and_coor_from_xyz(fname, natom, elem, coor)
  forall(i = 1:natom) nuc(i) = elem2nuc(elem(i))
 case('.gjf')
  call read_natom_from_gjf(fname, natom)
  allocate(elem(natom), nuc(natom), coor(3,natom))
  call read_elem_and_coor_from_gjf(fname, natom, elem, nuc, coor, charge, mult)
 case default
  write(6,'(/,A)') 'ERROR in subroutine find_nmol_in_file: file format not supp&
                   &orted.'
  write(6,'(A)') 'Currently only .gjf/.xyz are supported.'
  stop
 end select

 deallocate(elem)
 allocate(dis(natom,natom), conn(natom,natom))
 call gen_conn_from_coor(natom, coor, nuc, dis, conn)
 deallocate(coor, nuc, dis)
 call find_nmol_from_conn(natom, conn, nmol)
 deallocate(conn)
end subroutine find_nmol_in_file

! generate connectivity from elements and Cartesian coordinates
subroutine gen_conn_from_coor(natom, coor, nuc, dis, conn)
 use periodic_table, only: cov_rad, rfac1, rfac2, rfac3
 implicit none
 integer :: i, j, k, m, n
 integer, intent(in) :: natom
 integer, intent(in) :: nuc(natom)
 integer, intent(out) :: conn(natom,natom)
 integer, allocatable :: map(:,:)
 real(kind=8) :: r
 real(kind=8), intent(in) :: coor(3,natom)
 real(kind=8), intent(out) :: dis(natom,natom)

 conn = 0 ! initialization
 n = natom
 call cal_dis_mat_from_coor(n, coor, dis)

 k = n*(n-1)/2
 allocate(map(2,k))
 forall(i=1:n-1, j=1:n, j>i) map(:,(2*n-i)*(i-1)/2+j-i) = [i,j]

 ! one composite loop is faster than two simple loops for OpenMP parallelism
!$omp parallel do schedule(dynamic) default(private) shared(k,map,nuc,dis,conn)
 do m = 1, k, 1
  i = map(1,m); j = map(2,m)
  r = dis(j,i)/(cov_rad(nuc(i)) + cov_rad(nuc(j)))

  if(r<rfac1 .and. r>rfac2) then
   conn(j,i) = 1; conn(i,j) = 1
  else if(r<rfac2 .and. r>rfac3) then
   conn(j,i) = 2; conn(i,j) = 2
  else if(r < rfac3) then
   conn(j,i) = 3; conn(i,j) = 3
  end if
 end do ! for m
!$omp end parallel do

 deallocate(map)
end subroutine gen_conn_from_coor

! find the number of molecules from the connectivity
subroutine find_nmol_from_conn(natom, conn, nmol)
 implicit none
 integer :: i, j, k, nconn, natom_old, natom_new
 integer, intent(in) :: natom
 integer, intent(in) :: conn(natom,natom)
 integer, intent(out) :: nmol
 logical, allocatable :: assigned(:), new_mol(:)

 nmol = 0
 allocate(assigned(natom))
 assigned = .false.

 do i = 1, natom, 1
  if(assigned(i)) cycle

  allocate(new_mol(i:natom))
  new_mol = .false.
  new_mol(i) = .true.
  natom_old = 1

  do while(.true.)
   do j = i, natom, 1
    if(.not. new_mol(j)) cycle
    nconn = COUNT(conn(:,j) > 0)
    if(nconn == 0) cycle
    ! Here only conn(:,j)>0 need to be checked, but we do not have the type
    ! array adj, so we loop from 1 to natom.
    do k = 1, natom, 1
     if(conn(k,j)==0 .or. k==j) cycle
     assigned(k) = .true.
     new_mol(k) = .true.
    end do ! for k
   end do ! for j

   natom_new = COUNT(new_mol .eqv. .true.)
   if(natom_new == natom_old) then
    exit
   else if(natom_new > natom_old) then
    natom_old = natom_new
   else
    write(6,'(/,A)') 'ERROR in subroutine find_nmol_from_conn: natom_new < nato&
                     &m_old. Impossible.'
    write(6,'(A,I0)') 'natom=', natom
    stop
   end if
  end do ! for while

  deallocate(new_mol)
  assigned(i) = .true.
  nmol = nmol + 1
 end do ! for i

 deallocate(assigned)
end subroutine find_nmol_from_conn

! get real(kind=8) data type of connectivities from elements and Cartesian
! coordinates
subroutine gen_rconn_from_coor(natom, coor, nuc, rconn)
 implicit none
 integer, intent(in) :: natom
 integer, intent(in) :: nuc(natom)
 integer, allocatable :: conn(:,:)
 real(kind=8), intent(in) :: coor(3,natom)
 real(kind=8), intent(out) :: rconn(natom,natom)
 real(kind=8), allocatable :: dis(:,:)

 allocate(dis(natom,natom), conn(natom,natom))
 call gen_conn_from_coor(natom, coor, nuc, dis, conn)
 deallocate(dis)
 rconn = DBLE(conn)
 deallocate(conn)
end subroutine gen_rconn_from_coor

! convert real(kind=8) type of conn into alternative Coulomb matrix
subroutine rconn2acoulomb(natom, nuc, rconn)
 implicit none
 integer :: i, j
 integer, intent(in) :: natom
 integer, intent(in) :: nuc(natom)
 real(kind=8), intent(inout) :: rconn(natom,natom)

 forall(i = 1:natom) rconn(i,i) = DBLE(nuc(i)*nuc(i))
 forall(i=1:natom, j=1:natom, j>i)
  rconn(j,i) = rconn(j,i)*DBLE(nuc(j)*nuc(i))
  rconn(i,j) = rconn(j,i)
 end forall
end subroutine rconn2acoulomb

! Check whether two geometries are conformers of each other.
! TODO: distinguish R/S/M/P chirality.
subroutine check_if_conformer(fname1, fname2, conformer)
 implicit none
 integer :: natom, natom1, natom2
 integer, allocatable :: nuc1(:), nuc2(:), nuc3(:), nuc4(:), idx(:)
 real(kind=8), parameter :: thres1 = 1d-7, thres2 = 1d-3
 real(kind=8), allocatable :: coor1(:,:), coor2(:,:), conn1(:,:), conn2(:,:), &
  conn3(:,:), conn4(:,:), w1(:), w2(:)
 character(len=240), intent(in) :: fname1, fname2
!f2py intent(in) :: fname1, fname2
 logical, intent(out) :: conformer
!f2py intent(out) :: conformer

 conformer = .false. ! initialization

 ! check whether the number of atoms in two files are equal
 call read_natom_from_file(fname1, natom1)
 call read_natom_from_file(fname2, natom2)
 if(natom1 /= natom2) return

 ! check whether the elements in two files are equal
 natom = natom1
 allocate(nuc1(natom), nuc2(natom), coor1(3,natom), coor2(3,natom))
 call read_nuc_and_coor_from_file(fname1, natom, nuc1, coor1)
 call read_nuc_and_coor_from_file(fname2, natom, nuc2, coor2)
 allocate(nuc3(natom), source=nuc1)
 allocate(nuc4(natom), source=nuc2)
 allocate(idx(natom))
 call sort_int_array(natom, nuc3, .true., idx)
 call sort_int_array(natom, nuc4, .true., idx)
 deallocate(idx)
 deallocate(nuc3, nuc4)
 if(.not. ALL(nuc3 == nuc4)) then
  deallocate(nuc1, nuc2, coor1, coor2)
  return
 end if

 ! Check the eigenvalues of two connectivity matrices
 ! Be careful: here conn1 and conn2 are real(kind=8) type.
 allocate(conn1(natom,natom), conn2(natom,natom))
 call gen_rconn_from_coor(natom, coor1, nuc1, conn1)
 call gen_rconn_from_coor(natom, coor2, nuc2, conn2)
 deallocate(coor1, coor2)
 allocate(conn3(natom,natom), source=conn1) ! backup
 allocate(conn4(natom,natom), source=conn2) ! backup
 allocate(w1(natom), w2(natom))
 call diag_get_e_and_vec(natom, conn3, w1)
 call diag_get_e_and_vec(natom, conn4, w2)
 deallocate(conn3, conn4)
 if(SUM(DABS(w1 - w2)) > thres1) then
  deallocate(nuc1, nuc2, conn1, conn2, w1, w2)
  return
 end if

 ! Now the eigenvalues are alomost identical. But some cases cannot be identified,
 ! e.g. o-/m-/p- disubstituted benzene. To distinguish these, alternative Coulomb
 ! matrix is needed.
 call rconn2acoulomb(natom, nuc1, conn1)
 call rconn2acoulomb(natom, nuc2, conn2)
 deallocate(nuc1, nuc2)
 call diag_get_e_and_vec(natom, conn1, w1)
 call diag_get_e_and_vec(natom, conn2, w2)
 deallocate(conn1, conn2)
 if(SUM(DABS(w1 - w2)) < thres2) conformer = .true.
 deallocate(w1, w2)
end subroutine check_if_conformer

