! written by jxzou at 20210210: convert a GAMESS .inp file into a PSI4 input file

program main
 implicit none
 integer :: i
 character(len=4) :: str
 character(len=240) :: inpname
 logical :: sph

 i = iargc()
 if(i<1 .or. i>2) then
  write(6,'(/,A)') ' ERROR in subroutine bas_gms2psi: wrong command line arguments!'
  write(6,'(A)')   ' Example 1: bas_gms2psi a.inp'
  write(6,'(A,/)') ' Example 2: bas_gms2psi a.inp -sph'
  stop
 end if

 str = ' '; inpname = ' '; sph = .false.
 call getarg(1, inpname)
 call require_file_exist(inpname)

 if(i == 2) then
  call getarg(2, str)
  if(str == '-sph') then
   sph = .true.
  else
   write(6,'(/,A)') 'ERROR in subroutine bas_gms2psi: wrong command line arguments.'
   write(6,'(A)') "The 2nd argument can only be '-sph'. But got '"//str//"'"
   stop
  end if
 end if

 call bas_gms2psi(inpname, sph)
end program main

! convert a GAMESS .inp file into a PSI4 input file
subroutine bas_gms2psi(inpname, sph)
 use pg, only: natom, nuc, elem, coor, ntimes, all_ecp, ecp_exist
 implicit none
 integer :: i, j, k, m, n, nline, rel, charge, mult, isph, fid1, fid2
 real(kind=8) :: rtmp(3)
 character(len=1), parameter :: am(0:6) = ['s','p','d','f','g','h','i']
 character(len=2) :: stype
 character(len=240) :: buf, inpname1, fileA, fileB
 character(len=240), intent(in) :: inpname
 logical :: uhf, ghf, X2C
 logical, intent(in) :: sph
 logical, allocatable :: ghost(:)

 call find_specified_suffix(inpname, '.inp', i)
 inpname1 = inpname(1:i-1)//'_psi.inp'
 fileA = inpname(1:i-1)//'.A'
 fileB = inpname(1:i-1)//'.B'

 call check_X2C_in_gms_inp(inpname, X2C)
 call read_charge_mult_isph_from_gms_inp(inpname, charge, mult, isph, uhf, ghf,&
                                         ecp_exist)
 call read_natom_from_gms_inp(inpname, natom)
 allocate(elem(natom), coor(3,natom), ntimes(natom), nuc(natom), ghost(natom))
 call read_elem_nuc_coor_from_gms_inp(inpname, natom, elem, nuc, coor, ghost)
 deallocate(nuc, ghost)
 call calc_ntimes(natom, elem, ntimes)

 open(newunit=fid2,file=TRIM(inpname1),status='replace')
 write(fid2,'(A)') '# generated by utility bas_gms2psi of MOKIT'
 write(fid2,'(A)') 'memory 4 GB'
 write(fid2,'(/,A)') 'molecule mymol {'
 write(fid2,'(A)') 'symmetry C1'
 write(fid2,'(A)') 'no_reorient'
 write(fid2,'(I0,1X,I0)') charge, mult

 do i = 1, natom, 1
  write(fid2,'(A,I0,3(2X,F15.8))') TRIM(elem(i)), ntimes(i), coor(1:3,i)
 end do ! for i

 deallocate(coor)
 write(fid2,'(A)') '}'
 write(fid2,'(/,A)') 'basis mybas {'

 do i = 1, natom, 1
  write(fid2,'(2(A,I0))') ' assign '//TRIM(elem(i)),ntimes(i),' gen',i
 end do ! for i

 call read_all_ecp_from_gms_inp(inpname)
 call goto_data_section_in_gms_inp(inpname, fid1)
 read(fid1,'(A)') buf
 read(fid1,'(A)') buf

 do i = 1, natom, 1
  read(fid1,'(A)') buf ! buf contains elem(i), nuc(i) and coor(1:3,i)
  write(fid2,'(A,I0,A)') '[gen', i, ']'
  if(sph) then
   write(fid2,'(A)') 'spherical'
  else
   write(fid2,'(A)') 'cartesian'
  end if
  write(fid2,'(A)') '****'
  write(fid2,'(A)') TRIM(elem(i))//' 0'

  do while(.true.)
   read(fid1,'(A)') buf
   if(LEN_TRIM(buf) == 0) then
    write(fid2,'(A)') '****'
    exit
   end if

   read(buf,*) stype, nline
   if(stype == 'L') then
    stype = 'SP'; k = 3
   else
    k = 2
   end if
   write(fid2,'(A,1X,I3,A)') TRIM(stype), nline, '  1.00'

   rtmp = 0d0
   do j = 1, nline, 1
    read(fid1,*) m, rtmp(1:k)
    write(fid2,'(3(2X,ES16.9))') rtmp(1:k)
   end do ! for j
  end do ! for while

  if(all_ecp(i)%ecp) then
   write(fid2,'(A)') TRIM(elem(i))//'   0'
   m = all_ecp(i)%highest
   write(fid2,'(A,2(1X,I3))') TRIM(elem(i))//'-ECP', m, all_ecp(i)%core_e

   do j = 0, m, 1
    if(j == 0) then
     write(fid2,'(A)') am(m)//' potential'
    else
     write(fid2,'(A)') am(j-1)//'-'//am(m)//' potential'
    end if
    n = all_ecp(i)%potential(j+1)%n
    write(fid2,'(I3)') n
    do k = 1, n, 1
     write(fid2,'(I1,2(1X,ES16.9))') all_ecp(i)%potential(j+1)%col2(k), &
      all_ecp(i)%potential(j+1)%col3(k), all_ecp(i)%potential(j+1)%col1(k)
    end do ! for k
   end do ! for j
   write(fid2,'(A)') '****'
  end if
 end do ! for i

 deallocate(all_ecp)
 write(fid2,'(A)') '}'

 if(X2C) then
  write(fid2,'(/,A)') 'basis mybas1 {'
  do i = 1, natom, 1
   write(fid2,'(2(A,I0))') ' assign '//TRIM(elem(i)),ntimes(i),' gen',i
  end do ! for i

  call goto_data_section_in_gms_inp(inpname, fid1)
  read(fid1,'(A)') buf
  read(fid1,'(A)') buf

  do i = 1, natom, 1
   read(fid1,'(A)') buf ! buf contains elem(i), nuc(i) and coor(1:3,i)
   write(fid2,'(A,I0,A)') '[gen', i, ']'
   write(fid2,'(A)') 'spherical'
   write(fid2,'(A)') '****'
   write(fid2,'(A)') TRIM(elem(i))//' 0'
 
   do while(.true.)
    read(fid1,'(A)') buf
    if(LEN_TRIM(buf) == 0) then
     write(fid2,'(A)') '****'
     exit
    end if
 
    read(buf,*) stype, nline
    if(stype == 'L') then
     stype = 'SP'; k = 3
    else
     k = 2
    end if
 
    rtmp = 0d0
    do j = 1, nline, 1
     write(fid2,'(A)') TRIM(stype)//'   1  1.00'
     read(fid1,*) m, rtmp(1:k)
     write(fid2,'(3(2X,ES16.9))') rtmp(1:k)
    end do ! for j
   end do ! for while
  end do ! for i

  write(fid2,'(A)') '}'
  write(fid2,'(/,A)') 'set relativistic x2c'
  write(fid2,'(A)') 'set basis mybas'
  write(fid2,'(A)') 'set basis_relativistic mybas1'
 end if

 close(fid1)
 deallocate(ntimes, elem)

 call check_DKH_in_gms_inp(inpname, rel)
 select case(rel)
 case(-2) ! nothing
 case(-1) ! RESC
  write(6,'(/,A)') 'ERROR in subroutine bas_gms2psi: RESC keywords detected.'
  write(6,'(A)') 'But RESC is not supported in PSI4.'
  stop
 case(0,1,2,4)  ! DKH0/1/2/4
  if(.not. X2C) then
   write(fid2,'(A)') 'set relativistic dkh'
   write(fid2,'(A)') 'set basis_relativistic mybas'
   if(rel /= 2) write(fid2,'(A,I0)') 'set DKH_order ', rel
  end if
 case default
  write(6,'(/,A)') 'ERROR in subroutine bas_gms2psi: rel out of range!'
  write(6,'(A,I0)') 'rel=', rel
  close(fid2,status='delete')
  stop
 end select

 write(fid2,'(/,A)') 'set {'
 write(fid2,'(A)') ' scf_type pk'
 write(fid2,'(A)') ' s_tolerance 1e-6'
 write(fid2,'(A)') ' e_convergence 1e5'
 write(fid2,'(A)') ' d_convergence 1e5'

 if(uhf) then
  write(fid2,'(A)') ' reference uhf'
 else
  if(mult == 1) then
   write(fid2,'(A)') ' reference rhf'
  else
   write(fid2,'(A)') ' reference rohf'
  end if
 end if
 write(fid2,'(A)') '}'

 write(fid2,'(/,A)') "scfenergy, scf_wfn = energy('scf', return_wfn=True)"
 write(fid2,'(A)') '# this scf makes every array allocated'

 write(fid2,'(/,A)') "scf_wfn.Ca().load('"//TRIM(fileA)//"')"
 if(uhf) write(fid2,'(A)') "scf_wfn.Cb().load('"//TRIM(fileB)//"')"
 write(fid2,'(A)') 'scf_wfn.to_file(scf_wfn.get_scratch_filename(180))'

 write(fid2,'(/,A)') 'set {'
 write(fid2,'(A)') ' guess read'
 write(fid2,'(A)') ' e_convergence 1e-8'
 write(fid2,'(A)') ' d_convergence 1e-6'
 write(fid2,'(A)') '}'
 write(fid2,'(/,A)') "scfenergy = energy('scf')"
 close(fid2)
end subroutine bas_gms2psi

