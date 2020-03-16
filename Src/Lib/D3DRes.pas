unit D3DRes;
//-----------------------------------------------------------------------------
// File: D3DRes.h
//
// Desc: Resource definitions required by the CD3DApplication class.
//       Any application using the CD3DApplication class must include resources
//       with the following identifiers.
//
// Copyright (c) 1999-2001 Microsoft Corporation. All rights reserved.
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
// Original ObjectPascal conversion made by: Boris V.
// E-Mail: bst@bstnet.org
//
// Updates and modifications by: Alexey Barkovoy
// E-Mail: clootie@reactor.ru
//-----------------------------------------------------------------------------
//  Latest version can be downloaded from:
//     http://clootie.narod.ru/delphi/
//       -- and choice version of DirectX SDK: 8.0 or 8.1
//-----------------------------------------------------------------------------

interface

const
 IDI_MAIN_ICON          =101; // Application icon
 IDR_MAIN_ACCEL         =113; // Keyboard accelerator
 IDR_MENU               =141; // Application menu
 IDR_POPUP              =142; // Popup menu
 IDD_SELECTDEVICE       =144; // "Change Device" dialog box

 IDC_ADAPTER_COMBO         =1002; // Adapter combobox for "SelectDevice" dlg
 IDC_DEVICE_COMBO          =1000; // Device combobox for "SelectDevice" dlg
 IDC_FULLSCREENMODES_COMBO =1003; // Mode combobox for "SelectDevice" dlg
 IDC_MULTISAMPLE_COMBO     =1005; // MultiSample combobox for "SelectDevice" dlg
 IDC_WINDOW                =1016; // Radio button for windowed-mode
 IDC_FULLSCREEN            =1018; // Radio button for fullscreen-mode

 IDM_TOGGLEHELP       =40001;
 IDM_CHANGEDEVICE     =40002; // Command to invoke "Change Device" dlg
 IDM_TOGGLEFULLSCREEN =40003; // Command to toggle fullscreen mode
 IDM_TOGGLESTART      =40004; // Command to toggle frame animation
 IDM_SINGLESTEP       =40005; // Command to single step frame animation
 IDM_EXIT             =40006; // Command to exit the application

implementation

end.

