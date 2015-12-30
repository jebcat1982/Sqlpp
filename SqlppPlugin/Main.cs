using System;
using System.IO;
using System.Text;
using System.Drawing;
using System.Threading;
using System.Windows.Forms;
using System.Drawing.Imaging;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using System.Text.RegularExpressions;
using System.Net;
using System.Linq;
using System.Diagnostics;

namespace NppPluginNET
{
    partial class PluginBase
    {
        #region " Fields "
        internal const string PluginName = "Sql++";
        static string iniFilePath = null;
        static string sectionName = "Insert Extension";
        static string keyName = "doCloseTag";
        static bool doCloseTag = false;
        static string sessionFilePath = @"C:\text.session";
        static frmGoToLine frmGoToLine = null;
        static internal int idFrmGotToLine = -1;
      
        static Icon tbIcon = null;
        #endregion

        #region " Startup/CleanUp "
        static internal void CommandMenuInit()
        {
            // Initialization of your plugin commands
            // You should fill your plugins commands here
 
        	//
	        // Firstly we get the parameters from your plugin config file (if any)
	        //

	        // get path of plugin configuration
            StringBuilder sbIniFilePath = new StringBuilder(Win32.MAX_PATH);
            Win32.SendMessage(nppData._nppHandle, NppMsg.NPPM_GETPLUGINSCONFIGDIR, Win32.MAX_PATH, sbIniFilePath);
            iniFilePath = sbIniFilePath.ToString();

	        // if config path doesn't exist, we create it
            if (!Directory.Exists(iniFilePath))
	        {
                Directory.CreateDirectory(iniFilePath);
	        }

	        // make your plugin config file full file path name
            iniFilePath = Path.Combine(iniFilePath, PluginName + ".ini");

	        // get the parameter value from plugin config
	        doCloseTag = (Win32.GetPrivateProfileInt(sectionName, keyName, 0, iniFilePath) != 0);

            // with function :
            // SetCommand(int index,                            // zero based number to indicate the order of command
            //            string commandName,                   // the command name that you want to see in plugin menu
            //            NppFuncItemDelegate functionPointer,  // the symbol of function (function pointer) associated with this command. The body should be defined below. See Step 4.
            //            ShortcutKey *shortcut,                // optional. Define a shortcut to trigger this command
            //            bool check0nInit                      // optional. Make this menu item be checked visually
            //            );
            SetCommand(0, "Search", Search, new ShortcutKey(true, true, false, Keys.D1));
            SetCommand(1, "Get", Get, new ShortcutKey(true, true, false, Keys.D2));


            SetCommand(15, "Dockable Dialog Demo", DockableDlgDemo); idFrmGotToLine = 15;
        }
        static internal void PluginCleanUp()
        {
	        Win32.WritePrivateProfileString(sectionName, keyName, doCloseTag ? "1" : "0", iniFilePath);
        }
        #endregion

        #region " Menu functions "
        static void Search()
        {

            var name = GetSelText();
            string responseString;
            using (var client = new WebClient())
            {
                responseString = client.DownloadString("http://localhost:8090/api/Db/Search?name=" + System.Web.HttpUtility.UrlEncode(name));
            }
            var arr = System.Web.Helpers.Json.Decode<string[]>(responseString);
            if (!arr.Any())
                MessageBox.Show("Could not find content");
            else
                CreateFile("search " + name, string.Join("\n", arr));
            return;
            // Open a new document
            Win32.SendMessage(nppData._nppHandle, NppMsg.NPPM_MENUCOMMAND, 0, NppMenuCmd.IDM_FILE_NEW);
            // Say hello now :
            // Scintilla control has no Unicode mode, so we use ANSI here (marshalled as ANSI by default)
            Win32.SendMessage(GetCurrentScintilla(), SciMsg.SCI_SETTEXT, 0, responseString);
        }
        static void Get()
        {
            try
            {
                var name = GetSelText();
                string responseString;
                using (var client = new WebClient())
                {
                    responseString = client.DownloadString("http://localhost:8090/api/Db/Get?name=" + System.Web.HttpUtility.UrlEncode(name));
                }
                responseString = System.Web.Helpers.Json.Decode<string>(responseString);
                if (String.IsNullOrEmpty(responseString.Trim()))
                    MessageBox.Show("Could not find content");
                else
                    CreateFile(name, responseString);
                return;

                // Open a new document
                Win32.SendMessage(nppData._nppHandle, NppMsg.NPPM_MENUCOMMAND, 0, NppMenuCmd.IDM_FILE_NEW);

                Win32.SendMessage(PluginBase.nppData._nppHandle, NppMsg.NPPM_SETCURRENTLANGTYPE, 0, (int)LangType.L_SQL);

                // Say hello now :
                // Scintilla control has no Unicode mode, so we use ANSI here (marshalled as ANSI by default)
                Win32.SendMessage(GetCurrentScintilla(), SciMsg.SCI_SETTEXT, 0, responseString);
            }
            catch (Exception ex)
            {
                CatchError(ex);
            }
        }

        private static void CreateFile(string name, string content)
        {
            var fi = new FileInfo(Path.GetTempPath() + @"\" + DateTime.Now.ToString("yyyy") + @"\" + DateTime.Now.ToString(@"MM") + @"\" + DateTime.Now.ToString("dd") + @"\" + name + ".sql");
            if (!fi.Directory.Exists)
                fi.Directory.Create();
            if (fi.Exists)
                fi.Delete();

            File.WriteAllText(fi.FullName,content);
            Win32.SendMessage(nppData._nppHandle, NppMsg.NPPM_DOOPEN, 0, fi.FullName);

            //Process notepadPlus = new Process();
            //notepadPlus.StartInfo.FileName =  @"C:\Program Files (x86)\Notepad++\notepad++.exe";
            //notepadPlus.Start();
        }

        private static void CatchError(Exception ex)
        {
            MessageBox.Show(ex.ToString());
        }
        static string GetSelText()
        {
            IntPtr curScintilla = GetCurrentScintilla();
            int length = (int)Win32.SendMessage(curScintilla, SciMsg.SCI_GETLENGTH, 0, 0) + 1;
            byte[] sb = new byte[length];
            unsafe
            {
                fixed (byte* p = sb)
                {

                    IntPtr ptr = (IntPtr)p;

                    Win32.SendMessage(curScintilla, SciMsg.SCI_GETSELTEXT, length, ptr);
                }

                return System.Text.Encoding.UTF8.GetString(sb).TrimEnd('\0');
            }
        }

        static void insertCurrentFullPath()
        {
            insertCurrentPath(NppMsg.FULL_CURRENT_PATH);
        }
        static void insertCurrentFileName()
        {
            insertCurrentPath(NppMsg.FILE_NAME);
        }
        static void insertCurrentDirectory()
        {
            insertCurrentPath(NppMsg.CURRENT_DIRECTORY);
        }
        static void insertCurrentPath(NppMsg which)
        {
	        NppMsg msg = NppMsg.NPPM_GETFULLCURRENTPATH;
	        if (which == NppMsg.FILE_NAME)
		        msg = NppMsg.NPPM_GETFILENAME;
	        else if (which == NppMsg.CURRENT_DIRECTORY)
                msg = NppMsg.NPPM_GETCURRENTDIRECTORY;

	        StringBuilder path = new StringBuilder(Win32.MAX_PATH);
	        Win32.SendMessage(nppData._nppHandle, msg, 0, path);

            Win32.SendMessage(GetCurrentScintilla(), SciMsg.SCI_REPLACESEL, 0, path);
        }

        static void insertShortDateTime()
        {
            insertDateTime(false);
        }
        static void insertLongDateTime()
        {
            insertDateTime(true);
        }
        static void insertDateTime(bool longFormat)
        {
            string dateTime = string.Format("{0} {1}", 
                DateTime.Now.ToShortTimeString(),
                longFormat ? DateTime.Now.ToLongDateString() : DateTime.Now.ToShortDateString());
            Win32.SendMessage(GetCurrentScintilla(), SciMsg.SCI_REPLACESEL, 0, dateTime);
        }

        static void checkInsertHtmlCloseTag()
        {
            doCloseTag = !doCloseTag;

            int i = Win32.CheckMenuItem(Win32.GetMenu(nppData._nppHandle), _funcItems.Items[9]._cmdID,
                Win32.MF_BYCOMMAND | (doCloseTag ? Win32.MF_CHECKED : Win32.MF_UNCHECKED));
        }
        static internal void doInsertHtmlCloseTag(char newChar)
        {
            LangType docType = LangType.L_TEXT;
            Win32.SendMessage(nppData._nppHandle, NppMsg.NPPM_GETCURRENTLANGTYPE, 0, ref docType);
            bool isDocTypeHTML = (docType == LangType.L_HTML || docType == LangType.L_XML || docType == LangType.L_PHP);
            if (doCloseTag && isDocTypeHTML)
            {
                if (newChar == '>')
                {
                    int bufCapacity = 512;
                    IntPtr hCurrentEditView = GetCurrentScintilla();
                    int currentPos = (int)Win32.SendMessage(hCurrentEditView, SciMsg.SCI_GETCURRENTPOS, 0, 0);
                    int beginPos = currentPos - (bufCapacity - 1);
                    int startPos = (beginPos > 0) ? beginPos : 0;
                    int size = currentPos - startPos;

                    if (size >= 3)
                    {
                        using (Sci_TextRange tr = new Sci_TextRange(startPos, currentPos, bufCapacity))
                        {
                            Win32.SendMessage(hCurrentEditView, SciMsg.SCI_GETTEXTRANGE, 0, tr.NativePointer);
                            string buf = tr.lpstrText;

                            if (buf[size - 2] != '/')
                            {
                                StringBuilder insertString = new StringBuilder("</");

                                int pCur = size - 2;
                                for (; (pCur > 0) && (buf[pCur] != '<') && (buf[pCur] != '>'); )
                                    pCur--;

                                if (buf[pCur] == '<')
                                {
                                    pCur++;

                                    Regex regex = new Regex(@"[\._\-:\w]");
                                    while (regex.IsMatch(buf[pCur].ToString()))
                                    {
                                        insertString.Append(buf[pCur]);
                                        pCur++;
                                    }
                                    insertString.Append('>');

                                    if (insertString.Length > 3)
                                    {
                                        Win32.SendMessage(hCurrentEditView, SciMsg.SCI_BEGINUNDOACTION, 0, 0);
                                        Win32.SendMessage(hCurrentEditView, SciMsg.SCI_REPLACESEL, 0, insertString);
                                        Win32.SendMessage(hCurrentEditView, SciMsg.SCI_SETSEL, currentPos, currentPos);
                                        Win32.SendMessage(hCurrentEditView, SciMsg.SCI_ENDUNDOACTION, 0, 0);
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        static void getFileNamesDemo()
        {
            int nbFile = (int)Win32.SendMessage(nppData._nppHandle, NppMsg.NPPM_GETNBOPENFILES, 0, 0);
            MessageBox.Show(nbFile.ToString(), "Number of opened files:");

            using (ClikeStringArray cStrArray = new ClikeStringArray(nbFile, Win32.MAX_PATH))
            {
                if (Win32.SendMessage(nppData._nppHandle, NppMsg.NPPM_GETOPENFILENAMES, cStrArray.NativePointer, nbFile) != IntPtr.Zero)
                    foreach (string file in cStrArray.ManagedStringsUnicode) MessageBox.Show(file);
            }
        }
        static void getSessionFileNamesDemo()
        {
            int nbFile = (int)Win32.SendMessage(nppData._nppHandle, NppMsg.NPPM_GETNBSESSIONFILES, 0, sessionFilePath);

        	if (nbFile < 1)
	        {
		        MessageBox.Show("Please modify \"sessionFilePath\" in \"Demo.cs\" in order to point to a valid session file", "Error");
		        return;
	        }
            MessageBox.Show(nbFile.ToString(), "Number of session files:");

            using (ClikeStringArray cStrArray = new ClikeStringArray(nbFile, Win32.MAX_PATH))
            {
                if (Win32.SendMessage(nppData._nppHandle, NppMsg.NPPM_GETSESSIONFILES, cStrArray.NativePointer, sessionFilePath) != IntPtr.Zero)
                    foreach (string file in cStrArray.ManagedStringsUnicode) MessageBox.Show(file);
            }
        }
        static void saveCurrentSessionDemo()
        {
            string sessionPath = Marshal.PtrToStringUni(Win32.SendMessage(nppData._nppHandle, NppMsg.NPPM_SAVECURRENTSESSION, 0, sessionFilePath));
	        if (!string.IsNullOrEmpty(sessionPath))
		        MessageBox.Show(sessionPath, "Saved Session File :", MessageBoxButtons.OK);
        }

        static void DockableDlgDemo()
        {
            // Dockable Dialog Demo
            // 
            // This demonstration shows you how to do a dockable dialog.
            // You can create your own non dockable dialog - in this case you don't nedd this demonstration.
            if (frmGoToLine == null)
            {
                frmGoToLine = new frmGoToLine();

                using (Bitmap newBmp = new Bitmap(16, 16))
                {
					Graphics g = Graphics.FromImage(newBmp);
					ColorMap[] colorMap = new ColorMap[1];
					colorMap[0] = new ColorMap();
					colorMap[0].OldColor = Color.Fuchsia;
					colorMap[0].NewColor = Color.FromKnownColor(KnownColor.ButtonFace);
					ImageAttributes attr = new ImageAttributes();
					attr.SetRemapTable(colorMap);
					tbIcon = Icon.FromHandle(newBmp.GetHicon());
                }
                
                NppTbData _nppTbData = new NppTbData();
                _nppTbData.hClient = frmGoToLine.Handle;
                _nppTbData.pszName = "Go To Line #";
                // the dlgDlg should be the index of funcItem where the current function pointer is in
                // this case is 15.. so the initial value of funcItem[15]._cmdID - not the updated internal one !
                _nppTbData.dlgID = idFrmGotToLine;
                // define the default docking behaviour
                _nppTbData.uMask = NppTbMsg.DWS_DF_CONT_RIGHT | NppTbMsg.DWS_ICONTAB | NppTbMsg.DWS_ICONBAR;
                _nppTbData.hIconTab = (uint)tbIcon.Handle;
                _nppTbData.pszModuleName = PluginName;
                IntPtr _ptrNppTbData = Marshal.AllocHGlobal(Marshal.SizeOf(_nppTbData));
                Marshal.StructureToPtr(_nppTbData, _ptrNppTbData, false);

                Win32.SendMessage(nppData._nppHandle, NppMsg.NPPM_DMMREGASDCKDLG, 0, _ptrNppTbData);
                // Following message will toogle both menu item state and toolbar button
                Win32.SendMessage(nppData._nppHandle, NppMsg.NPPM_SETMENUITEMCHECK, _funcItems.Items[idFrmGotToLine]._cmdID, 1);
            }
            else
            {
            	if (!frmGoToLine.Visible)
            	{
	                Win32.SendMessage(nppData._nppHandle, NppMsg.NPPM_DMMSHOW, 0, frmGoToLine.Handle);
	                Win32.SendMessage(nppData._nppHandle, NppMsg.NPPM_SETMENUITEMCHECK, _funcItems.Items[idFrmGotToLine]._cmdID, 1);
            	}
            	else
            	{
	                Win32.SendMessage(nppData._nppHandle, NppMsg.NPPM_DMMHIDE, 0, frmGoToLine.Handle);
	                Win32.SendMessage(nppData._nppHandle, NppMsg.NPPM_SETMENUITEMCHECK, _funcItems.Items[idFrmGotToLine]._cmdID, 0);
            	}
            }
            frmGoToLine.textBox1.Focus();
        }
        #endregion
    }
}   
