// Please, don't delete this comment. \\
(*
  Copyright Owner: Yahe
  Copyright Year : 2008-2018

  Include: MWgpsU (platform independant)
  Version: 0.4.5.3c

  Contact E-Mail: hello@yahe.sh
*)
// Please, don't delete this comment. \\

(*
  Description:

  This include file contains compiler switches for MWgpsU.
*)

(*
  Change Log:

  [Version 0.2b] (17.07.2008: initial release)
  - initial source has been written
*)

{$DEFINE DEBUG_MODE}

{$IF DEFINED(DEBUG_MODE)}
  {$ASSERTIONS ON}
  {$DEBUGINFO ON}
  {$LOCALSYMBOLS ON}
  {$OPTIMIZATION OFF}
  {$STACKFRAMES ON}
{$ELSE DEFINED(DEBUG_MODE)}
  {$ASSERTIONS OFF}
  {$DEBUGINFO OFF}
  {$LOCALSYMBOLS OFF}
  {$OPTIMIZATION ON}
  {$STACKFRAMES OFF}
{$IFEND DEFINED(DEBUG_MODE)}

{$IOCHECKS ON}
{$OVERFLOWCHECKS ON}
{$RANGECHECKS ON}
