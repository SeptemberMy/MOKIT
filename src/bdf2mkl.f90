! written by jxzou at 20210111: combined two utilities - bdf2fch and fch2mkl

program main
 implicit none
 integer :: i
 character(len=3) :: str
 character(len=240) :: orbname, fchname

 i = iargc()
 if(.not. (i==2 .or. i==3)) then
  write(6,'(/,A)') ' ERROR in subroutine bdf2mkl: wrong command line arguments!'
  write(6,'(A)')   ' Example 1 (for R(O)HF, UHF): bdf2mkl a.scforb a.fch'
  write(6,'(A)')   ' Example 2 (for CAS)        : bdf2mkl a.casorb a.fch'
  write(6,'(A,/)') ' Example 3 (for CAS NO)     : bdf2mkl a.casorb a.fch -no'
  stop
 end if

 str = ' '; fchname = ' '
 call getarg(1,orbname)
 call require_file_exist(orbname)

 call getarg(2,fchname)
 call require_file_exist(fchname)

 if(i == 3) then
  call getarg(3, str)
  if(str /= '-no') then
   write(6,'(/,A)') "ERROR in subroutine bdf2mkl: the 3rd argument is&
                      & wrong! Only '-no' is accepted."
   write(6,'(A)') "But you specify '"//str//"'."
   stop
  end if
 end if

 call bdf2mkl(orbname, fchname, str)
end program main

! Step 1: call utility bdf2fch to transfer orbitals back into .fch(k) file
! Step 2: call utility fch2mkl to generate ORCA .inp and .mkl file
subroutine bdf2mkl(orbname, fchname, str)
 implicit none
 integer :: i, SYSTEM
 character(len=3), intent(in) :: str
 character(len=240), intent(in) :: orbname, fchname

 i = SYSTEM('bdf2fch '//TRIM(orbname)//' '//TRIM(fchname)//' '//str)
 if(i /= 0) then
  write(6,'(A)') 'ERROR in subroutine bdf2mkl: failed to call utility bdf2fch.'
  write(6,'(A)') 'Did you forget to compile utility bdf2fch?'
  stop
 end if

 i = SYSTEM('fch2mkl '//TRIM(fchname))
 if(i /= 0) then
  write(6,'(A)') 'ERROR in subroutine bdf2mkl: failed to call utility fch2mkl.'
  write(6,'(A)') 'Did you forget to compile utility fch2mkl?'
  stop
 end if
end subroutine bdf2mkl

